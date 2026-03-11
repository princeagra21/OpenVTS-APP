# User Module Missing / Mismatched APIs

Date: 2026-03-10

## Summary

Most reachable User screens are now wired to real APIs. The remaining gaps are not UI wiring problems; they are backend coverage or backend-contract mismatches.

## Missing or mismatched APIs

### 1. Create Vehicle mismatch
- Screen: `User -> Vehicles -> Add Vehicle`
- UI currently shows:
  - IMEI field
  - Vehicle Number field
  - VIN field
  - GMT selector
  - Vehicle Type selector
  - `Add Vehicle` submit button
- Postman: `POST /user/vehicles`
- Postman body keys:
  - `name`
  - `vin`
  - `plateNumber`
  - `imei`
  - `simNumber`
  - `vehicleTypeId`
  - `gmtOffset`
- FleetStack-API-Reference.md:
  - documents `GET /user/vehicles`
  - documents `GET /user/vehicles/:id`
  - documents `PATCH /user/vehicles/:id`
  - does **not** document `POST /user/vehicles`
- Live probe:
  - `POST /user/vehicles` returned `404 Cannot POST /user/vehicles`
- Backend gap / mismatch:
  - mobile UI has a real create form
  - Postman says create exists
  - live backend does not expose the route
- Current app behavior:
  - screen submits the real payload
  - user sees the real backend failure instead of fake success

### 2. Route Optimization backend is incomplete
- Screen: `User -> Tools -> Route Optimization`
- UI currently shows:
  - waypoint selection / route building
  - optimize action
  - assign driver action
  - save/load route behavior
- Confirmed existing endpoints:
  - `GET /user/routes`
  - `GET /user/routes/:id`
  - `POST /user/routes`
  - `PATCH /user/routes/:id`
  - `DELETE /user/routes/:id`
- Missing endpoints:
  - no confirmed route optimization endpoint such as `POST /user/routes/optimize`
  - no confirmed route-to-driver assignment endpoint
  - no confirmed route share/email endpoint
- Backend gap / mismatch:
  - UI exposes optimize, assign, and email actions
  - backend only provides route CRUD
- Current app behavior:
  - route save/load is real
  - optimization remains client-side
  - Assign Driver is local-only
  - Email/share remains unavailable

### 3. Transactions details / receipt missing
- Screen: `User -> Transactions`
- UI currently shows:
  - transaction list
  - `View details`
  - `Receipt`
  - details screen route
- Confirmed existing endpoint:
  - `GET /user/transactions`
- Missing endpoints:
  - no confirmed `GET /user/transactions/:id`
  - no confirmed receipt / invoice / download endpoint
- Backend gap / mismatch:
  - UI has details and receipt affordances
  - backend only confirms list retrieval
- Current app behavior:
  - list is real
  - details screen uses list item data only
  - receipt action cannot be wired

### 4. Support advanced actions missing
- Screen: `User -> Support`
- UI currently shows:
  - ticket list
  - ticket conversation
  - status dropdown
  - `Generate Answer` button
  - reply box and send action
- Confirmed existing endpoints:
  - `GET /user/tickets`
  - `POST /user/tickets`
  - `GET /user/tickets/:id`
  - `POST /user/tickets/:id`
- Missing endpoints:
  - no confirmed ticket status update endpoint for User
  - no confirmed AI/generate-answer endpoint
- Backend gap / mismatch:
  - UI exposes status editing and AI answer generation
  - backend only confirms tickets list/details/create/reply
- Current app behavior:
  - tickets list/details/reply work
  - status change is not backend-backed
  - Generate Answer remains unavailable

### 5. Report generation API missing
- Screen: `User -> Generate Report`
- UI currently shows:
  - dedicated report screen route
  - report generation placeholder screen
- FleetStack-API-Reference.md:
  - no User report-generation endpoint found
- Postman:
  - no User report-generation endpoint found
- Backend gap / mismatch:
  - UI route exists
  - backend has no matching report API contract
- Current app behavior:
  - screen remains an honest unavailable placeholder until backend confirms report APIs

### 6. Notification settings scope mismatch
- Screen: `User -> Notification Settings`
- UI currently shows:
  - notification settings list
  - detail toggle screen per settings item
  - channel toggles such as email / mobile push / web push / WhatsApp / SMS
- Confirmed existing endpoints:
  - `GET /user/notification-settings`
  - `PUT /user/notification-settings`
  - `GET /user/notifications/preferences`
  - `PUT /user/notifications/preferences`
- Confirmed separate inbox endpoints:
  - `GET /user/notifications`
  - `GET /user/notifications/vehicle`
- Missing capability:
  - no confirmed per-vehicle notification preference endpoint matching the old vehicle-based toggle UI
- Backend gap / mismatch:
  - old UI semantics were vehicle-based
  - backend contract is event-type/channel-based
  - no dedicated per-vehicle settings endpoint was found
- Current app behavior:
  - mobile UI is now backed by the global event-type preferences matrix
  - old per-vehicle semantics are not supported by current backend contracts

## Operational issue (API exists, provider currently failing)

### 7. WhatsApp verification request
- Endpoints confirmed:
  - `POST /user/profile/verify/whatsapp/request`
  - `POST /user/profile/verify/whatsapp/confirm`
- UI currently shows:
  - verification state in profile
  - verification flow can request OTP
- Live probe result:
  - request endpoint returned `201` with payload `action: false`
  - backend message: failed to send WhatsApp verification code
- Backend/runtime issue:
  - API exists
  - provider delivery failed on the backend side
- Current app behavior:
  - verification flow can be wired
  - WhatsApp OTP delivery will still fail until backend/provider is fixed

## Recommended backend actions

1. Confirm and enable `POST /user/vehicles` on the live server, or remove it from Postman if it is not supported.
2. Provide a real route-optimization endpoint if route optimization should be server-driven.
3. Add User transaction details and receipt endpoints.
4. Add User ticket status-update and AI-answer endpoints if the UI should support them.
5. Provide report-generation endpoints for the User module.
6. Confirm whether notification settings are global-only or per-vehicle. If per-vehicle is required, add dedicated per-vehicle preference endpoints.
7. Fix WhatsApp verification provider delivery on the backend.
