# Fleet Stack API Map (From `X-Fleet.postman_collection.json`)

This project includes a Postman collection: `X-Fleet.postman_collection.json`.

## Base URL + Token

- Base URL is represented as `{{host}}` in the Postman collection.
- Most protected endpoints expect:
  - `Authorization: bearer <token>`
- Token is obtained via `POST /auth/login`.

## Auth (Public)

- `POST /auth/login`
- `GET /auth/checksadmin`
- `POST /auth/createsuperadmin`

## Health (Public)

- `GET /health`
- `GET /health/databases`
- `GET /health/primary-db`
- `GET /health/logs-db`
- `GET /health/address-db`

## Common (Public Reference Data)

Reference endpoints that do not require a token:

- `GET /countries`
- `GET /states/{countryCode}`
- `GET /cities/{...}`
- `GET /timezones`
- `GET /languages`
- `GET /dateformats`
- `GET /currencies`
- `GET /mobileprefix`
- `GET /devicestypes`
- `GET /vehicletypes`
- `GET /simproviders`
- `GET /documenttypes/{associateType}`
- `GET /version`
- `GET /status`
- `GET /policies`
- `GET /policies/{type}`
- `GET /branding?host=...`

Other absolute URLs present in the collection:

- `GET https://agent.fleetstack.in/webhook/ftversion`
- `POST https://agent.fleetstack.in/webhook/validate-license`

## Superadmin (Protected)

Most endpoints under `/superadmin/...` require a token. The collection includes domains like:

- Dashboard
- Vehicles
- Support Tickets
- Map & Telemetry
- Calendar
- Landmarks
- Uploads / Documents
- Settings (whitelabel, branding, SMTP, SSL, roles, policies)

## Admin (Protected)

Most endpoints under `/admin/...` require a token. The collection includes domains like:

- Payments / Transactions
- Vehicles / Sensors / Bulk jobs
- Users
- Support Tickets
- Uploads / Documents

## User (Protected)

Most endpoints under `/user/...` require a token. The collection includes domains like:

- Drivers / Driver Documents
- Vehicles / Vehicle Documents / Sensors
- Geofences / POIs / Routes
- Share Track Links
- Sub Users
- Custom Dashboards
- Support Tickets

