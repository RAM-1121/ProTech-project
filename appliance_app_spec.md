# Appliance Service App Specification

## 1. App Features

| App Role | Category | Feature Name | Detailed Description | Priority |
| :--- | :--- | :--- | :--- | :--- |
| Customer | Onboarding | Profile & Authentication | Registration/Login via Email OTP or OAuth (Google/Apple), profile management, and saving geolocation-tagged addresses. | High |
| Customer | Booking | Service Catalog & Booking | Select appliance, choose the issue, select a time slot, and attach photos/videos of the problem. | High |
| Customer | Tracking | Real-Time Tracking | Live GPS map tracking of the assigned executive with accurate ETA based on traffic. | High |
| Customer | Communication | In-App Audio/Video & Chat | Matrix-powered secure chat and LiveKit-powered WebRTC audio/video calls with the assigned executive. | High |
| Customer | Payments | Dynamic Billing & Payments | Real-time bill updates and UPI deep-linking (redirecting to GPay, PhonePe, Paytm) for seamless checkout. | High |
| Customer | Management | Booking Management | View active bookings, historical services, and reschedule/cancel options before dispatch. | Medium |
| Customer | Post-Service | Ratings & Reviews | Post-service 5-star rating system and text review for the executive's work. | Medium |
| Customer | Post-Service | Warranty & AMC Tracking | Track Annual Maintenance Contracts or warranties for parts replaced during previous repairs. | Low |
| Executive | Onboarding | KYC & Verification | Registration with document upload (ID, technical certifications) for admin verification. | High |
| Executive | Operations | Job Dashboard & Roster | View assigned jobs, upcoming time slots, and toggle 'On/Off Duty' status. | High |
| Executive | Navigation | Route & ETA Management | One-tap Google Maps integration for navigation; auto-updates ETA for the customer. | High |
| Executive | Operations | Job Execution & Status | Mark status updates progressively (Arrived, Diagnosing, Repairing, Completed). | High |
| Executive | Billing | Dynamic Invoicing | Add extra services or spare parts to the job card directly from the app, updating the customer instantly. | High |
| Executive | Quality | Proof of Work | Mandatory pre-repair and post-repair photo/video uploads to close a ticket and prevent disputes. | High |
| Executive | Payments | Payment Verification | Confirmation workflow when the customer pays via UPI (manual or auto-verify). | High |
| Executive | Dashboard | Earnings & Spare Parts | Dashboard for daily/weekly earnings and ability to request specific parts from inventory for a job. | Medium |
| Admin | Access | Role-Based Mobile UI | A dedicated admin login within the app that transforms the UI into a mobile management dashboard. | High |
| Admin | Operations | Mobile Dispatch & Routing | View auto-assigned jobs and manually override or reassign executives directly from the phone. | High |
| Admin | Tracking | Live Fleet Tracking | A map view showing all active executives, their current job status, and available fleet. | High |
| Admin | Management | User & Executive Management | Approve KYC documents, suspend accounts, and manage user disputes on the go. | High |
| Admin | Quality | Communication Oversight | Ability to review Matrix chat logs or call metadata for quality control and dispute resolution. | Medium |
| Admin | Config | Service & Pricing Catalog | Update base prices, visiting charges, taxes, and add-on prices in real-time. | High |
| Admin | Analytics | Mobile Analytics Dashboard | Quick-glance dashboard for daily revenue, completed jobs, and executive performance metrics. | Medium |
| System-Wide | Notifications | Strict Notification Engine | Push Notifications (primary alerts), In-App Messaging (booking state), Registered Email (invoices/OTP). Strictly NO SMS. | High |
| System-Wide | Architecture | Unified App Architecture | A single app binary downloaded from the store, serving 3 different UIs based on login role (JWT validation). | High |

## 2. Architecture & Tech Stack

| Architecture Layer | Component | Technology Chosen | Purpose & Justification |
| :--- | :--- | :--- | :--- |
| Frontend | Mobile App Framework | Flutter (Dart) | Allows a single codebase for iOS, Android, and Web Admin. Enables dynamic UI rendering based on the JWT user role. |
| Frontend | Routing | go_router | Handles role-based navigation securely so a Customer cannot accidentally route to an Admin screen. |
| Frontend | Real-Time Comms SDK | livekit_client & dart_matrix | Official Flutter libraries to implement WebRTC audio/video and Matrix decentralized chat natively. |
| Frontend | Maps & Location | google_maps_flutter | Renders custom maps, live tracking markers, and ETA polylines smoothly at 60fps. |
| Backend | Core Framework | Node.js with NestJS | Provides a highly scalable, modular, enterprise-grade REST and WebSocket API architecture using TypeScript. |
| Backend | Real-Time Engine | Socket.IO | Pushes live billing updates, dynamic invoice changes, and location status changes instantly to the app via WebSockets. |
| Database | Primary Relational DB | PostgreSQL | Stores users, roles, robust financial transactions, invoices, and job histories with strict ACID compliance. |
| Database | Spatial Queries | PostGIS (PG Extension) | Handles heavy location-based math (e.g., 'Find the nearest available AC technician within a 5km radius'). |
| Database | Caching & Live Location | Redis | Acts as an ultra-fast buffer for executives' constant GPS coordinate pings, preventing PostgreSQL from being overwhelmed. |
| Infrastructure | Video/Audio Server | LiveKit Server | Lightweight, scalable WebRTC server (written in Go) to handle peer-to-peer or relay audio/video calls securely. |
| Infrastructure | Chat Server | Matrix Synapse | Open-source decentralized communication server to handle all messaging, media attachments, and chat rooms securely. |
