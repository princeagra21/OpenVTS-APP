# User Screen API Audit

- Date: 2026-03-10 18:42:37Z
- Base URL tested: `http://15.206.76.175:4000`
- User used: `devuser0310121320@fleetstack.dev`
- Audit method: live API checks + code review of routed User screens, repositories, models, and child widgets

## Summary

- This pass checks the **actual routed User screens** against both:
  - the live backend responses
  - the Flutter code that consumes those responses
- Status legend:
  - `Match`: screen UI fields are backed by the current API shape used in code
  - `Partial`: screen works, but some visible actions/modes are still local-only or blocked by missing backend support
  - `Missing`: routed screen exists, but the backend path required for the main action is missing or failing live
  - `Local-only`: navigation/menu screen, no direct backend dependency

## Routed Screen Audit

### Home `/user/home`
- Status: **Match**
- APIs:
  - `GET /user/dashboard/fleet-status` -> HTTP 200
  - `GET /user/dashboard/usage-last-7-days` -> HTTP 200
  - `GET /user/dashboard/recent-alerts?limit=20` -> HTTP 200
  - `GET /user/dashboard/top-performing-assets?limit=10` -> HTTP 200
- Code match:
  - `OverviewBox` reads `totalVehicles`, `withDevice`, `noDevice`, `totalDrivenKm`, `totalEngineHours`, `alertCount`
  - `VehicleStatusBox` reads `running`, `idle`, `stopped`, `inactive`, `noData`, percentages
  - `RecentActivityBox` reads alert title/message/time
  - `TopCustomersBox` reads top asset title/subtitle/metric
- Notes: This screen now genuinely matches the repositories and child widgets.

### Map `/user/maps`
- Status: **Partial**
- APIs:
  - `GET /user/map-telemetry` -> HTTP 200
  - `GET /user/vehicles/by-imei/:imei/trail` -> HTTP 200
  - `GET /user/vehicles/by-imei/:imei/replay` -> HTTP 200
  - `GET /user/vehicles/by-imei/:imei/history` -> HTTP 200
- Code match:
  - marker rendering reads `vehicleId`, `imei`, `plateNumber`, `lat`, `lng`, `status`, `updatedAt`
  - live mode is fully API-backed
  - history/playback are wired to the documented endpoints and parse point lists correctly
- Remaining gap:
  - `Traffic` control is UI-only; no traffic backend/tile layer is confirmed
- Notes: Live, history, and playback paths match code. Only traffic mode does not.

### Tools menu `/user/admin`
- Status: **Local-only**
- APIs: none
- Notes: This is a navigation hub only.

### Share Track list `/user/share-track`
- Status: **Partial**
- APIs:
  - `GET /user/sharetracklinks` -> HTTP 200
  - `PATCH /user/sharetracklinks/:id` -> live path wired for pause/resume
  - `DELETE /user/sharetracklinks/:id` -> live path wired
- Code match:
  - list item UI reads `displayName`, `finalUrl`, `expiryAt`, `statusLabel`, `vehicles`, `views`, `lastOpenedAt`
  - pause/resume/delete actions are real
- Remaining gap:
  - `Edit` action is visible but intentionally unavailable because full edit payload is not confirmed
  - `QR Code` action is visible but UI-only/unavailable
- Notes: Core list is real. Visible extra actions make this screen partial, not full match.

### Share Track add `/user/share-track/add`
- Status: **Match**
- APIs:
  - `GET /user/vehicles` -> HTTP 200
  - `POST /user/sharetracklinks` -> HTTP 201
- Code match:
  - current UI only exposes confirmed fields:
    - vehicles
    - expiry date
    - expiry time
    - geofence
    - history
  - unsupported UI fields were removed
- Notes: This screen now matches the backend contract cleanly.

### Vehicles list `/user/vehicles`
- Status: **Match**
- APIs:
  - `GET /user/vehicles` -> HTTP 200
- Code match:
  - UI reads `plateNumber/name`, `imei`, `gmtOffset`, `updatedAt/createdAt`, `primaryExpiry/secondaryExpiry`, `status/isActive`
  - all rendered fields exist in `VehicleListItem`
- Notes: Real list matches the model and UI.

### Vehicle Details `/user/vehicles/details/:id`
- Status: **Match**
- APIs:
  - `GET /user/vehicles/:id` -> HTTP 200
- Code match:
  - details screen reads `id`, `name`, `plateNumber`, `vin`, `imei`, `simNumber`, `vehicleType.name`, `gmtOffset`, `device.*`, `plan.*`
  - vehicles list card tap now routes to the details screen
- Notes: User vehicle details is now wired to the real endpoint.

### Add Vehicle `/user/vehicles/add`
- Status: **Missing**
- APIs:
  - `GET /vehicletypes` -> HTTP 200
  - `POST /user/vehicles` -> HTTP 404
- Code match:
  - UI builds payload for `name`, `plateNumber`, `imei`, `vin`, `vehicleTypeId`, `gmtOffset`
- Blocking issue:
  - live backend still returns `404 Cannot POST /user/vehicles`
- Notes: Screen is wired correctly on the client side, but the main backend create path is not working live.

### Drivers list `/user/drivers`
- Status: **Match**
- APIs:
  - `GET /user/drivers` -> HTTP 200
- Code match:
  - UI reads `fullName`, `statusLabel`, `fullPhone`, `email`, `addressLocation`
  - all values come from `AdminDriverListItem`
- Notes: Good match.

### Add Driver `/user/drivers/add`
- Status: **Match**
- APIs:
  - `GET /mobileprefix` -> HTTP 200
  - `GET /countries` -> HTTP 200
  - `POST /user/drivers` -> HTTP 201
- Code match:
  - UI sends `name`, `mobilePrefix`, `mobile`, `email`, `username`, `password`, `countryCode`, `stateCode`, `city`, `address`
- Notes: Good match.

### Geofence Management `/user/geofence`
- Status: **Match**
- APIs:
  - `GET /user/geofences` -> HTTP 200
  - `GET /user/routes` -> HTTP 200
  - `GET /user/pois` -> HTTP 200
  - `POST /user/geofences` -> HTTP 201
  - `POST /user/routes` -> HTTP 201
  - `POST /user/pois` -> HTTP 201
- Code match:
  - map renders circles/polygons/routes/POIs from the response geodata
  - create flows use the live resource endpoints
- Notes: Good match for the current screen scope.

### Route Optimization `/user/route-optimization`
- Status: **Partial**
- APIs:
  - `GET /user/routes` -> HTTP 200
  - `GET /user/routes/:id` -> HTTP 200
  - `POST /user/routes` -> HTTP 201
  - `PATCH /user/routes/:id` -> live path wired
  - `DELETE /user/routes/:id` -> live path wired
- Code match:
  - screen correctly hydrates from `UserRouteItem.coordinates`
  - save/load/delete of route resources are real
- Remaining gap:
  - route optimization itself is still client-side; no backend optimize endpoint exists
  - assign driver is still local-only
- Notes: Resource CRUD matches. Optimization workflow does not fully exist on backend.

### Support `/user/support`
- Status: **Partial**
- APIs:
  - `GET /user/tickets` -> HTTP 200
  - `GET /user/tickets/:id` -> HTTP 200
  - `POST /user/tickets` -> HTTP 201
  - `POST /user/tickets/:id` -> HTTP 200
- Code match:
  - list screen reads `ticketNo`, `title/subject`, `status`, `createdAt`, `owner/snippet`
  - details screen reads ticket details and message list from `UserTicketDetails`
  - reply send is real
- Remaining gap:
  - status dropdown is visible but User status-update endpoint is not confirmed
  - `Generate Answer` is visible but no AI endpoint exists
- Notes: Main inbox/conversation flow is real, but visible unsupported actions keep this partial.

### Profile `/user/profile`
- Status: **Match**
- APIs:
  - `GET /user/profile` -> HTTP 200
- Code match:
  - screen reads `fullName`, `username`, `role`, `isActive`, `emailVerified`, `lastLoginAt`, `createdAt`, `passwordChangedAt`
  - all rendered fields exist in `AdminProfile`
- Child flows:
  - `Edit Profile` modal -> **Match** to `PATCH /user/profile`
  - `Update Password` modal -> **Match** to `PATCH /user/updatepassword`
- Notes: Verification endpoints exist separately but are not currently part of this screen UI. The current screen and its modals match the wired APIs.

### Generate Report `/user/generate-report`
- Status: **Missing**
- APIs: none confirmed
- Code match:
  - screen intentionally renders an honest unavailable message
- Notes: No backend endpoint exists for this screen yet.

### Localization `/user/localization`
- Status: **Match**
- APIs:
  - `GET /languages` -> HTTP 200
  - `GET /dateformats` -> HTTP 200
  - `GET /timezones` -> HTTP 200
  - `GET /user/localization` -> HTTP 200
  - `PATCH /user/localization` -> wired
- Code match:
  - screen reads `languageCode`, `direction`, `dateFormat`, `use24Hour/timeFormat`, `timezone`, `units`, `mapLat`, `mapLng`, `mapZoom`
  - all fields exist in `AdminLocalizationSettings`
- Notes: Good match.

### Notifications Inbox `/user/notifications`
- Status: **Match**
- APIs:
  - `GET /user/notifications` -> HTTP 200
  - `PATCH /user/notifications/:id/read` -> wired
  - `PATCH /user/notifications/read-all` -> wired
- Code match:
  - screen reads `title`, `body`, `createdAt`, `type`, `isRead`
  - all fields exist in `AdminNotificationItem`
- Notes: Good match.

### Notification Settings `/user/notification-settings`
- Status: **Match**
- APIs:
  - `GET /user/notifications/preferences` -> HTTP 200
  - `PUT /user/notifications/preferences` -> wired
- Code match:
  - list screen reads the channel matrix through `UserNotificationPreferences.items`
  - child toggle route `/user/toggle/:eventType` edits one event type from the same payload
- Legacy endpoint note:
  - `GET /user/notification-settings` exists but is not the source used by the app because it does not provide the matrix this UI needs
- Notes: Current implementation matches the actual useful backend endpoint.

### Notification toggle details `/user/toggle/:eventType`
- Status: **Match**
- APIs:
  - `GET /user/notifications/preferences` -> HTTP 200
  - `PUT /user/notifications/preferences` -> wired
- Code match:
  - screen edits one `UserNotificationPreferenceItem`
  - per-channel toggles map directly to `notifyEmail`, `notifyWhatsapp`, `notifyWebPush`, `notifyMobilePush`, `notifyTelegram`, `notifySms`
- Notes: Good match.

### Sub-users `/user/sub-users`
- Status: **Match**
- APIs:
  - `GET /user/subusers` -> HTTP 200
- Code match:
  - list reads `name`, `username`, `email`, `fullPhone`, `permissionsLabel`, `statusLabel`
  - all fields exist in `UserSubUserItem`
- Notes: Good match.

### Add Sub-user `/user/sub-users/add`
- Status: **Match**
- APIs:
  - `GET /mobileprefix` -> HTTP 200
  - `POST /user/subusers` -> HTTP 201
- Code match:
  - UI sends `name`, `username`, `email`, `mobilePrefix`, `mobileNumber`, `password`, `isActive`
- Notes: Good match.

### More menu `/user/more`
- Status: **Local-only**
- APIs: none
- Notes: This is a navigation hub only.

### Transactions `/user/transactions`
- Status: **Partial**
- APIs:
  - `GET /user/transactions` -> HTTP 200
- Code match:
  - list screen reads `items`, `page`, `limit`, `total` from `UserTransactionsPage`
  - each row reads `reference/invoice`, `status`, `method`, `amount`, `credits`, `createdAt` from `AdminTransactionItem`
- Remaining gap:
  - no User transaction-details endpoint is confirmed
  - no receipt endpoint is confirmed
- Notes: List view is real. The overall transaction flow is still partial.

### Transaction Details `/user/transactions/details/:id`
- Status: **Partial**
- APIs:
  - no dedicated details endpoint confirmed
- Code match:
  - screen renders from the tapped list item passed through route `extra`
- Remaining gap:
  - no live details/receipt backend contract
- Notes: This is intentionally list-item-backed, not API-detail-backed.

## Key Code-vs-Backend Gaps

- `POST /user/vehicles` still fails live with `404`, so Add Vehicle remains blocked by backend.
- Map `Traffic` control still has no confirmed backend/tile support.
- Share Track list still shows visible `Edit` and `QR` actions that are not backend-backed.
- Route Optimization still has no backend optimize endpoint and no persisted assign-driver endpoint.
- Support still shows visible actions not backed for User: status update and AI answer.
- Transactions still have no User details/receipt endpoints.
- Generate Report still has no backend endpoint.

## Current Data Snapshot

- Vehicles visible to current user: 1
- Drivers visible to current user: 3
- Sub-users visible to current user: 2
- Geofences visible to current user: 2
- Routes visible to current user: 2
- POIs visible to current user: 1
- Share links visible to current user: 1
- Tickets visible to current user: 2
- Transactions visible to current user: 2
