


Here is the highly granular `checklist.md` document. It is broken down into phases so you can literally check off every single step from today until submission day on April 24, 2026. 

Save this in your repository as your ultimate source of truth for your 14-day sprint.

***

# `checklist.md` - CargoMind AI Master Sprint List
**Start Date:** April 12, 2026 | **Deadline:** April 24, 2026

## Phase 0: Setup & Google Cloud Provisioning (Day 1)
- [ ] **Google Cloud Platform (GCP)**
  - [ ] Create a new GCP Project named `cargomind-ai-2026`.
  - [ ] Link active billing account.
  - [ ] Enable **Google Maps JavaScript API**.
  - [ ] Enable **Google Routes API** (for truck polylines).
  - [ ] Enable **Google Geocoding API** (to convert AI text to lat/lng).
  - [ ] Enable **Vertex AI API** (for Gemini 2.0 Pro).
  - [ ] Generate GCP API Keys and restrict them (for security points).
- [ ] **Firebase Setup**
  - [ ] Create a new Firebase Project (link to existing GCP project).
  - [ ] Enable **Firestore Database** (Test Mode or specific security rules).
  - [ ] Register Web/Flutter app to generate `firebase_options.dart`.
  - [ ] Download Firebase Admin SDK private key (`serviceAccountKey.json`) for the Node.js backend.
- [ ] **GitHub Repository**
  - [ ] Initialize Git repo.
  - [ ] Add `hld.md`, `lld.md`, and `chat.md` to `docs/` folder.
  - [ ] Create folder structure: `/frontend` (Flutter) and `/backend` (Node.js).

## Phase 1: Database & Mock Data Layer (Day 2)
- [ ] **Firestore Configuration**
  - [ ] Create collection `ActiveShipments`.
  - [ ] Create mock document 1: `ship_101` (Type: MEDICAL_URGENT, Blood Vials).
  - [ ] Create mock document 2: `ship_102` (Type: AGRI_PERISHABLE, 5 Tonnes Tomatoes).
- [ ] **Environment Simulation Data (Node.js backend)**
  - [ ] Create `market_prices.json` (Mock dataset containing 5 Indian cities with dummy profitable crop prices).
  - [ ] Create `hospital_registry.json` (Mock dataset containing 3 local clinics for emergency medical drops).

## Phase 2: Agentic Backend (Node.js / Cloud Run) (Days 3-6)
- [ ] **Initialization**
  - [ ] `npm init` in `/backend`.
  - [ ] Install dependencies: `express`, `firebase-admin`, `@google/vertexai`, `axios`, `cors`.
  - [ ] Setup `index.js` to initialize Firebase Admin SDK.
- [ ] **The "Watcher" Loop (Movement Simulator)**
  - [ ] Write a script that reads an encoded polyline, decodes it into an array of `LatLng`.
  - [ ] Write a `setInterval` loop that pushes the next `LatLng` coordinate to the active Firestore document every 3 seconds to simulate vehicle movement.
- [ ] **The Event/Simulator Endpoint (Webhook)**
  - [ ] Create Express `POST /api/trigger-incident` endpoint.
  - [ ] Accept payload: `{ vehicle_id, incident_type, severity }`.
- [ ] **Vertex AI Integration (The Brain)**
  - [ ] Initialize `@google/vertexai` with Gemini 2.0 Pro.
  - [ ] Write the **System Instructions** prompt (Defining CargoMind's persona as an economic and life-saving triage agent).
  - [ ] Write the **Function Declaration (Tools)**: `execute_market_arbitrage(destination, latitude, longitude, expected_salvage)`.
  - [ ] Write the **Function Declaration (Tools)**: `execute_medical_triage(hospital_name, latitude, longitude)`.
- [ ] **Geospatial Sync Logic**
  - [ ] After Gemini selects a strategy, ping the Google Geocoding API to verify exact coordinates.
  - [ ] Ping the Google Routes API passing the truck's current location and the new AI-decided destination.
  - [ ] Extract the new `encoded_polyline` from Routes API.
  -[ ] Update the Firestore document with `status: DIVERTED`, the new polyline, and the AI Justification text.

## Phase 3: Frontend Client (Flutter) (Days 7-10)
- [ ] **Initialization & Dependencies**
  - [ ] `flutter create frontend`
  - [ ] Install dependencies: `google_maps_flutter`, `firebase_core`, `cloud_firestore`, `flutter_riverpod`, `vector_math`.
  - [ ] Apply dark-mode theme / clean UI scheme (Shadcn-like aesthetics).
-[ ] **State Management (Riverpod)**
  - [ ] Create `shipment_provider.dart` listening to Firestore `ActiveShipments` stream.
- [ ] **The Map View**
  - [ ] Initialize `GoogleMap` widget with a custom dark map style JSON.
  - [ ] Build polyline decoder in Dart to draw the route.
  - [ ] Apply logic: Green polyline = Normal, Red/Orange Polyline = Diverted/Crisis.
- [ ] **Smooth Truck Animation Logic (Critical for Polish)**
  - [ ] Import custom truck / delivery van icon assets as map markers.
  - [ ] Implement `calculateBearing()` math function (using vector math).
  - [ ] Wrap map marker updates in `TweenAnimationBuilder` to animate the icon smoothly across `Lat`/`Lng` between the 3-second database updates.
- [ ] **Dashboard UI Elements**
  - [ ] Left Sidebar: Active Fleet List (Cards showing Truck ID, Cargo Type, Current ETA).
  - [ ] Header/Toast: A real-time Notification banner that drops down when the AI triggers a triage (e.g., "Agent diverted Truck #2 - Salvage ₹1.2 Lakh").
- [ ] **The God-Mode Simulator Panel (For Demo Use)**
  - [ ] Create a semi-transparent floating widget/panel on the UI.
  - [ ] Add a Slider: "Truck Internal Temperature".
  - [ ] Add a Button: "Inject NH-44 Landslide (Delay +24 Hrs)".
  - [ ] Connect buttons to hit the Node.js backend `POST /api/trigger-incident` webhook.

## Phase 4: Integration & Golden Path Rehearsal (Days 11-12)
- [ ] Run the complete pipeline end-to-end.
- [ ] **Scenario 1 Check:** Verify agriculture truck moves normally -> click Protest button -> map flashes red -> route diverts to Agra -> AI logic toast appears.
- [ ] **Scenario 2 Check:** Verify medical truck moves normally -> drag temp slider up -> map updates to divert to nearest cold-storage clinic.
- [ ] Bug Hunt: Check for screen flickering on Flutter Map updates. Ensure AI tool-calling strictness (zero hallucinated map points).

## Phase 5: Submission & Hackathon Polish (Days 13-14: April 24)
- [ ] **Deployment**
  - [ ] Deploy Node.js backend to **Google Cloud Run**.
  - [ ] Deploy Flutter Web to **Firebase Hosting**.
  - [ ] Ensure all API keys are secure/restricted.
- [ ] **Submission Materials Preparation**
  - [ ] Update `README.md` with polished summary, screenshot of UI, and instructions to run.
  - [ ] Prepare GitHub Repository link (make it public).
  - [ ] **Record Demo Video (Max 2 mins / 5MB PDF format constraints from guidelines)**
    -[ ] Script out the voiceover.
    - [ ] Highlight UI polish.
    - [ ] explicitly point out "We are using Gemini 2.0 Pro Function Calling and Google Routes".
    - [ ] Highlight business value/Expected Impact (₹ salvaged).
  - [ ] Write the 2056-char brief overview (using text from `hld.md`).
  - [ ] Complete the mandatory Solution Challenge Submission Template PDF.
- [ ] **Final Form Submission (April 24, 2026 - Before 11:59:00 PM IST)**

***