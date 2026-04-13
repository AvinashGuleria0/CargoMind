# `hld.md` (High-Level Design) - CargoMind AI

## 1. Executive Summary
**CargoMind AI** is a proactive, agentic B2B supply chain ecosystem designed to prevent critical logistics failures. Instead of traditional reactive routing, CargoMind utilizes an event-driven AI agent (powered by Vertex AI Gemini 2.0 Pro) running asynchronously in the cloud. It monitors high-stakes cargo (Medical/Agricultural), predicts spoilage or bottlenecks based on external events, and autonomously executes triage protocols—like market arbitrage or vehicle intercepts—without human intervention.

## 2. System Architecture Architecture Diagram (Conceptual)
The system adopts an **Event-Driven, Decoupled Architecture**. The Frontend is completely separated from the AI Logic by a real-time Database Layer (Firestore).

```text
[ Simulator Panel / Webhooks ]
             |
             v (Injects Crisis Events via HTTP API)
             |
+-----------------------------------------------------+
|              NODE.JS AGENT (Cloud Run)              |
|  [ Event Listener ] ---> [ Context Aggregator ]     |
|                              |                      |
|[ Vertex AI Gemini 2.0 Pro ]       | <-- Evaluates State
|                 (Function Calling / Reasoning)      |     Outputs Triage JSON
|                              |                      |
|                  [ Geospatial Engine ]              | <-- Maps APIs (Routes/Geocoding)
+-----------------------------------------------------+
             | (Writes New Routes/Status)
             v
+-----------------------------------------------------+
|        FIREBASE FIRESTORE (Real-Time NoSQL DB)      | <-- Single Source of Truth
+-----------------------------------------------------+
             | (Pushes Streams via WebSockets)
             v
+-----------------------------------------------------+
|           FLUTTER FRONTEND (Web / Mobile)           |
|  [ Riverpod State ] --->[ UI Dashboard / Map ]     | <-- Smooth 3D Render
+-----------------------------------------------------+
```

## 3. Core Modules

### 3.1. User Interface Module (Flutter)
A lightweight, reactive client compiled for Web and Mobile.
*   **Role:** Solely responsible for visually representing the state of the database to the Fleet Manager.
*   **Responsibility:** Renders the Google Map, paints the Route Polylines, smoothly animates the moving assets, and displays notification toasts. It holds *no business logic*, ensuring the client app remains hyper-fast and lightweight.

### 3.2. Real-Time Middleware (Firebase Firestore)
Acts as the bridge between the AI Agent and the UI.
*   **Role:** Maintains the master state (`ActiveShipments`).
*   **Responsibility:** Provides WebSocket-driven streams to the Flutter client. When the Agent makes a routing decision, it writes to Firestore, which instantly and silently updates the frontend.

### 3.3. Autonomous Agent Engine (Node.js)
The core "Brain" of the platform, deployed continuously on Google Cloud Run.
*   **Watcher Daemon:** Simulates live GPS pings by slowly progressing vehicle coordinates along their assigned polylines.
*   **Event Trigger:** Listens for external shocks (mocked API weather updates, traffic jams, mechanical failures).
*   **Agent Pipeline:** When an event occurs, it gathers current vehicle coordinates, destination data, and cargo metrics, then packages them into a strictly typed system prompt.

### 3.4. Cognitive Intelligence Layer (Google Cloud Vertex AI)
Utilizing **Gemini 2.0 Pro**.
*   **Role:** Multi-variable decision making. 
*   **Responsibility:** Receives chaotic real-world inputs (e.g., "Bridge collapsed, shipment is tomatoes, expiry in 12 hours"). Computes the optimal financial or life-saving outcome using dynamic prompt schemas, and guarantees a structured JSON output (e.g., "Reroute to Market B, save ₹2 Lakhs") using Vertex Function Calling.

### 3.5. Geospatial Integration Module
The bridge between abstract AI decisions and physical world geography.
*   **Role:** Interacts with Google Maps Platform APIs.
*   **Components:** 
    *   *Geocoding API:* Translates Gemini's text output ("Agra Wholesale Market") into precise Latitude/Longitude.
    *   *Routes API:* Takes the new Lat/Lng and calculates a fresh polyline, distance, and ETA, accounting for heavy vehicles/trucks.

---

## 4. Standard Operation vs. Crisis Data Flow

### 4.1. "Happy Path" (Standard Logistics)
1. Backend Node.js loop increments truck position along `original_polyline`.
2. Writes new `{lat, lng}` to Firestore every 3 seconds.
3. Flutter UI receives update, interpolates bearing, and smoothly animates the truck marker. Map is green.

### 4.2. "Golden Path" Triage Flow (Crisis Event)
1. **Event Injected:** Admin uses Simulator to trigger "Refrigeration Failure" on Truck A.
2. **Context Assembly:** Node.js detects event. Pulls Truck A's state + local environment variables.
3. **AI Reasoning:** Vertex AI determines cargo will spoil in 45 mins. Calculates that destination is 2 hours away. Evaluates "Nearest Cold Storage" database.
4. **Tool Execution:** Vertex AI executes `trigger_emergency_divert({new_target: "Apollo Clinic Storage"})`.
5. **Geospatial Sync:** Node.js hits Geocoding + Routes API to fetch the Polyline to the Clinic.
6. **DB Write:** Overwrites Firestore document with `new_target` and `emergency_polyline`.
7. **UI Update:** Map instantly flashes RED. Old polyline vanishes. New route to the Clinic is drawn. Auto-SMS/Email is drafted for stakeholders.

---

## 5. Hackathon Criteria Alignment (Scalability & Security)

### Scalability
By separating the UI and AI logic using Firebase, the architecture natively scales. Flutter handles thousands of map markers smoothly due to Riverpod state containment. The Cloud Run backend scales horizontally to zero when inactive, mitigating costs, and can spin up instantly to handle fleet events.

### Security
All communication with Vertex AI and Google Maps APIs occurs Server-Side within the Google Cloud Platform (Node.js). No raw API keys are exposed to the Flutter Client. The Flutter client only has read-access to specific Firestore document streams configured via Firebase Security Rules. 
