const fs = require('fs');
const path = require('path');

const axios = require('axios');
const admin = require('firebase-admin');

function loadVertexSdk() {
  try {
    // Preferred package name in the latest CargoMind checklist.
    return require('@google/vertexai');
  } catch (_) {
    // Fallback to currently installed official Vertex AI SDK package.
    return require('@google-cloud/vertexai');
  }
}

const {
  VertexAI,
  FunctionDeclarationSchemaType,
  FunctionCallingMode,
} = loadVertexSdk();

const DATA_DIR = path.join(__dirname, '..', 'data');
const MARKET_PRICES_FILE = path.join(DATA_DIR, 'market_prices.json');
const HOSPITAL_REGISTRY_FILE = path.join(DATA_DIR, 'hospital_registry.json');

const DEFAULT_MODEL = process.env.VERTEX_MODEL || 'gemini-2.0-pro';
const INDIA_FALLBACK_COORDINATES = { lat: 20.5937, lng: 78.9629 };

const CITY_COORDINATES = {
  delhi: { lat: 28.6139, lng: 77.2090 },
  agra: { lat: 27.1767, lng: 78.0081 },
  jaipur: { lat: 26.9124, lng: 75.7873 },
  lucknow: { lat: 26.8467, lng: 80.9462 },
  indore: { lat: 22.7196, lng: 75.8577 },
  noida: { lat: 28.5355, lng: 77.3910 },
  gurugram: { lat: 28.4595, lng: 77.0266 },
};

const SCHEMA_TYPE = FunctionDeclarationSchemaType || {
  OBJECT: 'OBJECT',
  STRING: 'STRING',
  NUMBER: 'NUMBER',
};

const AGENT_TOOLS = [
  {
    functionDeclarations: [
      {
        name: 'execute_autonomous_triage',
        description:
          'Triggers when a crisis requires route divergence or intercept. Generates new routing constraints.',
        parameters: {
          type: SCHEMA_TYPE.OBJECT,
          properties: {
            vehicle_id: { type: SCHEMA_TYPE.STRING },
            action_type: {
              type: SCHEMA_TYPE.STRING,
              enum: [
                'MARKET_ARBITRAGE_DIVERSION',
                'HOSPITAL_TRIAGE',
                'VEHICLE_INTERCEPT',
              ],
            },
            new_target_location: { type: SCHEMA_TYPE.STRING },
            justification_log: { type: SCHEMA_TYPE.STRING },
            calculated_salvage_value: { type: SCHEMA_TYPE.NUMBER },
          },
          required: [
            'vehicle_id',
            'action_type',
            'new_target_location',
            'justification_log',
            'calculated_salvage_value',
          ],
        },
      },
    ],
  },
];

const AGENT_TOOL_CONFIG = {
  functionCallingConfig: {
    mode: FunctionCallingMode?.ANY || 'ANY',
    allowedFunctionNames: ['execute_autonomous_triage'],
  },
};

function readJsonFile(filePath) {
  const raw = fs.readFileSync(filePath, 'utf-8');
  return JSON.parse(raw);
}

function inferActionType(incidentType = '', severity = '') {
  const normalizedType = String(incidentType).toUpperCase();
  const normalizedSeverity = String(severity).toUpperCase();

  if (normalizedType.includes('MEDICAL') || normalizedType.includes('TEMP')) {
    return 'HOSPITAL_TRIAGE';
  }

  if (normalizedType.includes('INTERCEPT') || normalizedSeverity === 'HIGH') {
    return 'VEHICLE_INTERCEPT';
  }

  return 'MARKET_ARBITRAGE_DIVERSION';
}

function pickBestMarketForTomato(markets) {
  if (!Array.isArray(markets) || markets.length === 0) {
    return null;
  }

  return markets.reduce((best, current) => {
    const bestPrice = Number(best?.crop_prices_inr_per_kg?.tomato || 0);
    const currentPrice = Number(current?.crop_prices_inr_per_kg?.tomato || 0);
    return currentPrice > bestPrice ? current : best;
  }, markets[0]);
}

function buildFallbackDecision(incidentPayload, marketPrices, hospitals) {
  const actionType = inferActionType(
    incidentPayload.incident_type,
    incidentPayload.severity
  );

  if (actionType === 'HOSPITAL_TRIAGE') {
    const hospital = hospitals[0];
    return {
      vehicle_id: incidentPayload.vehicle_id,
      action_type: 'HOSPITAL_TRIAGE',
      new_target_location: hospital
        ? `${hospital.name}, ${hospital.address}`
        : 'Apollo Emergency Cold-Chain Clinic, Delhi',
      justification_log:
        'Medical/temperature risk detected. Diverting to nearest cold-chain capable clinic for stabilization.',
      calculated_salvage_value: Number(incidentPayload.estimated_value_inr || 150000),
    };
  }

  const bestMarket = pickBestMarketForTomato(marketPrices);
  const targetMarket = bestMarket
    ? `${bestMarket.market}, ${bestMarket.city}`
    : 'Kuberpur Agricultural Market, Agra';
  const tomatoPrice = Number(bestMarket?.crop_prices_inr_per_kg?.tomato || 0);
  const fallbackValue = Number(incidentPayload.estimated_value_inr || 200000);

  return {
    vehicle_id: incidentPayload.vehicle_id,
    action_type: actionType,
    new_target_location: targetMarket,
    justification_log:
      'Primary route compromised. Diverting to higher-yield destination to preserve cargo value and continuity.',
    calculated_salvage_value: Math.max(fallbackValue, tomatoPrice * 10000),
  };
}

function sanitizeDecision(rawDecision, incidentPayload, fallbackDecision) {
  const safe = rawDecision && typeof rawDecision === 'object' ? rawDecision : {};

  return {
    vehicle_id: String(safe.vehicle_id || incidentPayload.vehicle_id),
    action_type: String(safe.action_type || fallbackDecision.action_type),
    new_target_location: String(
      safe.new_target_location || fallbackDecision.new_target_location
    ),
    justification_log: String(
      safe.justification_log || fallbackDecision.justification_log
    ),
    calculated_salvage_value: Number(
      safe.calculated_salvage_value ?? fallbackDecision.calculated_salvage_value
    ),
  };
}

function extractFunctionCall(response) {
  const parts = response?.candidates?.[0]?.content?.parts || [];
  const functionPart = parts.find((part) => part.functionCall);
  return functionPart?.functionCall || null;
}

function extractJsonTextDecision(response) {
  const parts = response?.candidates?.[0]?.content?.parts || [];
  const textPart = parts.find((part) => typeof part.text === 'string' && part.text.trim());
  if (!textPart) {
    return null;
  }

  try {
    return JSON.parse(textPart.text);
  } catch (_) {
    return null;
  }
}

async function runVertexAgent(incidentPayload, marketPrices, hospitals) {
  const project = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT;
  const location = process.env.VERTEX_LOCATION || 'us-central1';

  if (!project) {
    return null;
  }

  const vertexAI = new VertexAI({ project, location });
  const model = vertexAI.getGenerativeModel({
    model: DEFAULT_MODEL,
    generationConfig: {
      temperature: 0.1,
      maxOutputTokens: 512,
      responseMimeType: 'application/json',
    },
    tools: AGENT_TOOLS,
    toolConfig: AGENT_TOOL_CONFIG,
  });

  const prompt = [
    'You are CargoMind autonomous triage orchestrator.',
    'Return exactly one function call: execute_autonomous_triage.',
    'Do not emit free-form prose.',
    'Incident payload:',
    JSON.stringify(incidentPayload),
    'Market context:',
    JSON.stringify(marketPrices),
    'Hospital context:',
    JSON.stringify(hospitals),
  ].join('\n');

  const result = await model.generateContent({
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    tools: AGENT_TOOLS,
    toolConfig: AGENT_TOOL_CONFIG,
  });

  const response = result?.response;
  const functionCall = extractFunctionCall(response);
  if (functionCall?.name === 'execute_autonomous_triage') {
    return functionCall.args;
  }

  return extractJsonTextDecision(response);
}

function findLocalCoordinates(locationText, hospitals, marketPrices) {
  const needle = String(locationText || '').toLowerCase();

  const matchingHospital = hospitals.find((item) => {
    const fields = [item.name, item.address, item.city].map((v) =>
      String(v || '').toLowerCase()
    );
    return fields.some((value) => value && needle.includes(value));
  });

  if (matchingHospital) {
    return {
      lat: Number(matchingHospital.lat),
      lng: Number(matchingHospital.lng),
      formattedAddress: `${matchingHospital.name}, ${matchingHospital.address}`,
      source: 'mock-local-registry',
    };
  }

  const matchingMarket = marketPrices.find((item) => {
    const fields = [item.market, item.city, item.state].map((v) =>
      String(v || '').toLowerCase()
    );
    return fields.some((value) => value && needle.includes(value));
  });

  if (matchingMarket) {
    const cityKey = String(matchingMarket.city || '').toLowerCase();
    const coords = CITY_COORDINATES[cityKey] || INDIA_FALLBACK_COORDINATES;
    return {
      lat: coords.lat,
      lng: coords.lng,
      formattedAddress: `${matchingMarket.market}, ${matchingMarket.city}, ${matchingMarket.state}`,
      source: 'mock-city-centroid',
    };
  }

  return {
    lat: INDIA_FALLBACK_COORDINATES.lat,
    lng: INDIA_FALLBACK_COORDINATES.lng,
    formattedAddress: String(locationText || 'India'),
    source: 'fallback-india-center',
  };
}

async function geocodeTargetLocation(locationText, hospitals, marketPrices) {
  const mapsApiKey = process.env.GOOGLE_MAPS_API_KEY;

  if (mapsApiKey) {
    try {
      const response = await axios.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        {
          params: {
            address: locationText,
            key: mapsApiKey,
          },
          timeout: 6000,
        }
      );

      const firstResult = response.data?.results?.[0];
      if (firstResult?.geometry?.location) {
        return {
          lat: Number(firstResult.geometry.location.lat),
          lng: Number(firstResult.geometry.location.lng),
          formattedAddress:
            firstResult.formatted_address || String(locationText || ''),
          source: 'google-geocoding',
        };
      }
    } catch (_) {
      // Fall through to deterministic local mocks.
    }
  }

  return findLocalCoordinates(locationText, hospitals, marketPrices);
}

async function getRoutePolyline(origin, destination) {
  const mapsApiKey = process.env.GOOGLE_MAPS_API_KEY;

  if (mapsApiKey) {
    try {
      const response = await axios.post(
        'https://routes.googleapis.com/directions/v2:computeRoutes',
        {
          origin: {
            location: {
              latLng: {
                latitude: origin.lat,
                longitude: origin.lng,
              },
            },
          },
          destination: {
            location: {
              latLng: {
                latitude: destination.lat,
                longitude: destination.lng,
              },
            },
          },
          travelMode: 'DRIVE',
          routingPreference: 'TRAFFIC_UNAWARE',
          polylineQuality: 'OVERVIEW',
          computeAlternativeRoutes: false,
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': mapsApiKey,
            'X-Goog-FieldMask':
              'routes.polyline.encodedPolyline,routes.distanceMeters,routes.duration',
          },
          timeout: 7000,
        }
      );

      const firstRoute = response.data?.routes?.[0];
      if (firstRoute?.polyline?.encodedPolyline) {
        return {
          encodedPolyline: firstRoute.polyline.encodedPolyline,
          distanceMeters: Number(firstRoute.distanceMeters || 0),
          duration: String(firstRoute.duration || ''),
          source: 'google-routes',
        };
      }
    } catch (_) {
      // Fall through to deterministic polyline mock.
    }
  }

  // Mock polyline path (Delhi -> Agra-ish sample route for demos)
  return {
    encodedPolyline: 'o|nnDcv}uM`@t@lAjCnErIzAnCxCpFdBnD~@rAr@t@',
    distanceMeters: 230000,
    duration: '10800s',
    source: 'mock-routes',
  };
}

async function resolveShipmentDocument(vehicleId) {
  if (!admin.apps.length) {
    return null;
  }

  const db = admin.firestore();
  const querySnapshot = await db
    .collection('ActiveShipments')
    .where('telemetry.vehicle_id', '==', vehicleId)
    .limit(1)
    .get();

  if (!querySnapshot.empty) {
    return querySnapshot.docs[0];
  }

  const directDoc = await db.collection('ActiveShipments').doc(vehicleId).get();
  if (directDoc.exists) {
    return directDoc;
  }

  return null;
}

function deriveStatusFromAction(actionType) {
  if (actionType === 'HOSPITAL_TRIAGE') {
    return 'CRITICAL';
  }
  if (actionType === 'VEHICLE_INTERCEPT') {
    return 'CRITICAL';
  }
  return 'DIVERTED';
}

async function persistTriageState(incidentPayload, decision, geocode, routePlan) {
  if (!admin.apps.length) {
    return {
      written: false,
      reason: 'firebase-admin not initialized',
    };
  }

  const shipmentDoc = await resolveShipmentDocument(decision.vehicle_id);
  const db = admin.firestore();

  const targetRef = shipmentDoc
    ? shipmentDoc.ref
    : db.collection('ActiveShipments').doc(decision.vehicle_id);

  const updatePayload = {
    status: deriveStatusFromAction(decision.action_type),
    telemetry: {
      vehicle_id: decision.vehicle_id,
      current_location: {
        lat: Number(incidentPayload.current_lat ?? INDIA_FALLBACK_COORDINATES.lat),
        lng: Number(incidentPayload.current_lng ?? INDIA_FALLBACK_COORDINATES.lng),
      },
      bearing: Number(incidentPayload.bearing ?? 0),
      temperature_celsius: Number(incidentPayload.temperature_celsius ?? 0),
    },
    route_data: {
      target_destination_name: geocode.formattedAddress,
      encoded_polyline: routePlan.encodedPolyline,
      eta_epoch_ms: Date.now() + 3 * 60 * 60 * 1000,
    },
    agent_metadata: {
      latest_action_log: decision.justification_log,
      financial_salvage_inr: decision.calculated_salvage_value,
      action_type: decision.action_type,
      updated_at: Date.now(),
    },
  };

  await targetRef.set(updatePayload, { merge: true });

  return {
    written: true,
    documentId: targetRef.id,
    status: updatePayload.status,
  };
}

async function processIncident(incidentPayload) {
  const marketPrices = readJsonFile(MARKET_PRICES_FILE);
  const hospitals = readJsonFile(HOSPITAL_REGISTRY_FILE);

  const fallbackDecision = buildFallbackDecision(
    incidentPayload,
    marketPrices,
    hospitals
  );

  let modelDecision = null;
  try {
    modelDecision = await runVertexAgent(incidentPayload, marketPrices, hospitals);
  } catch (_) {
    modelDecision = null;
  }

  const decision = sanitizeDecision(
    modelDecision,
    incidentPayload,
    fallbackDecision
  );

  const origin = {
    lat: Number(incidentPayload.current_lat ?? INDIA_FALLBACK_COORDINATES.lat),
    lng: Number(incidentPayload.current_lng ?? INDIA_FALLBACK_COORDINATES.lng),
  };

  const geocode = await geocodeTargetLocation(
    decision.new_target_location,
    hospitals,
    marketPrices
  );

  const routePlan = await getRoutePolyline(origin, {
    lat: geocode.lat,
    lng: geocode.lng,
  });

  const firestoreWrite = await persistTriageState(
    incidentPayload,
    decision,
    geocode,
    routePlan
  );

  return {
    decision,
    geocode,
    routePlan,
    firestoreWrite,
    contextUsed: {
      market_count: marketPrices.length,
      hospital_count: hospitals.length,
      model: DEFAULT_MODEL,
    },
  };
}

module.exports = {
  processIncident,
};
