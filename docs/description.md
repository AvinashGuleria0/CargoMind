# CargoMind AI: Autonomous Logistics & Triage Agent
**Google Solution Challenge 2026 - Problem Statement 3 (Smart Supply Chains)**

## 1. Project Overview (What it is)
**CargoMind AI** is a proactive, event-driven B2B logistics SaaS platform designed for high-stakes, time-sensitive cargo (Medical and Agricultural). 

Traditional fleet management software and standard GPS solutions are **reactive and cargo-blind**—they tell a driver how to escape traffic, but they do not know *what* is inside the truck. CargoMind changes this by introducing an **Autonomous AI Agent**. The system knows the exact constraints of the payload (e.g., "Blood expires in 4 hours," "Tomatoes will rot if delayed by 2 days"). 

When an unpredictable supply chain disruption occurs (weather events, road blocks, refrigeration failure), CargoMind does not just alert the manager; it uses **Vertex AI (Gemini 2.0 Pro)** to autonomously reason the economic or life-saving impact, execute a dynamic triage protocol, instantly reroute the vehicle to a new optimized destination, and notify all stakeholders without requiring a single human click.

## 2. Who is it for? (Target Audience & Impact)
*   **Medical Logistics Providers (Cold-Chain):** Transporting vaccines, blood, or organs where a delay means a total loss of life-saving assets.
*   **Agricultural Fleet Managers / Corporate Shippers:** Moving perishable goods where unpredictable Indian supply chain delays currently cause 30-40% of food spoilage before reaching the market.
*   **The Ultimate Impact:** CargoMind acts as "Payload Insurance." It saves fleets millions of rupees by executing predictive financial salvages (diverting rotting food to closer markets) and saves lives by preventing cold-chain medical supplies from expiring in highway standstills.

## 3. Core Features & Unique Selling Points (The "Genius" Details)
1.  **Payload-Aware AI Triage:** The AI evaluates live route delays against the cargo’s *shelf-life and storage temperature*. 
2.  **Predictive Market Arbitrage (Agriculture):** If a food delivery to Delhi is blocked, the AI fetches live commodity pricing data (simulated). It doesn’t just reroute to the nearest market; it routes to the *most profitable* nearest market (e.g., bypassing Jaipur for Agra because Agra pays ₹20 more per kg), saving the farmer's margins.
3.  **Vehicle-to-Vehicle Intercepts (Medical):** If an organ-transport truck suffers an AC failure, the AI dynamically scans all other active fleet trucks, calculates an exact halfway meeting coordinate (gas station/plaza), and routes *both* vehicles there for a mid-highway cargo transfer.
4.  **Zero-Touch Automated Stakeholder Sync:** Upon rerouting, Gemini automatically drafts and fires an SMS/Email to the destination hospital or buyer (e.g., *"Truck delayed. Triage activated. Sending backup via drone. ETA 1 Hr."*).
5.  **Interactive "Crisis Simulator" UI:** Built specifically for the hackathon demo, the frontend features a God-Mode control panel allowing judges to artificially drag up the truck's temperature or trigger a highway collapse, instantly watching the AI's real-time reasoning and map-redraw process.

## 4. The Technology Stack (Max Google Tech Integration)
*   **Frontend User Interface:** **Flutter (Web)** for a highly responsive, cross-platform dashboard. Uses `google_maps_flutter` for rendering and **Riverpod** for strict state management.
*   **The Agent "Brain":** **Google Cloud Vertex AI (Gemini 2.0 Pro)** utilizing **Function Calling/Tools**. Gemini is constrained to output *strictly structured JSON*, ensuring 0% hallucination and 100% executable system code.
*   **Real-time Engine:** **Firebase Cloud Firestore**. The UI uses WebSockets to listen to document streams. When the AI changes a route, the DB updates, and the UI map instantly shifts without refreshing.
*   **Backend / Middleware:** **Node.js** running on **Google Cloud Run** to securely process mapping logic, handle API keys, and run the background watcher loop.
*   **Location Intelligence:** **Google Maps Platform** (Maps JS API for rendering, Routes API for truck-specific polyline drawing, and Geocoding/Places API to locate emergency hospitals/markets).

## 5. Detailed Step-by-Step Workflow (The "Golden Path")
Here is exactly how data moves through the system from start to finish during your presentation:

*   **Step 1: Normal Operations (The Watcher)**
    The system reads pre-encoded route Polylines. The Node.js backend pushes the next latitude/longitude coordinate to Firestore every 2 seconds. The Flutter frontend listens to this data, calculates the *bearing* (heading angle) mathematically, and uses a `TweenAnimationBuilder` to smoothly animate the 3D truck icon across the map without stuttering.
*   **Step 2: The Crisis Injected**
    The user (Demo Admin) clicks "Trigger Protest / NH-44 Blockage" on the simulator panel.
*   **Step 3: Context Assembly (Node.js)**
    The backend catches this alert. It aggregates the data: *[Cargo: 5 Tonnes Tomatoes, Time to Spoil: 10 Hours, Original Route Delay: 24 Hours, Active Location: Lat/Lng]*
*   **Step 4: AI Reasoning (Vertex AI)**
    The backend sends this payload to Gemini 2.0 Pro. Gemini processes the constraints. It realizes 24 hours > 10 hours. The tomatoes will rot. 
*   **Step 5: Action Formulation (Function Calling)**
    Gemini checks the `market_prices.json` (or mock API). It formulates an execution plan and outputs strict JSON back to the backend calling the specific tool: `executeMarketArbitrage(market: "Agra Wholesale", financial_salvage: 275000)`.
*   **Step 6: Geospatial Resolution**
    Node.js passes "Agra Wholesale" to the Google Geocoding API, gets the new destination coordinates, and calls the Google Routes API to generate a new encoded polyline path starting from the truck's *exact current location*.
*   **Step 7: Real-Time Sync & UI Feedback**
    The backend overwrites the document in Firestore with the new polyline and target. 
    In milliseconds, the Flutter Map UI instantly redraws the polyline in high-contrast routing colors. A toast notification appears displaying the Gemini-generated reasoning: *"⚠️ Incident Managed: Rerouted to Agra to prevent spoilage. Expected salvage: ₹2.75 Lakhs."*
*   **Step 8: Stakeholder Sync**
    A webhook hits an SMS API provider alerting the initial buyer that the shipment is canceled and dispatched elsewhere to mitigate losses.

## 6. Challenges Addressed & Solved
*   *How do you prevent the AI from making fake places?* By using Vertex AI **Function Calling**. Gemini is not allowed to generate map coordinates; it is only allowed to select from verified logical strategies, which are then passed securely to Google's deterministic Geocoding APIs.
*   *How does the map not lag with real-time updates?* By using **Riverpod StreamProviders** and abstracting the map state away from the Flutter build logic. Only the marker coordinate is repainted using native interpolation, mimicking enterprise GPS apps (like Uber).

***

### Summary for Judges
CargoMind AI represents the leap from "Maps that tell you where to go" to **"Agentic systems that understand what is at stake."** By wrapping Google Maps APIs, Firebase's real-time speed, and Vertex AI's deep multimodal reasoning into a clean, intuitive Flutter dashboard, CargoMind fundamentally solves the chronic intelligence gap in high-stakes global supply chains.