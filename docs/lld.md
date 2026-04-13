# `lld.md` (Low-Level Design) - CargoMind AI

## 1. System Overview
**CargoMind AI** is an autonomous, event-driven B2B logistics agent. Unlike reactive routing applications, CargoMind runs continuously in the background, combining geospatial data (Google Maps/Routes APIs), domain-specific contexts (shelf-life, market pricing), and multi-modal intelligence (Vertex AI Gemini 2.0 Pro) to proactively predict supply-chain failures and execute autonomous, economically-optimized reroutes without human intervention.

## 2. Technology Stack (2026 Specifications)
*   **Frontend Client:** Flutter (Web/Mobile cross-platform compilation).
*   **State Management:** Riverpod (Stream-based reactive UI).
*   **Mapping:** `google_maps_flutter`, Google Maps JavaScript API (Web layer).
*   **Real-time Engine & Database:** Firebase Cloud Firestore (NoSQL, stream listeners).
*   **Agentic Backend:** Node.js backend deployed on Google Cloud Run (event-driven microservice architecture).
*   **AI / Brain:** Google Cloud Vertex AI (Gemini 2.0 Pro via Node.js SDK) using advanced **Function Calling/Tools**.
*   **Location Intelligence:** Google Routes API (Polyline generation), Google Geocoding/Places API.

---

## 3. Architecture & Component Design

### 3.1 Client-Side (Flutter App)
The frontend acts as a **"Dumb Terminal + Smart Visualizer."** It executes no complex AI logic. It exclusively listens to Firestore Streams and renders data.
*   **`MapScreen` Widget:** Holds the `GoogleMap` widget.
*   **`ShipmentProvider` (Riverpod):** A `StreamProvider` that listens to `firestore.collection('ActiveShipments')`.
*   **`TruckAnimator` Service:** Listens to position changes in the stream. Uses a `TweenAnimationBuilder` to smoothly animate the latitude/longitude marker between current location and next step over 1.5 seconds.
*   **`SimulatorPanel` Widget:** A debug UI overlaid on the map to inject mock events (e.g., "Trigger NH-44 Landslide") directly into the Backend by triggering an API call.

### 3.2 Server-Side (Node.js Autonomous Agent)
The Cloud Run Node.js instance serves as the intelligent watcher.
*   **`SimulatorController`:** Receives mock events from the Frontend's Simulator Panel.
*   **`ContextAssembler`:** When an event is injected, it fetches the current state of *all* `ActiveShipments` from Firestore, active weather mock APIs, and `market_prices.json`.
*   **`AgenticEngine`:** Formulates the master prompt with System Instructions and attached schemas (Tools). Sends the aggregated payload to Vertex AI Gemini 2.0 Pro.
*   **`ExecutionEngine`:** Parses the guaranteed JSON function call returned by Gemini, interacts with the Google Routes API to fetch the new Polyline, and pushes the updated structured data back to Firestore.

---

## 4. Database Schema (Firestore)

### Collection: `ActiveShipments`
Handles real-time states. Listened to directly by Flutter via WebSockets (Firestore Streams).

```typescript
// Document ID: auto-generated (e.g., "ship_1042")
{
  "status": string, // "ON_TRACK", "CRITICAL", "DIVERTED"
  "cargo": {
    "type": string, // "AGRI_PERISHABLE", "MEDICAL_URGENT"
    "description": string, // e.g., "5 Tonnes Tomatoes"
    "value_inr": number, 
    "spoilage_time_hours": number 
  },
  "telemetry": {
    "vehicle_id": string,
    "current_location": {
      "lat": number,
      "lng": number
    },
    "bearing": number, // Heading angle for 3D truck orientation
    "temperature_celsius": number 
  },
  "route_data": {
    "target_destination_name": string,
    "encoded_polyline": string,
    "eta_epoch_ms": number
  },
  "agent_metadata": {
    "latest_action_log": string, // e.g., "Diverted to Agra market for +₹20k margin."
    "financial_salvage_inr": number // Populates only on intervention
  }
}
```

---

## 5. Agentic AI Integration Design (Vertex AI Function Calling)

To prevent hallucinations, the system relies strictly on Function Calling (Tools).

**Tool Schema Definition injected into Gemini:**
```javascript
const agentTools =[{
  name: "execute_autonomous_triage",
  description: "Triggers when a crisis requires route divergence or intercept. Generates new routing constraints.",
  parameters: {
    type: "OBJECT",
    properties: {
      "vehicle_id": { "type": "STRING" },
      "action_type": { "type": "STRING", "enum":["MARKET_ARBITRAGE_DIVERSION", "HOSPITAL_TRIAGE", "VEHICLE_INTERCEPT"] },
      "new_target_location": { "type": "STRING" }, // Addressed to Geocode
      "justification_log": { "type": "STRING" },
      "calculated_salvage_value": { "type": "NUMBER" }
    },
    required:["vehicle_id", "action_type", "new_target_location", "justification_log", "calculated_salvage_value"]
  }
}];
```
**Data Flow Logic:** 
1. Prompt passes Cargo State + Delay Event to Gemini 2.0 Pro.
2. Gemini returns `execute_autonomous_triage({vehicle_id: "MH-12", action_type: "MARKET_ARBITRAGE_DIVERSION", new_target_location: "Agra Wholesale", ...})`.
3. Node.js backend geocodes "Agra Wholesale", gets Lat/Lng, calls Routes API for the new polyline.
4. Node.js updates Firestore document. UI Updates automatically.

---

## 6. Key UI Algorithms (Mathematical Implementation)

### Bearing (Heading) Calculation for Truck Animation
To prevent the map icon from moving rigidly, the bearing angle (where the nose of the truck points) must be calculated between coordinate `A` (current) and coordinate `B` (next step) before animation triggers.

**Algorithm (Dart/Flutter implementation constraint):**
```dart
double calculateBearing(double startLat, double startLng, double endLat, double endLng) {
  var longitude1 = startLng;
  var longitude2 = endLng;
  var latitude1 = vector_math.radians(startLat);
  var latitude2 = vector_math.radians(endLat);
  var longDiff = vector_math.radians(longitude2 - longitude1);
  
  var y = math.sin(longDiff) * math.cos(latitude2);
  var x = math.cos(latitude1) * math.sin(latitude2) - 
          math.sin(latitude1) * math.cos(latitude2) * math.cos(longDiff);
          
  return (vector_math.degrees(math.atan2(y, x)) + 360) % 360;
}
```

### Route Decoupling & Movement Simulation
To mimic a live-driving GPS scenario for the judges without draining GPS location APIs:
1. Decode the Google Maps Polyline string into an array of `LatLng` points on the backend.
2. The Node.js `Watcher` script iteratively reads this array, taking one `LatLng` per 2 seconds.
3. Backend writes the updated `current_location` coordinate to Firestore.
4. Flutter picks up the new coordinate, recalculates the `bearing` (above), and applies a `TweenAnimationBuilder` to gracefully slide the asset icon over 1.5 seconds.

---

## 7. Execution Timeline Integration

1.  **Phase 1:** Core structure setup (Flutter Canvas, GCP API Enables).
2.  **Phase 2:** Node.js Backend creation + Mock Polylines parsing loop.
3.  **Phase 3:** Agentic brain integration (Vertex SDK setup, logic tuning).
4.  **Phase 4:** Simulator Panel injection + Demo capture sequence tuning.
