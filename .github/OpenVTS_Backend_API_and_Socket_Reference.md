# OpenVTS Backend API & Socket Reference

Generated from static source review of `openVTS-main/backend/src` on 2026-05-09.

> Scope: This document is generated from NestJS controller/gateway source. It lists every route decorator found in backend controllers, request decorators/payload DTOs visible from signatures, standard response envelope, streaming endpoints, and Socket.IO channels. Always validate against `flutter analyze`/backend runtime for dynamic multipart parsing and service-specific response details.

## Runtime conventions

- **HTTP platform:** NestJS 11 with Fastify.
- **Global validation:** `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true, enableImplicitConversion: true })`.
- **CORS:** enabled with credentials; methods `GET, PUT, POST, DELETE, OPTIONS, PATCH, HEAD`.
- **Multipart:** Fastify multipart enabled, `fileSize` 5MB, max `files` 5, max `fields` 20.
- **Uploads:** served from `/uploads/` via Fastify static.
- **Response wrapper:** most controller return values are wrapped by `ResponseInterceptor` as:

```json
{ "status": "success", "data": {}, "timestamp": "2026-05-09T00:00:00.000Z" }
```

- **Exceptions/errors:** NestJS/Fastify exception responses may bypass the success wrapper and return standard error payloads with HTTP status code/message/error details.
- **Auth:** endpoints protected by `AuthGuard` require `Authorization: Bearer <jwt>`. Role-gated endpoints additionally use `RolesGuard`.
- **`@HeaderId()`:** derived from authenticated JWT `req.user.userId` or `req.user.sub`; it is not a manual HTTP header.

## Summary

- Controllers found: **16**
- HTTP endpoints found: **488**
- DTO/interface payload classes indexed: **266**
- Socket gateway/source files indexed: **5**

### Endpoint count by controller

| Controller | Endpoints | Source examples |
|---|---:|---|
| `AdminController` | 158 | `src/admin/admin.controller.ts` |
| `AgentController` | 3 | `src/agent/controllers/agent.controller.ts` |
| `AppController` | 19 | `src/app.controller.ts` |
| `AuthController` | 14 | `src/auth/controllers/auth.controller.ts` |
| `BugReportController` | 1 | `src/bug-report/bug-report.controller.ts` |
| `GeocodingController` | 3 | `src/geocoding/geocoding.controller.ts` |
| `HandledataController` | 1 | `src/handledata/handledata.controller.ts` |
| `HealthController` | 9 | `src/health/health.controller.ts` |
| `PublicTrackController` | 7 | `src/public-track/public-track.controller.ts` |
| `ServerController` | 4 | `src/superadmin/server/server.controller.ts` |
| `SslController` | 3 | `src/ssl/ssl.controller.ts` |
| `SslStreamController` | 1 | `src/ssl/ssl.controller.ts` |
| `SuperadminController` | 140 | `src/superadmin/superadmin.controller.ts` |
| `UserController` | 118 | `src/user/user.controller.ts` |
| `WhatsAppTemplatesController` | 5 | `src/superadmin/whatsapp-templates/whatsapp-templates.controller.ts` |
| `WhatsappWebhookController` | 2 | `src/webhooks/whatsapp-webhook.controller.ts` |

### Endpoint count by access role

| Role/access | Count |
|---|---:|
| `ADMIN` | 158 |
| `SUPERADMIN` | 152 |
| `ADMIN,USER` | 111 |
| `PUBLIC/UNSPECIFIED` | 54 |
| `USER` | 7 |
| `SUPERADMIN,ADMIN,USER,SUBUSER` | 3 |
| `SUPERADMIN,ADMIN,USER,SUBUSER,TEAM,DRIVER` | 3 |

## Quick endpoint index

| # | Method | Endpoint | Controller | Auth/Roles |
|---:|---|---|---|---|
| 1 | `GET` | `/` | `AppController.getHello` | Public |
| 2 | `GET` | `/admin/calendar/day` | `AdminController.getCalendarDayDetails` | JWT (ADMIN) |
| 3 | `GET` | `/admin/calendar/events` | `AdminController.getCalendarEvents` | JWT (ADMIN) |
| 4 | `GET` | `/admin/calendar/user/:uid` | `AdminController.getCalendarUserDetails` | JWT (ADMIN) |
| 5 | `GET` | `/admin/commands/:cmdId` | `AdminController.getCommandLogByCmdId` | JWT (ADMIN) |
| 6 | `GET` | `/admin/commands/status/:cmdId` | `AdminController.getCommandStatus` | JWT (ADMIN) |
| 7 | `PATCH` | `/admin/companydetails` | `AdminController.updateOwnCompanyDetails` | JWT (ADMIN) |
| 8 | `GET` | `/admin/companydetails/:id` | `AdminController.getCompanyDetails` | JWT (ADMIN) |
| 9 | `PATCH` | `/admin/companydetails/:id` | `AdminController.updateCompanyDetails` | JWT (ADMIN) |
| 10 | `PATCH` | `/admin/companyinfo/:id` | `AdminController.updateCompanyInfo` | JWT (ADMIN) |
| 11 | `GET` | `/admin/config` | `AdminController.getAdminConfig` | JWT (ADMIN) |
| 12 | `PATCH` | `/admin/config` | `AdminController.patchAdminConfig` | JWT (ADMIN) |
| 13 | `GET` | `/admin/customcommands` | `AdminController.getCustomCommands` | JWT (ADMIN) |
| 14 | `GET` | `/admin/dashboard/summary` | `AdminController.getDashboardSummary` | JWT (ADMIN) |
| 15 | `POST` | `/admin/deviceandsim` | `AdminController.createDeviceAndSim` | JWT (ADMIN) |
| 16 | `GET` | `/admin/devices` | `AdminController.getDevices` | JWT (ADMIN) |
| 17 | `POST` | `/admin/devices` | `AdminController.createDevice` | JWT (ADMIN) |
| 18 | `DELETE` | `/admin/devices/:id` | `AdminController.deleteDevice` | JWT (ADMIN) |
| 19 | `PATCH` | `/admin/devices/:id` | `AdminController.updateDevice` | JWT (ADMIN) |
| 20 | `GET` | `/admin/documents/:userId` | `AdminController.getDocuments` | JWT (ADMIN) |
| 21 | `GET` | `/admin/documents/driver/:driverId` | `AdminController.getDriverDocuments` | JWT (ADMIN) |
| 22 | `GET` | `/admin/documents/vehicle/:vehicleId` | `AdminController.getVehicleDocuments` | JWT (ADMIN) |
| 23 | `POST` | `/admin/driverbulkjobs` | `AdminController.createDriverBulkJob` | JWT (ADMIN) |
| 24 | `GET` | `/admin/driverbulkjobs/:id` | `AdminController.getDriverBulkJob` | JWT (ADMIN) |
| 25 | `GET` | `/admin/driverbulkjobs/:id/failed.csv` | `AdminController.downloadDriverFailedCsv` | JWT (ADMIN) |
| 26 | `GET` | `/admin/driverbulkjobs/:id/stream` | `AdminController.streamDriverBulkJob` | JWT (ADMIN) |
| 27 | `GET` | `/admin/drivers` | `AdminController.getDrivers` | JWT (ADMIN) |
| 28 | `POST` | `/admin/drivers` | `AdminController.createDriver` | JWT (ADMIN) |
| 29 | `DELETE` | `/admin/drivers/:id` | `AdminController.deleteDriver` | JWT (ADMIN) |
| 30 | `GET` | `/admin/drivers/:id` | `AdminController.getDriverById` | JWT (ADMIN) |
| 31 | `PATCH` | `/admin/drivers/:id` | `AdminController.updateDriver` | JWT (ADMIN) |
| 32 | `GET` | `/admin/drivers/:id/users` | `AdminController.getDriverUsers` | JWT (ADMIN) |
| 33 | `GET` | `/admin/drivers/linkedusers/:driverId` | `AdminController.getLinkedUsersForDriver` | JWT (ADMIN) |
| 34 | `POST` | `/admin/drivers/linkedusers/:driverId` | `AdminController.linkUsersToDriver` | JWT (ADMIN) |
| 35 | `GET` | `/admin/drivers/unlinkedusers/:driverId` | `AdminController.getUnlinkedUsersForDriver` | JWT (ADMIN) |
| 36 | `POST` | `/admin/drivers/unlinkedusers/:driverId` | `AdminController.unlinkUsersFromDriver` | JWT (ADMIN) |
| 37 | `POST` | `/admin/inventorybulkjobs` | `AdminController.createInventoryBulkJob` | JWT (ADMIN) |
| 38 | `GET` | `/admin/inventorybulkjobs/:id` | `AdminController.getInventoryBulkJob` | JWT (ADMIN) |
| 39 | `GET` | `/admin/inventorybulkjobs/:id/failed.csv` | `AdminController.downloadInventoryFailedCsv` | JWT (ADMIN) |
| 40 | `GET` | `/admin/inventorybulkjobs/:id/stream` | `AdminController.streamInventoryBulkJob` | JWT (ADMIN) |
| 41 | `GET` | `/admin/linkusers/:vehicleId` | `AdminController.getLinkedUsers` | JWT (ADMIN) |
| 42 | `POST` | `/admin/linkusers/:vehicleId` | `AdminController.linkUsers` | JWT (ADMIN) |
| 43 | `GET` | `/admin/linkvehicles/:userId` | `AdminController.getLinkedVehicles` | JWT (ADMIN) |
| 44 | `POST` | `/admin/linkvehicles/:userId` | `AdminController.linkVehicles` | JWT (ADMIN) |
| 45 | `GET` | `/admin/localization` | `AdminController.getLocalizationData` | JWT (ADMIN) |
| 46 | `PATCH` | `/admin/localization` | `AdminController.updateLocalizationData` | JWT (ADMIN) |
| 47 | `GET` | `/admin/logs/activity` | `AdminController.getActivityLogs` | JWT (ADMIN) |
| 48 | `GET` | `/admin/logs/events` | `AdminController.getEventLogs` | JWT (ADMIN) |
| 49 | `GET` | `/admin/logs/events/:id` | `AdminController.getEventLogById` | JWT (ADMIN) |
| 50 | `GET` | `/admin/logs/options` | `AdminController.getLogsOptions` | JWT (ADMIN) |
| 51 | `GET` | `/admin/logs/telemetry` | `AdminController.getTelemetryLogs` | JWT (ADMIN) |
| 52 | `GET` | `/admin/logs/telemetry/:id` | `AdminController.getTelemetryLogById` | JWT (ADMIN) |
| 53 | `GET` | `/admin/map-events` | `AdminController.getMapEvents` | JWT (ADMIN) |
| 54 | `GET` | `/admin/map-telemetry` | `AdminController.getMapTelemetry` | JWT (ADMIN) |
| 55 | `GET` | `/admin/mytickets` | `AdminController.listAdminMyTickets` | JWT (ADMIN) |
| 56 | `POST` | `/admin/mytickets` | `AdminController.createAdminMyTicket` | JWT (ADMIN) |
| 57 | `GET` | `/admin/mytickets/:id` | `AdminController.getAdminMyTicketById` | JWT (ADMIN) |
| 58 | `POST` | `/admin/mytickets/:id/messages` | `AdminController.replyAdminMyTicket` | JWT (ADMIN) |
| 59 | `PATCH` | `/admin/mytickets/:id/status` | `AdminController.updateAdminMyTicketStatus` | JWT (ADMIN) |
| 60 | `GET` | `/admin/notifications` | `AdminController.getNotifications` | JWT (ADMIN) |
| 61 | `PATCH` | `/admin/notifications/:id/read` | `AdminController.markNotificationRead` | JWT (ADMIN) |
| 62 | `PATCH` | `/admin/notifications/read-all` | `AdminController.markAllNotificationsRead` | JWT (ADMIN) |
| 63 | `GET` | `/admin/payments` | `AdminController.listAdminPayments` | JWT (ADMIN) |
| 64 | `POST` | `/admin/payments/renew` | `AdminController.renewVehiclesPayment` | JWT (ADMIN) |
| 65 | `GET` | `/admin/pricingplans` | `AdminController.getPricingPlans` | JWT (ADMIN) |
| 66 | `POST` | `/admin/pricingplans` | `AdminController.createPricingPlan` | JWT (ADMIN) |
| 67 | `PATCH` | `/admin/pricingplans/:id` | `AdminController.updatePricingPlan` | JWT (ADMIN) |
| 68 | `GET` | `/admin/profile` | `AdminController.getProfile` | JWT (ADMIN) |
| 69 | `PATCH` | `/admin/profile` | `AdminController.updateProfile` | JWT (ADMIN) |
| 70 | `GET` | `/admin/profile/email-subscription` | `AdminController.getEmailSubscription` | JWT (ADMIN) |
| 71 | `POST` | `/admin/profile/email-subscription/subscribe` | `AdminController.subscribeEmail` | JWT (ADMIN) |
| 72 | `POST` | `/admin/profile/verify/email/confirm` | `AdminController.verifyEmailOtp` | JWT (ADMIN) |
| 73 | `POST` | `/admin/profile/verify/email/request` | `AdminController.requestEmailOtp` | JWT (ADMIN) |
| 74 | `POST` | `/admin/profile/verify/whatsapp/confirm` | `AdminController.verifyWhatsAppOtp` | JWT (ADMIN) |
| 75 | `POST` | `/admin/profile/verify/whatsapp/request` | `AdminController.requestWhatsAppOtp` | JWT (ADMIN) |
| 76 | `GET` | `/admin/quickdevice` | `AdminController.getQuickDevices` | JWT (ADMIN) |
| 77 | `POST` | `/admin/quickdevice` | `AdminController.createQuickDevice` | JWT (ADMIN) |
| 78 | `GET` | `/admin/quicksimcards` | `AdminController.getQuickSimCards` | JWT (ADMIN) |
| 79 | `GET` | `/admin/shortusers` | `AdminController.getShortUsers` | JWT (ADMIN) |
| 80 | `GET` | `/admin/simcards` | `AdminController.getSimCards` | JWT (ADMIN) |
| 81 | `POST` | `/admin/simcards` | `AdminController.createSimCard` | JWT (ADMIN) |
| 82 | `DELETE` | `/admin/simcards/:id` | `AdminController.deleteSimCard` | JWT (ADMIN) |
| 83 | `GET` | `/admin/simcards/:id` | `AdminController.getSimCardById` | JWT (ADMIN) |
| 84 | `PATCH` | `/admin/simcards/:id` | `AdminController.updateSimCard` | JWT (ADMIN) |
| 85 | `GET` | `/admin/smtpconfig` | `AdminController.getSmtpConfig` | JWT (ADMIN) |
| 86 | `PATCH` | `/admin/smtpconfig` | `AdminController.patchSmtpConfig` | JWT (ADMIN) |
| 87 | `POST` | `/admin/smtpconfig` | `AdminController.updateSmtpConfig` | JWT (ADMIN) |
| 88 | `GET` | `/admin/systemvariables` | `AdminController.getSystemVariables` | JWT (ADMIN) |
| 89 | `GET` | `/admin/teams` | `AdminController.getTeams` | JWT (ADMIN) |
| 90 | `POST` | `/admin/teams` | `AdminController.createTeam` | JWT (ADMIN) |
| 91 | `DELETE` | `/admin/teams/:id` | `AdminController.deleteTeam` | JWT (ADMIN) |
| 92 | `GET` | `/admin/teams/:id` | `AdminController.getTeamById` | JWT (ADMIN) |
| 93 | `PATCH` | `/admin/teams/:id` | `AdminController.updateTeam` | JWT (ADMIN) |
| 94 | `POST` | `/admin/testsmtp` | `AdminController.testSmtpSettings` | JWT (ADMIN) |
| 95 | `GET` | `/admin/tickets` | `AdminController.listAdminTickets` | JWT (ADMIN) |
| 96 | `POST` | `/admin/tickets` | `AdminController.createAdminTicket` | JWT (ADMIN) |
| 97 | `GET` | `/admin/tickets/:id` | `AdminController.getAdminTicketById` | JWT (ADMIN) |
| 98 | `POST` | `/admin/tickets/:id/messages` | `AdminController.replyAdminTicket` | JWT (ADMIN) |
| 99 | `PATCH` | `/admin/tickets/:id/status` | `AdminController.updateAdminTicketStatus` | JWT (ADMIN) |
| 100 | `GET` | `/admin/topbar-search` | `AdminController.searchTopbar` | JWT (ADMIN) |
| 101 | `GET` | `/admin/transactions` | `AdminController.listAdminTransactions` | JWT (ADMIN) |
| 102 | `GET` | `/admin/transactions/analytics` | `AdminController.transactionsAnalytics` | JWT (ADMIN) |
| 103 | `POST` | `/admin/transactions/renew` | `AdminController.renewVehicles` | JWT (ADMIN) |
| 104 | `GET` | `/admin/unlinkusers/:vehicleId` | `AdminController.getUnlinkedUsers` | JWT (ADMIN) |
| 105 | `POST` | `/admin/unlinkusers/:vehicleId` | `AdminController.unlinkUsers` | JWT (ADMIN) |
| 106 | `GET` | `/admin/unlinkvehicles/:userId` | `AdminController.getUnlinkedVehicles` | JWT (ADMIN) |
| 107 | `POST` | `/admin/unlinkvehicles/:userId` | `AdminController.unlinkVehicles` | JWT (ADMIN) |
| 108 | `PATCH` | `/admin/updatepassword` | `AdminController.patchPasswordAdmin` | JWT (ADMIN) |
| 109 | `POST` | `/admin/updatepassword` | `AdminController.updatePasswordAdmin` | JWT (ADMIN) |
| 110 | `POST` | `/admin/updateuserpassword/:id` | `AdminController.updatePassword` | JWT (ADMIN) |
| 111 | `POST` | `/admin/upload` | `AdminController.uploadFile` | JWT (ADMIN) |
| 112 | `POST` | `/admin/uploaddoc` | `AdminController.uploadDocument` | JWT (ADMIN) |
| 113 | `DELETE` | `/admin/uploaddoc/:id` | `AdminController.deleteDocument` | JWT (ADMIN) |
| 114 | `PATCH` | `/admin/uploaddoc/:id` | `AdminController.updateDocument` | JWT (ADMIN) |
| 115 | `POST` | `/admin/userbulkjobs` | `AdminController.createUserBulkJob` | JWT (ADMIN) |
| 116 | `GET` | `/admin/userbulkjobs/:id` | `AdminController.getUserBulkJob` | JWT (ADMIN) |
| 117 | `GET` | `/admin/userbulkjobs/:id/failed.csv` | `AdminController.downloadUserFailedCsv` | JWT (ADMIN) |
| 118 | `GET` | `/admin/userbulkjobs/:id/stream` | `AdminController.streamUserBulkJob` | JWT (ADMIN) |
| 119 | `GET` | `/admin/userlogin/:id` | `AdminController.adminLogin` | JWT (ADMIN) |
| 120 | `GET` | `/admin/users` | `AdminController.getUsers` | JWT (ADMIN) |
| 121 | `POST` | `/admin/users` | `AdminController.createUser` | JWT (ADMIN) |
| 122 | `DELETE` | `/admin/users/:id` | `AdminController.deleteUser` | JWT (ADMIN) |
| 123 | `GET` | `/admin/users/:id` | `AdminController.getUserById` | JWT (ADMIN) |
| 124 | `PATCH` | `/admin/users/:id` | `AdminController.updateUser` | JWT (ADMIN) |
| 125 | `GET` | `/admin/users/:id/activitylogs` | `AdminController.getUserActivityLogs` | JWT (ADMIN) |
| 126 | `GET` | `/admin/users/linkeddrivers/:userId` | `AdminController.getLinkedDriversForUser` | JWT (ADMIN) |
| 127 | `POST` | `/admin/users/linkeddrivers/:userId` | `AdminController.linkDriversToUser` | JWT (ADMIN) |
| 128 | `GET` | `/admin/users/unlinkeddrivers/:userId` | `AdminController.getUnlinkedDriversForUser` | JWT (ADMIN) |
| 129 | `POST` | `/admin/users/unlinkeddrivers/:userId` | `AdminController.unlinkDriversFromUser` | JWT (ADMIN) |
| 130 | `POST` | `/admin/vehiclebulkjobs` | `AdminController.createVehicleBulkJob` | JWT (ADMIN) |
| 131 | `GET` | `/admin/vehiclebulkjobs/:id` | `AdminController.getVehicleBulkJob` | JWT (ADMIN) |
| 132 | `GET` | `/admin/vehiclebulkjobs/:id/failed.csv` | `AdminController.downloadFailedCsv` | JWT (ADMIN) |
| 133 | `GET` | `/admin/vehiclebulkjobs/:id/stream` | `AdminController.streamVehicleBulkJob` | JWT (ADMIN) |
| 134 | `GET` | `/admin/vehicles` | `AdminController.getVehicles` | JWT (ADMIN) |
| 135 | `POST` | `/admin/vehicles` | `AdminController.createVehicle` | JWT (ADMIN) |
| 136 | `DELETE` | `/admin/vehicles/:id` | `AdminController.deleteVehicle` | JWT (ADMIN) |
| 137 | `GET` | `/admin/vehicles/:id` | `AdminController.getVehicleById` | JWT (ADMIN) |
| 138 | `PATCH` | `/admin/vehicles/:id` | `AdminController.updateVehicle` | JWT (ADMIN) |
| 139 | `PATCH` | `/admin/vehicles/:id/config` | `AdminController.updateVehicleConfig` | JWT (ADMIN) |
| 140 | `GET` | `/admin/vehicles/:vehicleId/sensors` | `AdminController.listVehicleSensors` | JWT (ADMIN) |
| 141 | `POST` | `/admin/vehicles/:vehicleId/sensors` | `AdminController.createVehicleSensor` | JWT (ADMIN) |
| 142 | `DELETE` | `/admin/vehicles/:vehicleId/sensors/:sensorId` | `AdminController.deleteVehicleSensor` | JWT (ADMIN) |
| 143 | `PATCH` | `/admin/vehicles/:vehicleId/sensors/:sensorId` | `AdminController.updateVehicleSensor` | JWT (ADMIN) |
| 144 | `POST` | `/admin/vehicles/:vehicleId/sensors/run` | `AdminController.runVehicleSensor` | JWT (ADMIN) |
| 145 | `GET` | `/admin/vehicles/:vehicleId/sensors/telemetry` | `AdminController.getVehicleSensorTelemetry` | JWT (ADMIN) |
| 146 | `GET` | `/admin/vehicles/by-imei/:imei/commands` | `AdminController.getCommandHistoryByImei` | JWT (ADMIN) |
| 147 | `GET` | `/admin/vehicles/by-imei/:imei/details` | `AdminController.getVehicleDetailsByImei` | JWT (ADMIN) |
| 148 | `GET` | `/admin/vehicles/by-imei/:imei/events` | `AdminController.getVehicleEventsByImei` | JWT (ADMIN) |
| 149 | `GET` | `/admin/vehicles/by-imei/:imei/events/export` | `AdminController.exportVehicleEventsCsv` | JWT (ADMIN) |
| 150 | `GET` | `/admin/vehicles/by-imei/:imei/history` | `AdminController.getVehicleHistoryByImei` | JWT (ADMIN) |
| 151 | `GET` | `/admin/vehicles/by-imei/:imei/logs` | `AdminController.getVehicleLogsByImei` | JWT (ADMIN) |
| 152 | `GET` | `/admin/vehicles/by-imei/:imei/logs/export` | `AdminController.exportVehicleLogsCsv` | JWT (ADMIN) |
| 153 | `GET` | `/admin/vehicles/by-imei/:imei/replay` | `AdminController.getVehicleReplayByImei` | JWT (ADMIN) |
| 154 | `POST` | `/admin/vehicles/by-imei/:imei/send-command` | `AdminController.sendDeviceCommandByImei` | JWT (ADMIN) |
| 155 | `GET` | `/admin/vehicles/by-imei/:imei/sensors` | `AdminController.getVehicleSensorsByImei` | JWT (ADMIN) |
| 156 | `GET` | `/admin/vehicles/by-imei/:imei/trail` | `AdminController.getVehicleTrailByImei` | JWT (ADMIN) |
| 157 | `GET` | `/admin/whitelabel` | `AdminController.getWhiteLabelSettings` | JWT (ADMIN) |
| 158 | `PATCH` | `/admin/whitelabel` | `AdminController.updateWhiteLabelSettings` | JWT (ADMIN) |
| 159 | `GET` | `/admin/whitelabel/inspect` | `AdminController.inspectWhiteLabelBranding` | JWT (ADMIN) |
| 160 | `POST` | `/agent/commands` | `AgentController.createCommand` | JWT (SUPERADMIN, ADMIN, USER, SUBUSER) |
| 161 | `GET` | `/agent/executions/:executionId` | `AgentController.getExecution` | JWT (SUPERADMIN, ADMIN, USER, SUBUSER) |
| 162 | `GET` | `/agent/executions/:executionId/status` | `AgentController.getExecutionStatus` | JWT (SUPERADMIN, ADMIN, USER, SUBUSER) |
| 163 | `GET` | `/auth/checksadmin` | `AuthController.getChecksAdmin` | Public |
| 164 | `POST` | `/auth/createsuperadmin` | `AuthController.createSuperAdmin` | Public |
| 165 | `POST` | `/auth/email-test` | `AuthController.testEmail` | JWT |
| 166 | `GET` | `/auth/fcm-web-config` | `AuthController.getFcmWebConfig` | Public |
| 167 | `POST` | `/auth/forgot-password` | `AuthController.forgotPassword` | Public |
| 168 | `GET` | `/auth/google/client-id` | `AuthController.getGoogleClientId` | Public |
| 169 | `POST` | `/auth/google/login` | `AuthController.googleLogin` | Public |
| 170 | `POST` | `/auth/login` | `AuthController.login` | Public |
| 488 | `POST` | `/auth/refresh-token` | `AuthController.refreshToken` | Public |
| 171 | `POST` | `/auth/push-test` | `AuthController.testPush` | JWT |
| 172 | `DELETE` | `/auth/push-token` | `AuthController.removePushToken` | JWT |
| 173 | `POST` | `/auth/push-token` | `AuthController.registerPushToken` | JWT |
| 174 | `GET` | `/auth/push-tokens/me` | `AuthController.getMyPushTokens` | JWT |
| 175 | `POST` | `/auth/reset-password` | `AuthController.resetPassword` | Public |
| 176 | `GET` | `/branding` | `AppController.getBranding` | Public |
| 177 | `POST` | `/bug-reports` | `BugReportController.create` | JWT |
| 178 | `GET` | `/cities/:countryCode/:stateCode` | `AppController.getCities` | Public |
| 179 | `GET` | `/countries` | `AppController.getCountries` | Public |
| 180 | `GET` | `/currencies` | `AppController.getCurrencies` | Public |
| 181 | `GET` | `/dateformats` | `AppController.getDateFormats` | Public |
| 182 | `GET` | `/devicestypes` | `AppController.getDeviceTypes` | Public |
| 183 | `GET` | `/documenttypes/:documentType` | `AppController.getDocumentTypes` | Public |
| 184 | `GET` | `/geocoding/precision` | `GeocodingController.precision` | JWT (SUPERADMIN, ADMIN, USER, SUBUSER, TEAM, DRIVER) |
| 185 | `GET` | `/geocoding/reverse` | `GeocodingController.reverse` | JWT (SUPERADMIN, ADMIN, USER, SUBUSER, TEAM, DRIVER) |
| 186 | `POST` | `/geocoding/reverse/bulk` | `GeocodingController.reverseBulk` | JWT (SUPERADMIN, ADMIN, USER, SUBUSER, TEAM, DRIVER) |
| 187 | `POST` | `/handledata` | `HandledataController.handleData` | Public |
| 188 | `GET` | `/health` | `HealthController.getHealth` | Public |
| 189 | `GET` | `/health/address-db` | `HealthController.getAddressDbHealth` | Public |
| 190 | `GET` | `/health/databases` | `HealthController.getDatabasesHealth` | Public |
| 191 | `GET` | `/health/logs-db` | `HealthController.getLogsDbHealth` | Public |
| 192 | `GET` | `/health/primary-db` | `HealthController.getPrimaryDbHealth` | Public |
| 193 | `GET` | `/health/telemetry-diagnostics/:imei` | `HealthController.getTelemetryDiagnostics` | Public |
| 194 | `GET` | `/health/telemetry-packet/:imei/:sourcePacketId` | `HealthController.getTelemetryPacket` | Public |
| 195 | `GET` | `/health/telemetry-stats` | `HealthController.getTelemetryStats` | Public |
| 196 | `GET` | `/health/telemetry-stats/:imei` | `HealthController.getImeiTelemetryStats` | Public |
| 197 | `GET` | `/languages` | `AppController.getLanguages` | Public |
| 198 | `GET` | `/mobileprefix` | `AppController.getMobileCode` | Public |
| 199 | `GET` | `/policies` | `AppController.getPolicies` | Public |
| 200 | `GET` | `/policies/:type` | `AppController.getPolicyByType` | Public |
| 201 | `GET` | `/public/track/:code` | `PublicTrackController.getLinkMeta` | Public |
| 202 | `GET` | `/public/track/:code/geofences` | `PublicTrackController.getGeofences` | Public |
| 203 | `GET` | `/public/track/:code/telemetry` | `PublicTrackController.getMapTelemetry` | Public |
| 204 | `GET` | `/public/track/:code/vehicles/:imei/details` | `PublicTrackController.getVehicleDetailsByImei` | Public |
| 205 | `GET` | `/public/track/:code/vehicles/:imei/history` | `PublicTrackController.getVehicleHistoryByImei` | Public |
| 206 | `GET` | `/public/track/:code/vehicles/:imei/logs` | `PublicTrackController.getVehicleLogsByImei` | Public |
| 207 | `GET` | `/public/track/:code/vehicles/:imei/replay` | `PublicTrackController.getVehicleReplayByImei` | Public |
| 208 | `GET` | `/simproviders` | `AppController.getSimProviders` | Public |
| 209 | `GET` | `/states/:countryCode` | `AppController.getStates` | Public |
| 210 | `GET` | `/status` | `AppController.getStatus` | Public |
| 211 | `POST` | `/superadmin/activateadmin/:id` | `SuperadminController.activateAdmin` | JWT (SUPERADMIN) |
| 212 | `GET` | `/superadmin/admin/:id` | `SuperadminController.getAdminById` | JWT (SUPERADMIN) |
| 213 | `GET` | `/superadmin/admin/:id/activitylogs` | `SuperadminController.getAdminActivityLogs` | JWT (SUPERADMIN) |
| 214 | `GET` | `/superadmin/adminlist` | `SuperadminController.getAdminList` | JWT (SUPERADMIN) |
| 215 | `GET` | `/superadmin/adminlogin/:id` | `SuperadminController.adminLogin` | JWT (SUPERADMIN) |
| 216 | `POST` | `/superadmin/adminpasswordupdate` | `SuperadminController.updateAdminPassword` | JWT (SUPERADMIN) |
| 217 | `GET` | `/superadmin/adminvehicles/:adminId` | `SuperadminController.getAdminVehiclesList` | JWT (SUPERADMIN) |
| 218 | `GET` | `/superadmin/appnotifytemplates` | `SuperadminController.getAppNotifyTemplates` | JWT (SUPERADMIN) |
| 219 | `GET` | `/superadmin/appnotifytemplates/:id` | `SuperadminController.getAppNotifyTemplateById` | JWT (SUPERADMIN) |
| 220 | `PATCH` | `/superadmin/appnotifytemplates/:id` | `SuperadminController.updateAppNotifyTemplate` | JWT (SUPERADMIN) |
| 221 | `POST` | `/superadmin/assigncredits/:id` | `SuperadminController.assignCredits` | JWT (SUPERADMIN) |
| 222 | `GET` | `/superadmin/calendar/day` | `SuperadminController.getCalendarDayDetails` | JWT (SUPERADMIN) |
| 223 | `GET` | `/superadmin/calendar/events` | `SuperadminController.getCalendarEvents` | JWT (SUPERADMIN) |
| 224 | `GET` | `/superadmin/calendar/user/:uid` | `SuperadminController.getCalendarUserDetails` | JWT (SUPERADMIN) |
| 225 | `GET` | `/superadmin/commands/:cmdId` | `SuperadminController.getCommandLogByCmdId` | JWT (SUPERADMIN) |
| 226 | `GET` | `/superadmin/commands/status/:cmdId` | `SuperadminController.getCommandStatus` | JWT (SUPERADMIN) |
| 227 | `GET` | `/superadmin/commandtypes` | `SuperadminController.getCommandTypes` | JWT (SUPERADMIN) |
| 228 | `POST` | `/superadmin/commandtypes` | `SuperadminController.createCommandType` | JWT (SUPERADMIN) |
| 229 | `DELETE` | `/superadmin/commandtypes/:id` | `SuperadminController.deleteCommandType` | JWT (SUPERADMIN) |
| 230 | `PATCH` | `/superadmin/commandtypes/:id` | `SuperadminController.updateCommandType` | JWT (SUPERADMIN) |
| 231 | `GET` | `/superadmin/companyconfig/:id` | `SuperadminController.getCompanyConfig` | JWT (SUPERADMIN) |
| 232 | `PATCH` | `/superadmin/companyconfig/:id` | `SuperadminController.updateCompanyConfig` | JWT (SUPERADMIN) |
| 233 | `PATCH` | `/superadmin/companydetails` | `SuperadminController.updateCompanyDetails` | JWT (SUPERADMIN) |
| 234 | `POST` | `/superadmin/createadmin` | `SuperadminController.createAdmin` | JWT (SUPERADMIN) |
| 235 | `GET` | `/superadmin/creditlogs/:id` | `SuperadminController.getCreditLogs` | JWT (SUPERADMIN) |
| 236 | `GET` | `/superadmin/customcommands` | `SuperadminController.getCustomCommands` | JWT (SUPERADMIN) |
| 237 | `POST` | `/superadmin/customcommands` | `SuperadminController.createCustomCommand` | JWT (SUPERADMIN) |
| 238 | `DELETE` | `/superadmin/customcommands/:id` | `SuperadminController.deleteCustomCommand` | JWT (SUPERADMIN) |
| 239 | `PATCH` | `/superadmin/customcommands/:id` | `SuperadminController.updateCustomCommand` | JWT (SUPERADMIN) |
| 240 | `GET` | `/superadmin/dashboard/activitylogs` | `SuperadminController.getDashboardActivityLogs` | JWT (SUPERADMIN) |
| 241 | `GET` | `/superadmin/dashboard/adoptiongraph` | `SuperadminController.getAdoptionGraph` | JWT (SUPERADMIN) |
| 242 | `GET` | `/superadmin/dashboard/overview` | `SuperadminController.getDashboardOverview` | JWT (SUPERADMIN) |
| 243 | `GET` | `/superadmin/dashboard/recentusers` | `SuperadminController.getRecentUsers` | JWT (SUPERADMIN) |
| 244 | `GET` | `/superadmin/dashboard/recentvehicles` | `SuperadminController.getRecentVehicles` | JWT (SUPERADMIN) |
| 245 | `GET` | `/superadmin/dashboard/totalcounts` | `SuperadminController.getTotalCounts` | JWT (SUPERADMIN) |
| 246 | `DELETE` | `/superadmin/deleteadmin/:id` | `SuperadminController.deleteAdmin` | JWT (SUPERADMIN) |
| 247 | `POST` | `/superadmin/devices/:imei/send-command` | `SuperadminController.sendDeviceCommand` | JWT (SUPERADMIN) |
| 248 | `GET` | `/superadmin/devicetypes` | `SuperadminController.getDeviceTypes` | JWT (SUPERADMIN) |
| 249 | `POST` | `/superadmin/devicetypes` | `SuperadminController.createDeviceType` | JWT (SUPERADMIN) |
| 250 | `DELETE` | `/superadmin/devicetypes/:id` | `SuperadminController.deleteDeviceType` | JWT (SUPERADMIN) |
| 251 | `PATCH` | `/superadmin/devicetypes/:id` | `SuperadminController.updateDeviceType` | JWT (SUPERADMIN) |
| 252 | `GET` | `/superadmin/documents/:adminId` | `SuperadminController.getDocuments` | JWT (SUPERADMIN) |
| 253 | `GET` | `/superadmin/documenttypes` | `SuperadminController.getDocumentTypes` | JWT (SUPERADMIN) |
| 254 | `POST` | `/superadmin/documenttypes` | `SuperadminController.createDocumentType` | JWT (SUPERADMIN) |
| 255 | `DELETE` | `/superadmin/documenttypes/:id` | `SuperadminController.deleteDocumentType` | JWT (SUPERADMIN) |
| 256 | `PATCH` | `/superadmin/documenttypes/:id` | `SuperadminController.updateDocumentType` | JWT (SUPERADMIN) |
| 257 | `GET` | `/superadmin/domainlist` | `SuperadminController.getDomainList` | JWT (SUPERADMIN) |
| 258 | `GET` | `/superadmin/emailtemplates` | `SuperadminController.getEmailTemplates` | JWT (SUPERADMIN) |
| 259 | `GET` | `/superadmin/emailtemplates/:id` | `SuperadminController.getEmailTemplateById` | JWT (SUPERADMIN) |
| 260 | `PATCH` | `/superadmin/emailtemplates/:id` | `SuperadminController.updateEmailTemplate` | JWT (SUPERADMIN) |
| 261 | `POST` | `/superadmin/ftkey/deactivate` | `SuperadminController.deactivateFtkey` | JWT (SUPERADMIN) |
| 262 | `POST` | `/superadmin/ftkey/recheck` | `SuperadminController.recheckFtkey` | JWT (SUPERADMIN) |
| 263 | `GET` | `/superadmin/ftkey/status` | `SuperadminController.getFtkeyStatus` | JWT (SUPERADMIN) |
| 264 | `POST` | `/superadmin/ftkey/validate` | `SuperadminController.validateFtkey` | JWT (SUPERADMIN) |
| 265 | `GET` | `/superadmin/geofences` | `SuperadminController.getAllGeofences` | JWT (SUPERADMIN) |
| 266 | `GET` | `/superadmin/integrations` | `SuperadminController.listIntegrations` | JWT (SUPERADMIN) |
| 267 | `POST` | `/superadmin/integrations` | `SuperadminController.upsertIntegration` | JWT (SUPERADMIN) |
| 268 | `DELETE` | `/superadmin/integrations/:id` | `SuperadminController.deleteIntegration` | JWT (SUPERADMIN) |
| 269 | `PATCH` | `/superadmin/integrations/:id` | `SuperadminController.updateIntegration` | JWT (SUPERADMIN) |
| 270 | `GET` | `/superadmin/integrations/:id/openrouter/models` | `SuperadminController.getOpenRouterModels` | JWT (SUPERADMIN) |
| 271 | `POST` | `/superadmin/integrations/:id/rotate-secret` | `SuperadminController.rotateIntegrationSecret` | JWT (SUPERADMIN) |
| 272 | `POST` | `/superadmin/integrations/:id/test-fcm` | `SuperadminController.testFcmIntegration` | JWT (SUPERADMIN) |
| 273 | `POST` | `/superadmin/integrations/:id/test-openrouter` | `SuperadminController.testOpenRouterIntegration` | JWT (SUPERADMIN) |
| 274 | `POST` | `/superadmin/integrations/:id/test-whatsapp` | `SuperadminController.testWhatsAppIntegration` | JWT (SUPERADMIN) |
| 275 | `POST` | `/superadmin/integrations/:id/validate-geocoding` | `SuperadminController.validateGeocodingIntegration` | JWT (SUPERADMIN) |
| 276 | `POST` | `/superadmin/integrations/:id/validate-google-sso` | `SuperadminController.validateGoogleSsoIntegration` | JWT (SUPERADMIN) |
| 277 | `GET` | `/superadmin/localization` | `SuperadminController.getLocalizationData` | JWT (SUPERADMIN) |
| 278 | `PATCH` | `/superadmin/localization` | `SuperadminController.updateLocalizationData` | JWT (SUPERADMIN) |
| 279 | `GET` | `/superadmin/map-events` | `SuperadminController.getMapEvents` | JWT (SUPERADMIN) |
| 280 | `GET` | `/superadmin/map-telemetry` | `SuperadminController.getMapTelemetry` | JWT (SUPERADMIN) |
| 281 | `GET` | `/superadmin/notifications` | `SuperadminController.getNotifications` | JWT (SUPERADMIN) |
| 282 | `PATCH` | `/superadmin/notifications/:id/read` | `SuperadminController.markNotificationRead` | JWT (SUPERADMIN) |
| 283 | `PATCH` | `/superadmin/notifications/read-all` | `SuperadminController.markAllNotificationsRead` | JWT (SUPERADMIN) |
| 284 | `POST` | `/superadmin/notifications/test-fcm-me` | `SuperadminController.testFcmToMe` | JWT (SUPERADMIN) |
| 285 | `GET` | `/superadmin/openrouter/models` | `SuperadminController.listOpenRouterModels` | JWT (SUPERADMIN) |
| 286 | `GET` | `/superadmin/pois` | `SuperadminController.getAllPois` | JWT (SUPERADMIN) |
| 287 | `PATCH` | `/superadmin/policy` | `SuperadminController.updatePolicy` | JWT (SUPERADMIN) |
| 288 | `POST` | `/superadmin/policy` | `SuperadminController.createPolicy` | JWT (SUPERADMIN) |
| 289 | `GET` | `/superadmin/profile` | `SuperadminController.getProfile` | JWT (SUPERADMIN) |
| 290 | `PATCH` | `/superadmin/profile` | `SuperadminController.updateProfile` | JWT (SUPERADMIN) |
| 291 | `GET` | `/superadmin/profile/email-subscription` | `SuperadminController.getEmailSubscription` | JWT (SUPERADMIN) |
| 292 | `POST` | `/superadmin/profile/email-subscription/subscribe` | `SuperadminController.subscribeEmail` | JWT (SUPERADMIN) |
| 293 | `POST` | `/superadmin/profile/verify/email/confirm` | `SuperadminController.verifyEmailOtp` | JWT (SUPERADMIN) |
| 294 | `POST` | `/superadmin/profile/verify/email/request` | `SuperadminController.requestEmailOtp` | JWT (SUPERADMIN) |
| 295 | `POST` | `/superadmin/profile/verify/whatsapp/confirm` | `SuperadminController.verifyWhatsAppOtp` | JWT (SUPERADMIN) |
| 296 | `POST` | `/superadmin/profile/verify/whatsapp/request` | `SuperadminController.requestWhatsAppOtp` | JWT (SUPERADMIN) |
| 297 | `GET` | `/superadmin/routes` | `SuperadminController.getAllRoutes` | JWT (SUPERADMIN) |
| 298 | `POST` | `/superadmin/server/actions` | `ServerController.createServerActionJob` | JWT (SUPERADMIN) |
| 299 | `GET` | `/superadmin/server/jobs/:id` | `ServerController.getServerActionJob` | JWT (SUPERADMIN) |
| 300 | `GET` | `/superadmin/server/jobs/:id/stream` | `ServerController.streamServerActionJob` | JWT (SUPERADMIN) |
| 301 | `GET` | `/superadmin/server/overview` | `ServerController.getOverview` | JWT (SUPERADMIN) |
| 302 | `GET` | `/superadmin/settings/:id` | `SuperadminController.getSettings` | JWT (SUPERADMIN) |
| 303 | `PATCH` | `/superadmin/settings/:id` | `SuperadminController.updateSettings` | JWT (SUPERADMIN) |
| 304 | `GET` | `/superadmin/settings/data-retention/preview` | `SuperadminController.previewDataRetention` | JWT (SUPERADMIN) |
| 305 | `POST` | `/superadmin/settings/data-retention/run` | `SuperadminController.runDataRetention` | JWT (SUPERADMIN) |
| 306 | `GET` | `/superadmin/simproviders` | `SuperadminController.getSimProviders` | JWT (SUPERADMIN) |
| 307 | `POST` | `/superadmin/simproviders` | `SuperadminController.createSimProvider` | JWT (SUPERADMIN) |
| 308 | `DELETE` | `/superadmin/simproviders/:id` | `SuperadminController.deleteSimProvider` | JWT (SUPERADMIN) |
| 309 | `PATCH` | `/superadmin/simproviders/:id` | `SuperadminController.updateSimProvider` | JWT (SUPERADMIN) |
| 310 | `GET` | `/superadmin/smtpconfig/:id` | `SuperadminController.getSmtpConfig` | JWT (SUPERADMIN) |
| 311 | `PATCH` | `/superadmin/smtpconfig/:id` | `SuperadminController.updateSmtpConfig` | JWT (SUPERADMIN) |
| 312 | `GET` | `/superadmin/smtpsettings` | `SuperadminController.getSmtpSettings` | JWT (SUPERADMIN) |
| 313 | `PATCH` | `/superadmin/smtpsettings` | `SuperadminController.updateSmtpSettings` | JWT (SUPERADMIN) |
| 314 | `GET` | `/superadmin/softwareconfig` | `SuperadminController.getConfig` | JWT (SUPERADMIN) |
| 315 | `PATCH` | `/superadmin/softwareconfig` | `SuperadminController.updateConfig` | JWT (SUPERADMIN) |
| 316 | `POST` | `/superadmin/ssl/install` | `SslController.install` | JWT (SUPERADMIN) |
| 317 | `GET` | `/superadmin/ssl/jobs/:jobId` | `SslController.getJob` | JWT (SUPERADMIN) |
| 318 | `GET` | `/superadmin/ssl/jobs/:jobId/stream` | `SslStreamController.streamJob` | Public |
| 319 | `GET` | `/superadmin/ssl/status` | `SslController.getStatus` | JWT (SUPERADMIN) |
| 320 | `GET` | `/superadmin/support/tickets` | `SuperadminController.listSupportTickets` | JWT (SUPERADMIN) |
| 321 | `POST` | `/superadmin/support/tickets` | `SuperadminController.createSupportTicketOnBehalfOfAdmin` | JWT (SUPERADMIN) |
| 322 | `GET` | `/superadmin/support/tickets/:id` | `SuperadminController.getSupportTicketById` | JWT (SUPERADMIN) |
| 323 | `POST` | `/superadmin/support/tickets/:id/messages` | `SuperadminController.replySupportTicket` | JWT (SUPERADMIN) |
| 324 | `PATCH` | `/superadmin/support/tickets/:id/status` | `SuperadminController.updateSupportTicketStatus` | JWT (SUPERADMIN) |
| 325 | `GET` | `/superadmin/systemvariables` | `SuperadminController.getSystemVariables` | JWT (SUPERADMIN) |
| 326 | `POST` | `/superadmin/systemvariables` | `SuperadminController.createSystemVariable` | JWT (SUPERADMIN) |
| 327 | `DELETE` | `/superadmin/systemvariables/:id` | `SuperadminController.deleteSystemVariable` | JWT (SUPERADMIN) |
| 328 | `PATCH` | `/superadmin/systemvariables/:id` | `SuperadminController.updateSystemVariable` | JWT (SUPERADMIN) |
| 329 | `GET` | `/superadmin/telemetry` | `SuperadminController.getTelemetrySnapshot` | JWT (SUPERADMIN) |
| 330 | `POST` | `/superadmin/testsmtp` | `SuperadminController.testSmtpSettings` | JWT (SUPERADMIN) |
| 331 | `GET` | `/superadmin/topbar-search` | `SuperadminController.searchTopbar` | JWT (SUPERADMIN) |
| 332 | `GET` | `/superadmin/transactions` | `SuperadminController.listTransactions` | JWT (SUPERADMIN) |
| 333 | `GET` | `/superadmin/transactions/analytics` | `SuperadminController.transactionsAnalytics` | JWT (SUPERADMIN) |
| 334 | `POST` | `/superadmin/transactions/manual` | `SuperadminController.recordManualTransaction` | JWT (SUPERADMIN) |
| 335 | `POST` | `/superadmin/updateadmin/:id` | `SuperadminController.updateAdmin` | JWT (SUPERADMIN) |
| 336 | `PATCH` | `/superadmin/updatepassword` | `SuperadminController.updatePassword` | JWT (SUPERADMIN) |
| 337 | `POST` | `/superadmin/upload/:id` | `SuperadminController.upload` | JWT (SUPERADMIN) |
| 338 | `POST` | `/superadmin/uploaddoc` | `SuperadminController.uploadDocument` | JWT (SUPERADMIN) |
| 339 | `DELETE` | `/superadmin/uploaddoc/:id` | `SuperadminController.deleteDocument` | JWT (SUPERADMIN) |
| 340 | `PATCH` | `/superadmin/uploaddoc/:id` | `SuperadminController.uploadDocumentUpdate` | JWT (SUPERADMIN) |
| 341 | `GET` | `/superadmin/vehicles` | `SuperadminController.getAllVehicles` | JWT (SUPERADMIN) |
| 342 | `GET` | `/superadmin/vehicles/:id` | `SuperadminController.getVehicleById` | JWT (SUPERADMIN) |
| 343 | `GET` | `/superadmin/vehicles/by-imei/:imei/commands` | `SuperadminController.getCommandHistoryByImei` | JWT (SUPERADMIN) |
| 344 | `GET` | `/superadmin/vehicles/by-imei/:imei/details` | `SuperadminController.getVehicleDetailsByImei` | JWT (SUPERADMIN) |
| 345 | `GET` | `/superadmin/vehicles/by-imei/:imei/events` | `SuperadminController.getVehicleEventsByImei` | JWT (SUPERADMIN) |
| 346 | `GET` | `/superadmin/vehicles/by-imei/:imei/history` | `SuperadminController.getVehicleHistoryByImei` | JWT (SUPERADMIN) |
| 347 | `GET` | `/superadmin/vehicles/by-imei/:imei/logs` | `SuperadminController.getVehicleLogsByImei` | JWT (SUPERADMIN) |
| 348 | `GET` | `/superadmin/vehicles/by-imei/:imei/replay` | `SuperadminController.getVehicleReplayByImei` | JWT (SUPERADMIN) |
| 349 | `POST` | `/superadmin/vehicles/by-imei/:imei/send-command` | `SuperadminController.sendDeviceCommandByImei` | JWT (SUPERADMIN) |
| 350 | `GET` | `/superadmin/vehicles/by-imei/:imei/sensors` | `SuperadminController.getVehicleSensorsByImei` | JWT (SUPERADMIN) |
| 351 | `GET` | `/superadmin/vehicles/by-imei/:imei/trail` | `SuperadminController.getVehicleTrailByImei` | JWT (SUPERADMIN) |
| 352 | `GET` | `/superadmin/vehicletypes` | `SuperadminController.getVehicleTypes` | JWT (SUPERADMIN) |
| 353 | `POST` | `/superadmin/vehicletypes` | `SuperadminController.createVehicleType` | JWT (SUPERADMIN) |
| 354 | `DELETE` | `/superadmin/vehicletypes/:id` | `SuperadminController.deleteVehicleType` | JWT (SUPERADMIN) |
| 355 | `PATCH` | `/superadmin/vehicletypes/:id` | `SuperadminController.updateVehicleType` | JWT (SUPERADMIN) |
| 356 | `GET` | `/superadmin/whatsapptemplates` | `WhatsAppTemplatesController.list` | JWT (SUPERADMIN) |
| 357 | `GET` | `/superadmin/whatsapptemplates/:id` | `WhatsAppTemplatesController.getOne` | JWT (SUPERADMIN) |
| 358 | `PATCH` | `/superadmin/whatsapptemplates/:id` | `WhatsAppTemplatesController.update` | JWT (SUPERADMIN) |
| 359 | `GET` | `/superadmin/whatsapptemplates/meta` | `WhatsAppTemplatesController.fetchMeta` | JWT (SUPERADMIN) |
| 360 | `POST` | `/superadmin/whatsapptemplates/sync` | `WhatsAppTemplatesController.sync` | JWT (SUPERADMIN) |
| 361 | `GET` | `/superadmin/whitelabel` | `SuperadminController.getWhiteLabelSettings` | JWT (SUPERADMIN) |
| 362 | `PATCH` | `/superadmin/whitelabel` | `SuperadminController.updateWhiteLabelSettings` | JWT (SUPERADMIN) |
| 363 | `GET` | `/superadmin/whitelabel/inspect` | `SuperadminController.inspectWhiteLabelBranding` | JWT (SUPERADMIN) |
| 364 | `GET` | `/timezones` | `AppController.getTimezones` | Public |
| 365 | `GET` | `/unsubscribe` | `AppController.unsubscribe` | Public |
| 366 | `GET` | `/user/commands/:cmdId` | `UserController.getCommandLogByCmdId` | JWT (ADMIN, USER) |
| 367 | `POST` | `/user/commands/send-bulk` | `UserController.sendCommandBulk` | JWT (ADMIN, USER) |
| 368 | `GET` | `/user/commands/status/:cmdId` | `UserController.getCommandStatus` | JWT (ADMIN, USER) |
| 369 | `PATCH` | `/user/companydetails` | `UserController.updateOwnCompanyDetails` | JWT (ADMIN, USER) |
| 370 | `GET` | `/user/customcommands` | `UserController.getUserCustomCommands` | JWT (ADMIN, USER) |
| 371 | `GET` | `/user/dashboard/day-night-comparison` | `UserController.getDayNightComparison` | JWT (ADMIN, USER) |
| 372 | `GET` | `/user/dashboard/fleet-status` | `UserController.getUserFleetStatus` | JWT (ADMIN, USER) |
| 373 | `GET` | `/user/dashboard/recent-alerts` | `UserController.getDashboardRecentAlerts` | JWT (ADMIN, USER) |
| 374 | `GET` | `/user/dashboard/recent-alerts/:id` | `UserController.getDashboardRecentAlertDetail` | JWT (ADMIN, USER) |
| 375 | `PATCH` | `/user/dashboard/recent-alerts/:id/read` | `UserController.markDashboardRecentAlertRead` | JWT (ADMIN, USER) |
| 376 | `GET` | `/user/dashboard/top-performing-assets` | `UserController.topPerformingAssets` | JWT (ADMIN, USER) |
| 377 | `GET` | `/user/dashboard/usage-last-7-days` | `UserController.getUsageLast7Days` | JWT (ADMIN, USER) |
| 378 | `GET` | `/user/dashboard/weekly-comparison` | `UserController.weeklyComparison` | JWT (ADMIN, USER) |
| 379 | `GET` | `/user/dashboards` | `UserController.listDashboards` | JWT (ADMIN, USER) |
| 380 | `POST` | `/user/dashboards` | `UserController.createDashboard` | JWT (ADMIN, USER) |
| 381 | `DELETE` | `/user/dashboards/:id` | `UserController.deleteDashboard` | JWT (ADMIN, USER) |
| 382 | `GET` | `/user/dashboards/:id` | `UserController.getDashboard` | JWT (ADMIN, USER) |
| 383 | `PUT` | `/user/dashboards/:id` | `UserController.updateDashboard` | JWT (ADMIN, USER) |
| 384 | `GET` | `/user/drivers` | `UserController.getDrivers` | JWT (ADMIN, USER) |
| 385 | `POST` | `/user/drivers` | `UserController.createDriver` | JWT (ADMIN, USER) |
| 386 | `DELETE` | `/user/drivers/:id` | `UserController.deleteDriver` | JWT (ADMIN, USER) |
| 387 | `GET` | `/user/drivers/:id` | `UserController.getDriverById` | JWT (ADMIN, USER) |
| 388 | `PATCH` | `/user/drivers/:id` | `UserController.updateDriver` | JWT (ADMIN, USER) |
| 389 | `POST` | `/user/drivers/:id/assign-vehicle` | `UserController.assignDriverToVehicle` | JWT (ADMIN, USER) |
| 390 | `GET` | `/user/drivers/:id/documents` | `UserController.getDriverDocuments` | JWT (ADMIN, USER) |
| 391 | `POST` | `/user/drivers/:id/documents` | `UserController.uploadDriverDocument` | JWT (ADMIN, USER) |
| 392 | `DELETE` | `/user/drivers/:id/documents/:docId` | `UserController.deleteDriverDocument` | JWT (ADMIN, USER) |
| 393 | `PATCH` | `/user/drivers/:id/documents/:docId` | `UserController.updateDriverDocument` | JWT (ADMIN, USER) |
| 394 | `GET` | `/user/drivers/:id/logs` | `UserController.getDriverLogs` | JWT (ADMIN, USER) |
| 395 | `POST` | `/user/drivers/:id/unassign-vehicle` | `UserController.unassignDriverFromVehicle` | JWT (ADMIN, USER) |
| 396 | `GET` | `/user/geofences` | `UserController.listGeofences` | JWT (ADMIN, USER) |
| 397 | `POST` | `/user/geofences` | `UserController.createGeofence` | JWT (ADMIN, USER) |
| 398 | `DELETE` | `/user/geofences/:id` | `UserController.deleteGeofence` | JWT (ADMIN, USER) |
| 399 | `GET` | `/user/geofences/:id` | `UserController.getGeofenceById` | JWT (ADMIN, USER) |
| 400 | `PATCH` | `/user/geofences/:id` | `UserController.updateGeofence` | JWT (ADMIN, USER) |
| 401 | `POST` | `/user/landmarkbulkjobs` | `UserController.createLandmarkBulkJob` | JWT (ADMIN, USER) |
| 402 | `GET` | `/user/landmarkbulkjobs/:id` | `UserController.getLandmarkBulkJob` | JWT (ADMIN, USER) |
| 403 | `GET` | `/user/landmarkbulkjobs/:id/failed.csv` | `UserController.downloadLandmarkFailedCsv` | JWT (ADMIN, USER) |
| 404 | `GET` | `/user/landmarkbulkjobs/:id/stream` | `UserController.streamLandmarkBulkJob` | JWT (ADMIN, USER) |
| 405 | `GET` | `/user/localization` | `UserController.getLocalizationData` | JWT (ADMIN, USER) |
| 406 | `PATCH` | `/user/localization` | `UserController.updateLocalizationData` | JWT (ADMIN, USER) |
| 407 | `GET` | `/user/map-events` | `UserController.getMapEvents` | JWT (ADMIN, USER) |
| 408 | `GET` | `/user/map-telemetry` | `UserController.getMapTelemetry` | JWT (ADMIN, USER) |
| 409 | `GET` | `/user/notification-settings` | `UserController.getNotificationSettings` | JWT (ADMIN, USER) |
| 410 | `PUT` | `/user/notification-settings` | `UserController.updateNotificationSettings` | JWT (ADMIN, USER) |
| 411 | `GET` | `/user/notifications` | `UserController.getUserNotifications` | JWT (USER) |
| 412 | `PATCH` | `/user/notifications/:id/read` | `UserController.markUserNotificationRead` | JWT (USER) |
| 413 | `GET` | `/user/notifications/preferences` | `UserController.getNotificationPreferences` | JWT (ADMIN, USER) |
| 414 | `PUT` | `/user/notifications/preferences` | `UserController.updateNotificationPreferences` | JWT (ADMIN, USER) |
| 415 | `PATCH` | `/user/notifications/read-all` | `UserController.markAllUserNotificationsRead` | JWT (USER) |
| 416 | `POST` | `/user/notifications/test-fcm-me` | `UserController.testFcmToMe` | JWT (ADMIN, USER) |
| 417 | `GET` | `/user/notifications/vehicle` | `UserController.getVehicleNotificationsForTopbar` | JWT (USER) |
| 418 | `PATCH` | `/user/notifications/vehicle/:id/read` | `UserController.markVehicleNotificationReadForTopbar` | JWT (USER) |
| 419 | `PATCH` | `/user/notifications/vehicle/read-all` | `UserController.markAllVehicleNotificationsReadForTopbar` | JWT (USER) |
| 420 | `GET` | `/user/pois` | `UserController.listPois` | JWT (ADMIN, USER) |
| 421 | `POST` | `/user/pois` | `UserController.createPoi` | JWT (ADMIN, USER) |
| 422 | `DELETE` | `/user/pois/:id` | `UserController.deletePoi` | JWT (ADMIN, USER) |
| 423 | `GET` | `/user/pois/:id` | `UserController.getPoiById` | JWT (ADMIN, USER) |
| 424 | `PATCH` | `/user/pois/:id` | `UserController.updatePoi` | JWT (ADMIN, USER) |
| 425 | `GET` | `/user/profile` | `UserController.getProfile` | JWT (ADMIN, USER) |
| 426 | `PATCH` | `/user/profile` | `UserController.updateProfile` | JWT (ADMIN, USER) |
| 427 | `GET` | `/user/profile/email-subscription` | `UserController.getEmailSubscription` | JWT (ADMIN, USER) |
| 428 | `POST` | `/user/profile/email-subscription/subscribe` | `UserController.subscribeEmail` | JWT (ADMIN, USER) |
| 429 | `POST` | `/user/profile/verify/email/confirm` | `UserController.verifyEmailOtp` | JWT (ADMIN, USER) |
| 430 | `POST` | `/user/profile/verify/email/request` | `UserController.requestEmailOtp` | JWT (ADMIN, USER) |
| 431 | `POST` | `/user/profile/verify/whatsapp/confirm` | `UserController.verifyWhatsAppOtp` | JWT (ADMIN, USER) |
| 432 | `POST` | `/user/profile/verify/whatsapp/request` | `UserController.requestWhatsAppOtp` | JWT (ADMIN, USER) |
| 433 | `GET` | `/user/routes` | `UserController.listRoutes` | JWT (ADMIN, USER) |
| 434 | `POST` | `/user/routes` | `UserController.createRoute` | JWT (ADMIN, USER) |
| 435 | `DELETE` | `/user/routes/:id` | `UserController.deleteRoute` | JWT (ADMIN, USER) |
| 436 | `GET` | `/user/routes/:id` | `UserController.getRouteById` | JWT (ADMIN, USER) |
| 437 | `PATCH` | `/user/routes/:id` | `UserController.updateRoute` | JWT (ADMIN, USER) |
| 438 | `GET` | `/user/sharetracklinks` | `UserController.listShareTrackLinks` | JWT (ADMIN, USER) |
| 439 | `POST` | `/user/sharetracklinks` | `UserController.createShareTrackLink` | JWT (ADMIN, USER) |
| 440 | `DELETE` | `/user/sharetracklinks/:id` | `UserController.deleteShareTrackLink` | JWT (ADMIN, USER) |
| 441 | `GET` | `/user/sharetracklinks/:id` | `UserController.getShareTrackLinkById` | JWT (ADMIN, USER) |
| 442 | `PATCH` | `/user/sharetracklinks/:id` | `UserController.updateShareTrackLink` | JWT (ADMIN, USER) |
| 443 | `GET` | `/user/subusers` | `UserController.listSubUsers` | JWT (ADMIN, USER) |
| 444 | `POST` | `/user/subusers` | `UserController.createSubUser` | JWT (ADMIN, USER) |
| 445 | `DELETE` | `/user/subusers/:id` | `UserController.deleteSubUser` | JWT (ADMIN, USER) |
| 446 | `GET` | `/user/subusers/:id` | `UserController.getSubUserById` | JWT (ADMIN, USER) |
| 447 | `PATCH` | `/user/subusers/:id` | `UserController.updateSubUser` | JWT (ADMIN, USER) |
| 448 | `GET` | `/user/subusers/:id/vehicles` | `UserController.getSubUserVehicles` | JWT (ADMIN, USER) |
| 449 | `POST` | `/user/subusers/:id/vehicles/assign` | `UserController.assignSubUserVehicles` | JWT (ADMIN, USER) |
| 450 | `POST` | `/user/subusers/:id/vehicles/unassign` | `UserController.unassignSubUserVehicles` | JWT (ADMIN, USER) |
| 451 | `GET` | `/user/systemvariables` | `UserController.getUserSystemVariables` | JWT (ADMIN, USER) |
| 452 | `GET` | `/user/tickets` | `UserController.listTickets` | JWT (ADMIN, USER) |
| 453 | `POST` | `/user/tickets` | `UserController.createTicket` | JWT (ADMIN, USER) |
| 454 | `GET` | `/user/tickets/:id` | `UserController.getTicketConversation` | JWT (ADMIN, USER) |
| 455 | `POST` | `/user/tickets/:id` | `UserController.addTicketMessage` | JWT (ADMIN, USER) |
| 456 | `GET` | `/user/topbar-search` | `UserController.searchTopbar` | JWT (USER) |
| 457 | `GET` | `/user/transactions` | `UserController.listUserTransactions` | JWT (ADMIN, USER) |
| 458 | `PATCH` | `/user/updatepassword` | `UserController.updatePassword` | JWT (ADMIN, USER) |
| 459 | `POST` | `/user/upload` | `UserController.uploadProfile` | JWT (ADMIN, USER) |
| 460 | `GET` | `/user/vehicles` | `UserController.getUserVehicles` | JWT (ADMIN, USER) |
| 461 | `GET` | `/user/vehicles/:id` | `UserController.getVehicleById` | JWT (ADMIN, USER) |
| 462 | `PATCH` | `/user/vehicles/:id` | `UserController.updateVehicleById` | JWT (ADMIN, USER) |
| 463 | `PATCH` | `/user/vehicles/:id/config` | `UserController.updateVehicleConfig` | JWT (ADMIN, USER) |
| 464 | `GET` | `/user/vehicles/:id/documents` | `UserController.getVehicleDocuments` | JWT (ADMIN, USER) |
| 465 | `POST` | `/user/vehicles/:id/documents` | `UserController.uploadVehicleDocument` | JWT (ADMIN, USER) |
| 466 | `DELETE` | `/user/vehicles/:id/documents/:docId` | `UserController.deleteVehicleDocument` | JWT (ADMIN, USER) |
| 467 | `PATCH` | `/user/vehicles/:id/documents/:docId` | `UserController.updateVehicleDocument` | JWT (ADMIN, USER) |
| 468 | `GET` | `/user/vehicles/:vehicleId/commands` | `UserController.getCommandHistoryByVehicleId` | JWT (ADMIN, USER) |
| 469 | `GET` | `/user/vehicles/:vehicleId/sensors` | `UserController.listVehicleSensors` | JWT (ADMIN, USER) |
| 470 | `POST` | `/user/vehicles/:vehicleId/sensors` | `UserController.createVehicleSensor` | JWT (ADMIN, USER) |
| 471 | `DELETE` | `/user/vehicles/:vehicleId/sensors/:sensorId` | `UserController.deleteVehicleSensor` | JWT (ADMIN, USER) |
| 472 | `PATCH` | `/user/vehicles/:vehicleId/sensors/:sensorId` | `UserController.updateVehicleSensor` | JWT (ADMIN, USER) |
| 473 | `GET` | `/user/vehicles/:vehicleId/sensors/:sensorId/history` | `UserController.getSensorHistory` | JWT (ADMIN, USER) |
| 474 | `POST` | `/user/vehicles/:vehicleId/sensors/run` | `UserController.runVehicleSensor` | JWT (ADMIN, USER) |
| 475 | `GET` | `/user/vehicles/:vehicleId/sensors/telemetry` | `UserController.getVehicleSensorTelemetry` | JWT (ADMIN, USER) |
| 476 | `GET` | `/user/vehicles/:vehicleId/telemetry` | `UserController.getVehicleTelemetrySnapshot` | JWT (ADMIN, USER) |
| 477 | `GET` | `/user/vehicles/by-imei/:imei/details` | `UserController.getVehicleDetailsByImei` | JWT (ADMIN, USER) |
| 478 | `GET` | `/user/vehicles/by-imei/:imei/events` | `UserController.getVehicleEventsByImei` | JWT (ADMIN, USER) |
| 479 | `GET` | `/user/vehicles/by-imei/:imei/history` | `UserController.getVehicleHistoryByImei` | JWT (ADMIN, USER) |
| 480 | `GET` | `/user/vehicles/by-imei/:imei/logs` | `UserController.getVehicleLogsByIMEI` | JWT (ADMIN, USER) |
| 481 | `GET` | `/user/vehicles/by-imei/:imei/replay` | `UserController.getVehicleReplayByImei` | JWT (ADMIN, USER) |
| 482 | `GET` | `/user/vehicles/by-imei/:imei/sensors` | `UserController.getVehicleSensorsByImei` | JWT (ADMIN, USER) |
| 483 | `GET` | `/user/vehicles/by-imei/:imei/trail` | `UserController.getVehicleTrailByImei` | JWT (ADMIN, USER) |
| 484 | `GET` | `/vehicletypes` | `AppController.getVehicleTypes` | Public |
| 485 | `GET` | `/version` | `AppController.getVersion` | Public |
| 486 | `GET` | `/webhooks/whatsapp` | `WhatsappWebhookController.verify` | Public |
| 487 | `POST` | `/webhooks/whatsapp` | `WhatsappWebhookController.inbound` | Public |

---

## Socket.IO / real-time channels

### Connection auth

Socket gateways accept the same JWT used by HTTP APIs. Token can be supplied through `client.handshake.auth.token`, `Authorization: Bearer <token>` header, or `?token=<token>` depending on gateway implementation.

### `(service/no namespace)` — `src/realtime/device-status-realtime.service.ts`

- **Server/client emits found:** `devicestatus:update`
- **Rooms/patterns detected:** `imei:${imei}`

### `(service/no namespace)` — `src/realtime/notification-realtime.service.ts`

- **Server/client emits found:** `notif:new`
- **Rooms/patterns detected:** `imei:${imei}`

### `/notifications` — `src/realtime/notification.gateway.ts`

- **Namespace:** `/notifications`
- **Client → server events:** `notif:subscribe`
- **Server/client emits found:** `notif:error`, `notif:subscribed`
- **Rooms/patterns detected:** `imei:${imei}`, `role:${role}`

### `(service/no namespace)` — `src/realtime/telemetry-realtime.service.ts`

- **Server/client emits found:** `telemetry:update`
- **Rooms/patterns detected:** `imei:${imei}`

### `/telemetry` — `src/realtime/telemetry.gateway.ts`

- **Namespace:** `/telemetry`
- **Client → server events:** `telemetry:subscribe`
- **Server/client emits found:** `telemetry:error`, `telemetry:snapshot`
- **Rooms/patterns detected:** `imei:${imei}`, `role:${role}`

### Real-time event details

| Namespace/source | Event | Direction | Payload | Notes |
|---|---|---|---|---|
| `/telemetry` | `telemetry:subscribe` | client → server | `{ scope?: "superadmin"; imeis?: string[]; publicTrackCode?: string }` | Joins `scope:superadmin` or `imei:<imei>` rooms after authorization; public-track clients are constrained by link code. |
| `/telemetry` | `telemetry:snapshot` | server → client | `TelemetryRecord[]` | Emitted immediately after successful subscription. Records include normalized `serverTimeMs` and `course`. |
| `/telemetry` | `telemetry:update` | server → client | `TelemetryRecord` | Emitted by `TelemetryRealtimeService` to `imei:<imei>` and `scope:superadmin`. |
| `/telemetry` | `telemetry:error` | server → client | `{ message: string }` | Invalid/unauthorized subscription or subscription failure. |
| `/notifications` | `notif:subscribe` | client → server | `{ scope?: "superadmin"; imeis?: string[] }` | Joins `scope:superadmin` and/or authorized `imei:<imei>` rooms. Unauthorized IMEIs are not echoed back. |
| `/notifications` | `notif:subscribed` | server → client | `{ ok: true, scope?: string, imeis: string[], denied: { scope: number, imeis: number } }` | Subscription acknowledgement. |
| `/notifications` | `notif:new` | server → client | notification payload | Emitted by `NotificationRealtimeService` to `scope:superadmin` and `imei:<imei>`. |
| `/notifications` | `devicestatus:update` | server → client | parsed device status payload | Emitted by `DeviceStatusRealtimeService` to `imei:<imei>` and `scope:superadmin`. |
| `/notifications` | `notif:error` | server → client | `{ message: string }` | Invalid/unauthorized subscription or subscription failure. |

### Server-Sent Event / raw streaming HTTP endpoints

| Method | Endpoint | Source | Events/notes |
|---|---|---|---|
| `GET` | `/admin/driverbulkjobs/:id/stream` | `src/admin/admin.controller.ts` | stream/raw response |
| `GET` | `/admin/inventorybulkjobs/:id/stream` | `src/admin/admin.controller.ts` | stream/raw response |
| `GET` | `/admin/userbulkjobs/:id/stream` | `src/admin/admin.controller.ts` | stream/raw response |
| `GET` | `/admin/vehiclebulkjobs/:id/stream` | `src/admin/admin.controller.ts` | stream/raw response |
| `GET` | `/superadmin/server/jobs/:id/stream` | `src/superadmin/server/server.controller.ts` | stream/raw response |
| `GET` | `/superadmin/ssl/jobs/:jobId/stream` | `src/ssl/ssl.controller.ts` | stream/raw response |
| `GET` | `/user/landmarkbulkjobs/:id/stream` | `src/user/user.controller.ts` | stream/raw response |

---

## Complete endpoint reference

## `root` endpoints

### 1. `GET /`

- **Controller:** `AppController.getHello()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Controller return type:** `string`
- **Return expression/source:** `this.appService.getHello()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `admin` endpoints

### 2. `GET /admin/calendar/day`

- **Controller:** `AdminController.getCalendarDayDetails()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCalendarDayDetails(headerId, dto.date, dto.types)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `AdminCalendarDayDto` | Yes | `@Query() dto: AdminCalendarDayDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 3. `GET /admin/calendar/events`

- **Controller:** `AdminController.getCalendarEvents()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCalendarEvents(headerId, dto.from, dto.to, dto.types)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `AdminCalendarRangeDto` | Yes | `@Query() dto: AdminCalendarRangeDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 4. `GET /admin/calendar/user/:uid`

- **Controller:** `AdminController.getCalendarUserDetails()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCalendarUserDetails(headerId, uid)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `uid` | `number` | Yes | `@Param('uid', ParseIntPipe) uid: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 5. `GET /admin/commands/:cmdId`

- **Controller:** `AdminController.getCommandLogByCmdId()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCommandLogByCmdId(adminId, cmdId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `cmdId` | `string` | Yes | `@Param('cmdId') cmdId: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() adminId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 6. `GET /admin/commands/status/:cmdId`

- **Controller:** `AdminController.getCommandStatus()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCommandStatus(cmdId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `cmdId` | `string` | Yes | `@Param('cmdId') cmdId: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 7. `PATCH /admin/companydetails`

- **Controller:** `AdminController.updateOwnCompanyDetails()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateCompanyConfig(headerId, companyConfig)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CompanyDto` — raw: `@Body() companyConfig: CompanyDto`

`CompanyDto` from `src/admin/dto/company.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 8. `GET /admin/companydetails/:id`

- **Controller:** `AdminController.getCompanyDetails()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCompanyDetails(headerId, id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 9. `PATCH /admin/companydetails/:id`

- **Controller:** `AdminController.updateCompanyDetails()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateCompanyConfig(id, companyConfig)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `CompanyDto` — raw: `@Body() companyConfig: CompanyDto`

`CompanyDto` from `src/admin/dto/company.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 10. `PATCH /admin/companyinfo/:id`

- **Controller:** `AdminController.updateCompanyInfo()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateCompanyInfo(id, headerId, updateCompanydto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateCompanyDto` — raw: `@Body() updateCompanydto: UpdateCompanyDto`

`UpdateCompanyDto` from `src/admin/dto/updatecompany.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |
| `secondaryColor` | `string` | No | @IsOptional(), @IsString() |
| `navbarColor` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 11. `GET /admin/config`

- **Controller:** `AdminController.getAdminConfig()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getAdminConfig(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 12. `PATCH /admin/config`

- **Controller:** `AdminController.patchAdminConfig()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateAdminConfig(headerId, configDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `AdminConfigDto` — raw: `@Body() configDto: AdminConfigDto`

`AdminConfigDto` from `src/admin/dto/adminconfig.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `allowSignup` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `signupCredits` | `number` | No | @IsOptional(), @IsInt(), @Min(0) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 13. `GET /admin/customcommands`

- **Controller:** `AdminController.getCustomCommands()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Return expression/source:** `this.adminService.getAdminCustomCommands(query)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `CustomCommandsQueryDto` | Yes | `@Query() query: CustomCommandsQueryDto` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 14. `GET /admin/dashboard/summary`

- **Controller:** `AdminController.getDashboardSummary()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDashboardSummary(headerId, dto)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `AdminDashboardSummaryDto` | Yes | `@Query() dto: AdminDashboardSummaryDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 15. `POST /admin/deviceandsim`

- **Controller:** `AdminController.createDeviceAndSim()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createDeviceAndSim(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `DeviceAndSimDto` — raw: `@Body() dto: DeviceAndSimDto`

`DeviceAndSimDto` from `src/admin/dto/deviceandsim.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `imei` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(5, 20), @Matches(/^\d+$/, { message: "imei must contain digits only" }) |
| `deviceTypeId` | `number` | Yes | @ToInt(), @IsInt(), @Min(1) |
| `simNumber` | `string` | Yes | @ToStringish(), @IsString(), @IsNotEmpty() |
| `imsi` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `providerId` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `iccid` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 16. `GET /admin/devices`

- **Controller:** `AdminController.getDevices()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDevices(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 17. `POST /admin/devices`

- **Controller:** `AdminController.createDevice()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createDevice(headerId, createDeviceDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateDeviceDto` — raw: `@Body() createDeviceDto: CreateDeviceDto`

`CreateDeviceDto` from `src/admin/dto/createdevice.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `imei` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(5, 20), @Matches(/^\d+$/, { message: "imei must contain digits only" }) |
| `deviceTypeId` | `number` | Yes | @Transform(({ value }) => {, @IsInt(), @Min(1) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 18. `DELETE /admin/devices/:id`

- **Controller:** `AdminController.deleteDevice()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteDevice(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 19. `PATCH /admin/devices/:id`

- **Controller:** `AdminController.updateDevice()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateDevice(id, headerId, updateDeviceDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateDeviceDto` — raw: `@Body() updateDeviceDto: UpdateDeviceDto`

`UpdateDeviceDto` from `src/admin/dto/updatedevice.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `simId` | `number \| null` | No | @IsOptional(), @IsInt(), @Min(0) |
| `deviceTypeId` | `number \| null` | No | @IsOptional(), @IsInt(), @Min(1) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `message` | `"status must be one of: IN_STOCK, IN_USE, IN_SCRAP",` | No | @IsOptional(), @IsEnum(DeviceInventoryStatusDto, { |
| `status` | `DeviceInventoryStatusDto` | No |  |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 20. `GET /admin/documents/:userId`

- **Controller:** `AdminController.getDocuments()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDocuments(userId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 21. `GET /admin/documents/driver/:driverId`

- **Controller:** `AdminController.getDriverDocuments()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDriverDocuments(driverId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `driverId` | `number` | Yes | `@Param('driverId', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 22. `GET /admin/documents/vehicle/:vehicleId`

- **Controller:** `AdminController.getVehicleDocuments()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleDocuments(vehicleId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 23. `POST /admin/driverbulkjobs`

- **Controller:** `AdminController.createDriverBulkJob()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Bulk job created', data: created }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateDriverBulkJobDto` — raw: `@Body() dto: CreateDriverBulkJobDto`

`CreateDriverBulkJobDto` — see `src/admin/dto/driverbulkjobs.dto.ts` (no simple public fields detected).

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 24. `GET /admin/driverbulkjobs/:id`

- **Controller:** `AdminController.getDriverBulkJob()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: false, message: 'Job not found' } \| { action: true, message: 'Job fetched', data: job }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 25. `GET /admin/driverbulkjobs/:id/failed.csv`

- **Controller:** `AdminController.downloadDriverFailedCsv()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 26. `GET /admin/driverbulkjobs/:id/stream`

- **Controller:** `AdminController.streamDriverBulkJob()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 27. `GET /admin/drivers`

- **Controller:** `AdminController.getDrivers()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDrivers(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 28. `POST /admin/drivers`

- **Controller:** `AdminController.createDriver()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createDriver(headerId, CreateDriverDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateDriverDto` — raw: `@Body() CreateDriverDto: CreateDriverDto`

`CreateDriverDto` from `src/admin/dto/createdriver.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MaxLength(120) |
| `mobilePrefix` | `string` | Yes | @IsString(), @MaxLength(10) |
| `mobile` | `string` | Yes | @IsString(), @MaxLength(20) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `primaryUserid` | `string \| number` | Yes | @IsString() |
| `username` | `string` | Yes | @IsString(), @MaxLength(50) |
| `password` | `string` | Yes | @IsString(), @MaxLength(100) |
| `countryCode` | `string` | Yes | @IsString(), @MaxLength(5) |
| `stateCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `city` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `address` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(20) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 29. `DELETE /admin/drivers/:id`

- **Controller:** `AdminController.deleteDriver()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteDriver(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 30. `GET /admin/drivers/:id`

- **Controller:** `AdminController.getDriverById()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDriverById(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 31. `PATCH /admin/drivers/:id`

- **Controller:** `AdminController.updateDriver()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateDriver(id, headerId, UpdateDriverDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateDriverDto` — raw: `@Body() UpdateDriverDto: UpdateDriverDto`

`UpdateDriverDto` from `src/admin/dto/updatedriver.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `mobile` | `string` | No | @IsOptional(), @IsString(), @MaxLength(20) |
| `email` | `string` | No | @IsOptional(), @IsEmail(), @MaxLength(254) |
| `username` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `password` | `string` | No | @IsOptional(), @IsString(), @MaxLength(100) |
| `countryCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(5) |
| `StateCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `city` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `address` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(12) |
| `isactive` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `attributes` | `Record<string, any> \| string` | No | @IsOptional() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 32. `GET /admin/drivers/:id/users`

- **Controller:** `AdminController.getDriverUsers()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getDriverUsers(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 33. `GET /admin/drivers/linkedusers/:driverId`

- **Controller:** `AdminController.getLinkedUsersForDriver()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getLinkedUsersForDriver(driverId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `driverId` | `number` | Yes | `@Param('driverId', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 34. `POST /admin/drivers/linkedusers/:driverId`

- **Controller:** `AdminController.linkUsersToDriver()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.linkDriverToUser(driverId, userId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `driverId` | `number` | Yes | `@Param('driverId', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `userId`: `number` — raw: `@Body('userId', ParseIntPipe) userId: number`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 35. `GET /admin/drivers/unlinkedusers/:driverId`

- **Controller:** `AdminController.getUnlinkedUsersForDriver()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getUnlinkedUsersForDriver(driverId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `driverId` | `number` | Yes | `@Param('driverId', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 36. `POST /admin/drivers/unlinkedusers/:driverId`

- **Controller:** `AdminController.unlinkUsersFromDriver()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.unlinkDriverFromUser(driverId, userId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `driverId` | `number` | Yes | `@Param('driverId', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `userId`: `number` — raw: `@Body('userId', ParseIntPipe) userId: number`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 37. `POST /admin/inventorybulkjobs`

- **Controller:** `AdminController.createInventoryBulkJob()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Bulk job created', data: created }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateInventoryBulkJobDto` — raw: `@Body() dto: CreateInventoryBulkJobDto`

`CreateInventoryBulkJobDto` from `src/admin/dto/inventorybulkjobs.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `deviceTypeId` | `string` | No | @IsDefined(), @IsString(), @Transform(({ value }) => trim(value)), @IsNotEmpty(), @IsIn(['devices', 'simcards', 'both']), @IsOptional(), @IsString(), @Transform(({ value }) => trim(value)) |
| `providerId` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => trim(value)) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 38. `GET /admin/inventorybulkjobs/:id`

- **Controller:** `AdminController.getInventoryBulkJob()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: false, message: 'Job not found' } \| { action: true, message: 'Job fetched', data: job }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 39. `GET /admin/inventorybulkjobs/:id/failed.csv`

- **Controller:** `AdminController.downloadInventoryFailedCsv()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 40. `GET /admin/inventorybulkjobs/:id/stream`

- **Controller:** `AdminController.streamInventoryBulkJob()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 41. `GET /admin/linkusers/:vehicleId`

- **Controller:** `AdminController.getLinkedUsers()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getLinkedUsers(vehicleId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 42. `POST /admin/linkusers/:vehicleId`

- **Controller:** `AdminController.linkUsers()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.linkVehicleToUser(userId, vehicleId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `userId`: `number` — raw: `@Body('userId', ParseIntPipe) userId: number`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 43. `GET /admin/linkvehicles/:userId`

- **Controller:** `AdminController.getLinkedVehicles()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getLinkedVehicles(userId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 44. `POST /admin/linkvehicles/:userId`

- **Controller:** `AdminController.linkVehicles()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.linkVehicleToUser(userId, vehicleId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `vehicleId`: `number` — raw: `@Body('vehicleId', ParseIntPipe) vehicleId: number`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 45. `GET /admin/localization`

- **Controller:** `AdminController.getLocalizationData()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getLocalizationData(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 46. `PATCH /admin/localization`

- **Controller:** `AdminController.updateLocalizationData()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateLocalizationSettings(headerId, localizationDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateSettingsStateDto` — raw: `@Body() localizationDto: UpdateSettingsStateDto`

`UpdateSettingsStateDto` from `src/superadmin/dto/usersetting.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `language` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_LANGUAGES as unknown as string[], { message: "Invalid language" }) |
| `layoutDirection` | `LayoutDirectionDto` | No | @IsOptional(), @IsEnum(LayoutDirectionDto) |
| `dateFormat` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_DATE_FORMATS as unknown as string[], { message: "Invalid dateFormat" }) |
| `use24Hour` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `theme` | `ThemeModeDto` | No | @IsOptional(), @IsEnum(ThemeModeDto) |
| `timezoneOffset` | `string` | No | @IsOptional(), @IsString(), @IsIn(ALLOWED_TIMEZONE_OFFSETS as unknown as string[], { message: "Invalid timezoneOffset" }) |
| `units` | `UnitsDto` | No | @IsOptional(), @IsEnum(UnitsDto) |
| `defaultLat` | `number` | No | @IsOptional() |
| `defaultLon` | `number` | No | @IsOptional() |
| `mapZoom` | `number` | No | @IsOptional() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 47. `GET /admin/logs/activity`

- **Controller:** `AdminController.getActivityLogs()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getActivityLogs(headerId, dto)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `AdminActivityLogsDto` | Yes | `@Query() dto: AdminActivityLogsDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 48. `GET /admin/logs/events`

- **Controller:** `AdminController.getEventLogs()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getEventLogs(headerId, dto)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `AdminEventLogsDto` | Yes | `@Query() dto: AdminEventLogsDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 49. `GET /admin/logs/events/:id`

- **Controller:** `AdminController.getEventLogById()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getEventLogById(headerId, id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 50. `GET /admin/logs/options`

- **Controller:** `AdminController.getLogsOptions()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getLogsOptions(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 51. `GET /admin/logs/telemetry`

- **Controller:** `AdminController.getTelemetryLogs()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getTelemetryLogs(headerId, dto)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `AdminTelemetryLogsDto` | Yes | `@Query() dto: AdminTelemetryLogsDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 52. `GET /admin/logs/telemetry/:id`

- **Controller:** `AdminController.getTelemetryLogById()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getTelemetryLogById(headerId, id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 53. `GET /admin/map-events`

- **Controller:** `AdminController.getMapEvents()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getMapEvents(headerId, query)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `MapEventsQueryDto` | Yes | `@Query() query: MapEventsQueryDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 54. `GET /admin/map-telemetry`

- **Controller:** `AdminController.getMapTelemetry()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getMapTelemetry(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 55. `GET /admin/mytickets`

- **Controller:** `AdminController.listAdminMyTickets()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.listAdminMyTickets(headerId, { status, search })`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `status` | `string` | No | `@Query('status') status?: string` |
| `search` | `string` | No | `@Query('search') search?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 56. `POST /admin/mytickets`

- **Controller:** `AdminController.createAdminMyTicket()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createAdminMyTicket(headerId, req, body)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `any` — raw: `@Body() body: any`

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 57. `GET /admin/mytickets/:id`

- **Controller:** `AdminController.getAdminMyTicketById()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getAdminMyTicketById(ticketId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 58. `POST /admin/mytickets/:id/messages`

- **Controller:** `AdminController.replyAdminMyTicket()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.replyAdminMyTicket(ticketId, headerId, req, body)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `any` — raw: `@Body() body: any`

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 59. `PATCH /admin/mytickets/:id/status`

- **Controller:** `AdminController.updateAdminMyTicketStatus()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateAdminMyTicketStatus(ticketId, headerId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `AdminUpdateTicketStatusDto` — raw: `@Body() dto: AdminUpdateTicketStatusDto`

`AdminUpdateTicketStatusDto` from `src/admin/dto/admin-update-ticket-status.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `status` | `TicketStatusEnum` | Yes | @IsEnum(TicketStatusEnum) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 60. `GET /admin/notifications`

- **Controller:** `AdminController.getNotifications()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getNotifications(headerId, { limit, beforeId, unreadOnly, category })`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `limit` | `string` | No | `@Query('limit') limit?: string` |
| `beforeId` | `string` | No | `@Query('beforeId') beforeId?: string` |
| `unreadOnly` | `string` | No | `@Query('unreadOnly') unreadOnly?: string` |
| `category` | `string` | No | `@Query('category') category?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 61. `PATCH /admin/notifications/:id/read`

- **Controller:** `AdminController.markNotificationRead()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.markNotificationRead(headerId, id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 62. `PATCH /admin/notifications/read-all`

- **Controller:** `AdminController.markAllNotificationsRead()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.markAllNotificationsRead(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 63. `GET /admin/payments`

- **Controller:** `AdminController.listAdminPayments()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'OK', data }`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `userId` | `string` | No | `@Query('userId') userId?: string` |
| `status` | `string` | No | `@Query('status') status?: string` |
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `q` | `string` | No | `@Query('q') q?: string` |
| `page` | `string` | No | `@Query('page') page?: string` |
| `limit` | `string` | No | `@Query('limit') limit?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 64. `POST /admin/payments/renew`

- **Controller:** `AdminController.renewVehiclesPayment()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Vehicles renewed successfully', data }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `AdminRenewVehiclesDto` — raw: `@Body() dto: AdminRenewVehiclesDto`

`AdminRenewVehiclesDto` from `src/admin/dto/admin-transactions.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `userId` | `number` | Yes | @Type(() => Number), @IsInt(), @Min(1) |
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayMinSize(1), @Type(() => Number), @IsInt({ each: true }) |
| `paymentMode` | `PaymentMode` | No | @IsOptional(), @IsEnum(PaymentMode) |
| `reference` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `amountOverride` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+(\.\d{1,2})?$/, { message: 'amountOverride must be a valid decimal string (e.g., "150.00")' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 65. `GET /admin/pricingplans`

- **Controller:** `AdminController.getPricingPlans()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getPricingPlans(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 66. `POST /admin/pricingplans`

- **Controller:** `AdminController.createPricingPlan()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createPricingPlan(headerId, createPricingPlanDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreatePricingPlanDto` — raw: `@Body() createPricingPlanDto: CreatePricingPlanDto`

`CreatePricingPlanDto` from `src/admin/dto/createpricingplan.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `durationDays` | `number` | Yes | @IsInt(), @Min(1) |
| `price` | `number` | Yes | @IsNumber(), @Min(0) |
| `currency` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(3, 3), @Matches(/^[A-Z]{3}$/, { message: "currency must be a 3-letter ISO code" }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 67. `PATCH /admin/pricingplans/:id`

- **Controller:** `AdminController.updatePricingPlan()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updatePricingPlan(id, headerId, updatePricingPlanDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreatePricingPlanDto` — raw: `@Body() updatePricingPlanDto: CreatePricingPlanDto`

`CreatePricingPlanDto` from `src/admin/dto/createpricingplan.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `durationDays` | `number` | Yes | @IsInt(), @Min(1) |
| `price` | `number` | Yes | @IsNumber(), @Min(0) |
| `currency` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(3, 3), @Matches(/^[A-Z]{3}$/, { message: "currency must be a 3-letter ISO code" }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 68. `GET /admin/profile`

- **Controller:** `AdminController.getProfile()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getProfile(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 69. `PATCH /admin/profile`

- **Controller:** `AdminController.updateProfile()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateProfile(headerId, profileDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `ProfileDto` — raw: `@Body() profileDto: ProfileDto`

`ProfileDto` from `src/superadmin/dto/profile.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `mobileNumber` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `addressLine` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `countryCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `stateCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `cityName` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 70. `GET /admin/profile/email-subscription`

- **Controller:** `AdminController.getEmailSubscription()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, data: { isSubscribed: subscribed, brandOwnerId, scope } }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 71. `POST /admin/profile/email-subscription/subscribe`

- **Controller:** `AdminController.subscribeEmail()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Subscribed', data: { isSubscribed: true } }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 72. `POST /admin/profile/verify/email/confirm`

- **Controller:** `AdminController.verifyEmailOtp()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.verifyEmailOtp(headerId, dto.otp)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `VerifyOtpDto` — raw: `@Body() dto: VerifyOtpDto`

`VerifyOtpDto` from `src/verification/dto/verify-otp.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 73. `POST /admin/profile/verify/email/request`

- **Controller:** `AdminController.requestEmailOtp()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.requestEmailOtp(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 74. `POST /admin/profile/verify/whatsapp/confirm`

- **Controller:** `AdminController.verifyWhatsAppOtp()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.verifyWhatsAppOtp(headerId, dto.otp)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `VerifyOtpDto` — raw: `@Body() dto: VerifyOtpDto`

`VerifyOtpDto` from `src/verification/dto/verify-otp.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 75. `POST /admin/profile/verify/whatsapp/request`

- **Controller:** `AdminController.requestWhatsAppOtp()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.requestWhatsAppOtp(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 76. `GET /admin/quickdevice`

- **Controller:** `AdminController.getQuickDevices()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getQuickDevices(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 77. `POST /admin/quickdevice`

- **Controller:** `AdminController.createQuickDevice()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createQuickDevice(headerId, imei, deviceTypeId, simNumber)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `QuickDeviceDto` — raw: `@Body() quickDeviceDto: QuickDeviceDto`

`QuickDeviceDto` from `src/admin/dto/quickdevice.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `imei` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(4, 20), @Matches(/^\d+$/, { message: "imei must contain digits only" }) |
| `deviceTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `simNumber` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(5, 30), @Matches(/^\d+$/, { message: "simNumber must contain digits only" }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 78. `GET /admin/quicksimcards`

- **Controller:** `AdminController.getQuickSimCards()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getQuickSimCards(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 79. `GET /admin/shortusers`

- **Controller:** `AdminController.getShortUsers()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getShortUsers(headerId, search)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `search` | `string` | No | `@Query('search') search?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 80. `GET /admin/simcards`

- **Controller:** `AdminController.getSimCards()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getSimCards(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 81. `POST /admin/simcards`

- **Controller:** `AdminController.createSimCard()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createSimCard(headerId, CreateSimCardDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `SimCardDto` — raw: `@Body() CreateSimCardDto: SimCardDto`

`SimCardDto` from `src/admin/dto/sim.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `simNumber` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `imsi` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `providerId` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `iccid` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `isActive` | `boolean` | No | @IsOptional() |
| `status` | `'IN_STOCK' \| 'IN_USE' \| 'IN_SCRAP'` | No | @IsOptional(), @ToStringish(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 82. `DELETE /admin/simcards/:id`

- **Controller:** `AdminController.deleteSimCard()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteSimCard(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 83. `GET /admin/simcards/:id`

- **Controller:** `AdminController.getSimCardById()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getSimCardById(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 84. `PATCH /admin/simcards/:id`

- **Controller:** `AdminController.updateSimCard()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateSimCard(id, headerId, UpdateSimCardDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `SimCardDto` — raw: `@Body() UpdateSimCardDto: SimCardDto`

`SimCardDto` from `src/admin/dto/sim.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `simNumber` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `imsi` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `providerId` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `iccid` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `isActive` | `boolean` | No | @IsOptional() |
| `status` | `'IN_STOCK' \| 'IN_USE' \| 'IN_SCRAP'` | No | @IsOptional(), @ToStringish(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 85. `GET /admin/smtpconfig`

- **Controller:** `AdminController.getSmtpConfig()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getSmtpConfig(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 86. `PATCH /admin/smtpconfig`

- **Controller:** `AdminController.patchSmtpConfig()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateSmtpConfig(headerId, smtpConfig)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateSmtpConfigDto` — raw: `@Body() smtpConfig: UpdateSmtpConfigDto`

`UpdateSmtpConfigDto` from `src/admin/dto/updatesmtpconfig.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `senderName` | `string` | No | @IsOptional(), @IsString() |
| `host` | `string` | No | @IsOptional(), @IsString() |
| `port` | `string \| number` | No | @IsOptional(), @IsOptional(), @Matches(/^\d+$/,{message: 'port must be a numeric string or number'}) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `type` | `SmtpSecurity` | No | @IsOptional(), @IsEnum(SmtpSecurity) |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `replyTo` | `string` | No | @IsOptional(), @IsEmail() |
| `isActive` | `string \| boolean` | No | @IsOptional(), @IsOptional(), @Matches(/^(true\|false)$/i, { message: 'isActive must be a boolean string ("true" or "false")' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 87. `POST /admin/smtpconfig`

- **Controller:** `AdminController.updateSmtpConfig()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateSmtpConfig(headerId, smtpConfig)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateSmtpConfigDto` — raw: `@Body() smtpConfig: UpdateSmtpConfigDto`

`UpdateSmtpConfigDto` from `src/admin/dto/updatesmtpconfig.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `senderName` | `string` | No | @IsOptional(), @IsString() |
| `host` | `string` | No | @IsOptional(), @IsString() |
| `port` | `string \| number` | No | @IsOptional(), @IsOptional(), @Matches(/^\d+$/,{message: 'port must be a numeric string or number'}) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `type` | `SmtpSecurity` | No | @IsOptional(), @IsEnum(SmtpSecurity) |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `replyTo` | `string` | No | @IsOptional(), @IsEmail() |
| `isActive` | `string \| boolean` | No | @IsOptional(), @IsOptional(), @Matches(/^(true\|false)$/i, { message: 'isActive must be a boolean string ("true" or "false")' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 88. `GET /admin/systemvariables`

- **Controller:** `AdminController.getSystemVariables()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Return expression/source:** `this.adminService.getAdminSystemVariables()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 89. `GET /admin/teams`

- **Controller:** `AdminController.getTeams()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getTeams(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 90. `POST /admin/teams`

- **Controller:** `AdminController.createTeam()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createTeam(createTeamDto, headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateTeamMemberDto` — raw: `@Body() createTeamDto: CreateTeamMemberDto`

`CreateTeamMemberDto` from `src/admin/dto/createteam.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `email` | `string` | Yes | @IsEmail(), @IsNotEmpty() |
| `mobilePrefix` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `mobileNumber` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `username` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `password` | `string` | Yes | @IsString(), @IsNotEmpty() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 91. `DELETE /admin/teams/:id`

- **Controller:** `AdminController.deleteTeam()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteTeam(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 92. `GET /admin/teams/:id`

- **Controller:** `AdminController.getTeamById()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getTeamById(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 93. `PATCH /admin/teams/:id`

- **Controller:** `AdminController.updateTeam()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateTeam(id, updateTeamDto, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateTeamMemberDto` — raw: `@Body() updateTeamDto: UpdateTeamMemberDto`

`UpdateTeamMemberDto` from `src/admin/dto/updateteam.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString() |
| `mobileNumber` | `string` | No | @IsOptional(), @IsString() |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 94. `POST /admin/testsmtp`

- **Controller:** `AdminController.testSmtpSettings()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.testSmtpSettings(headerId, email)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `email`: `string` — raw: `@Body('email') email: string`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 95. `GET /admin/tickets`

- **Controller:** `AdminController.listAdminTickets()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.listAdminTickets(headerId, { status, search, userId })`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `status` | `string` | No | `@Query('status') status?: string` |
| `search` | `string` | No | `@Query('search') search?: string` |
| `userId` | `string` | No | `@Query('userId') userId?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 96. `POST /admin/tickets`

- **Controller:** `AdminController.createAdminTicket()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createAdminTicket(headerId, req, body)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `any` — raw: `@Body() body: any`

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 97. `GET /admin/tickets/:id`

- **Controller:** `AdminController.getAdminTicketById()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getAdminTicketById(ticketId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 98. `POST /admin/tickets/:id/messages`

- **Controller:** `AdminController.replyAdminTicket()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.replyAdminTicket(ticketId, headerId, req, body)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `any` — raw: `@Body() body: any`

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 99. `PATCH /admin/tickets/:id/status`

- **Controller:** `AdminController.updateAdminTicketStatus()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateAdminTicketStatus(ticketId, headerId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `AdminUpdateTicketStatusDto` — raw: `@Body() dto: AdminUpdateTicketStatusDto`

`AdminUpdateTicketStatusDto` from `src/admin/dto/admin-update-ticket-status.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `status` | `TicketStatusEnum` | Yes | @IsEnum(TicketStatusEnum) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 100. `GET /admin/topbar-search`

- **Controller:** `AdminController.searchTopbar()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.topbarSearch.searchForAdmin(headerId, dto)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `TopbarSearchQueryDto` | Yes | `@Query() dto: TopbarSearchQueryDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 101. `GET /admin/transactions`

- **Controller:** `AdminController.listAdminTransactions()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'OK', data }`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `status` | `string` | No | `@Query('status') status?: string` |
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `q` | `string` | No | `@Query('q') q?: string` |
| `page` | `string` | No | `@Query('page') page?: string` |
| `limit` | `string` | No | `@Query('limit') limit?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 102. `GET /admin/transactions/analytics`

- **Controller:** `AdminController.transactionsAnalytics()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'OK', data }`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `userId` | `string` | No | `@Query('userId') userId?: string` |
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `month` | `string` | No | `@Query('month') month?: string` |
| `year` | `string` | No | `@Query('year') year?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 103. `POST /admin/transactions/renew`

- **Controller:** `AdminController.renewVehicles()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Vehicles renewed successfully', data }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `AdminRenewVehiclesDto` — raw: `@Body() dto: AdminRenewVehiclesDto`

`AdminRenewVehiclesDto` from `src/admin/dto/admin-transactions.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `userId` | `number` | Yes | @Type(() => Number), @IsInt(), @Min(1) |
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayMinSize(1), @Type(() => Number), @IsInt({ each: true }) |
| `paymentMode` | `PaymentMode` | No | @IsOptional(), @IsEnum(PaymentMode) |
| `reference` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `amountOverride` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+(\.\d{1,2})?$/, { message: 'amountOverride must be a valid decimal string (e.g., "150.00")' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 104. `GET /admin/unlinkusers/:vehicleId`

- **Controller:** `AdminController.getUnlinkedUsers()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getUnlinkedUsers(vehicleId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 105. `POST /admin/unlinkusers/:vehicleId`

- **Controller:** `AdminController.unlinkUsers()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.unlinkVehicleFromUser(userId, vehicleId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `userId`: `number` — raw: `@Body('userId', ParseIntPipe) userId: number`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 106. `GET /admin/unlinkvehicles/:userId`

- **Controller:** `AdminController.getUnlinkedVehicles()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getUnlinkedVehicles(userId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 107. `POST /admin/unlinkvehicles/:userId`

- **Controller:** `AdminController.unlinkVehicles()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.unlinkVehicleFromUser(userId, vehicleId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `vehicleId`: `number` — raw: `@Body('vehicleId', ParseIntPipe) vehicleId: number`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 108. `PATCH /admin/updatepassword`

- **Controller:** `AdminController.patchPasswordAdmin()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateAdminPassword(headerId, currentPassword, newPassword)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `{ currentPassword: string, newPassword: string }` — raw: `@Body() body: { currentPassword: string, newPassword: string }`
  - Inline object: `{ currentPassword: string, newPassword: string }`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 109. `POST /admin/updatepassword`

- **Controller:** `AdminController.updatePasswordAdmin()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateAdminPassword(headerId, currentPassword, newPassword)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `{ currentPassword: string, newPassword: string }` — raw: `@Body() body: { currentPassword: string, newPassword: string }`
  - Inline object: `{ currentPassword: string, newPassword: string }`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 110. `POST /admin/updateuserpassword/:id`

- **Controller:** `AdminController.updatePassword()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateuserPassword(id, headerId, newPassword)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `{ newPassword: string }` — raw: `@Body() body: { newPassword: string }`
  - Inline object: `{ newPassword: string }`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 111. `POST /admin/upload`

- **Controller:** `AdminController.uploadFile()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `result \| { action: false, message: error.message \|\| 'Upload failed', data: null }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 112. `POST /admin/uploaddoc`

- **Controller:** `AdminController.uploadDocument()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.uploadDocumentMultipart(req, headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 113. `DELETE /admin/uploaddoc/:id`

- **Controller:** `AdminController.deleteDocument()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.adminService.deleteDocument(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 114. `PATCH /admin/uploaddoc/:id`

- **Controller:** `AdminController.updateDocument()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateDocumentMultipartWithAuth(req, id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 115. `POST /admin/userbulkjobs`

- **Controller:** `AdminController.createUserBulkJob()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Bulk job created', data: created }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateUserBulkJobDto` — raw: `@Body() dto: CreateUserBulkJobDto`

`CreateUserBulkJobDto` — see `src/admin/dto/userbulkjobs.dto.ts` (no simple public fields detected).

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 116. `GET /admin/userbulkjobs/:id`

- **Controller:** `AdminController.getUserBulkJob()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: false, message: 'Job not found' } \| { action: true, message: 'Job fetched', data: job }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 117. `GET /admin/userbulkjobs/:id/failed.csv`

- **Controller:** `AdminController.downloadUserFailedCsv()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 118. `GET /admin/userbulkjobs/:id/stream`

- **Controller:** `AdminController.streamUserBulkJob()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 119. `GET /admin/userlogin/:id`

- **Controller:** `AdminController.adminLogin()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.userLogin(headerId, id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param("id", ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 120. `GET /admin/users`

- **Controller:** `AdminController.getUsers()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getUsers(headerId, search)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `search` | `string` | No | `@Query('search') search?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 121. `POST /admin/users`

- **Controller:** `AdminController.createUser()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createUser(headerId, CreateUserDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateUserDto` — raw: `@Body() CreateUserDto: CreateUserDto`

`CreateUserDto` from `src/admin/dto/createuser.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString() |
| `email` | `string` | No | @IsOptional(), @IsString() |
| `mobilePrefix` | `string` | Yes | @IsString() |
| `mobileNumber` | `string` | Yes | @IsString() |
| `username` | `string` | Yes | @IsString() |
| `password` | `string` | Yes | @IsString() |
| `companyName` | `string` | No | @IsOptional(), @IsString() |
| `address` | `string` | Yes | @IsString() |
| `countryCode` | `string` | Yes | @IsString() |
| `stateCode` | `string` | No | @IsOptional(), @IsString() |
| `city` | `string` | No | @IsOptional(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 122. `DELETE /admin/users/:id`

- **Controller:** `AdminController.deleteUser()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteUser(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 123. `GET /admin/users/:id`

- **Controller:** `AdminController.getUserById()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Return expression/source:** `this.adminService.getUserById(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 124. `PATCH /admin/users/:id`

- **Controller:** `AdminController.updateUser()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateUser(id, UpdateUserDto, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateUserDto` — raw: `@Body() UpdateUserDto: UpdateUserDto`

`UpdateUserDto` from `src/admin/dto/updateuser.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `roleId` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `name` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `email` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `mobilePrefix` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `mobileNumber` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `username` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `password` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `companyName` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `address` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `countryCode` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `stateCode` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `city` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `isActive` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 125. `GET /admin/users/:id/activitylogs`

- **Controller:** `AdminController.getUserActivityLogs()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getUserActivityLogs(headerId, id, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `UserActivityLogsDto` | Yes | `@Query() dto: UserActivityLogsDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 126. `GET /admin/users/linkeddrivers/:userId`

- **Controller:** `AdminController.getLinkedDriversForUser()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getLinkedDriversForUser(userId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 127. `POST /admin/users/linkeddrivers/:userId`

- **Controller:** `AdminController.linkDriversToUser()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.linkDriverToUser(driverId, userId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `driverId`: `number` — raw: `@Body('driverId', ParseIntPipe) driverId: number`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 128. `GET /admin/users/unlinkeddrivers/:userId`

- **Controller:** `AdminController.getUnlinkedDriversForUser()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getUnlinkedDriversForUser(userId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 129. `POST /admin/users/unlinkeddrivers/:userId`

- **Controller:** `AdminController.unlinkDriversFromUser()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.unlinkDriverFromUser(driverId, userId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `userId` | `number` | Yes | `@Param('userId', ParseIntPipe) userId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `driverId`: `number` — raw: `@Body('driverId', ParseIntPipe) driverId: number`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 130. `POST /admin/vehiclebulkjobs`

- **Controller:** `AdminController.createVehicleBulkJob()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Bulk job created', data: created }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateVehicleBulkJobDto` — raw: `@Body() dto: CreateVehicleBulkJobDto`

`CreateVehicleBulkJobDto` — see `src/admin/dto/vehiclebulkjobs.dto.ts` (no simple public fields detected).

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 131. `GET /admin/vehiclebulkjobs/:id`

- **Controller:** `AdminController.getVehicleBulkJob()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: false, message: 'Job not found' } \| { action: true, message: 'Job fetched', data: job }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 132. `GET /admin/vehiclebulkjobs/:id/failed.csv`

- **Controller:** `AdminController.downloadFailedCsv()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 133. `GET /admin/vehiclebulkjobs/:id/stream`

- **Controller:** `AdminController.streamVehicleBulkJob()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 134. `GET /admin/vehicles`

- **Controller:** `AdminController.getVehicles()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.adminService.getVehicles(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 135. `POST /admin/vehicles`

- **Controller:** `AdminController.createVehicle()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createVehicle(headerId, CreateVehicleDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateVehicleDto` — raw: `@Body() CreateVehicleDto: CreateVehicleDto`

`CreateVehicleDto` from `src/admin/dto/createvehicle.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `vin` | `string` | No | @IsDefined(), @IsString(), @Transform(({ value }) => trim(value)), @IsNotEmpty(), @MaxLength(120), @IsOptional(), @IsString(), @Transform(({ value }) => trim(value)), @MaxLength(64) |
| `plateNumber` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => trim(value)), @MaxLength(32) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 136. `DELETE /admin/vehicles/:id`

- **Controller:** `AdminController.deleteVehicle()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteVehicle(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 137. `GET /admin/vehicles/:id`

- **Controller:** `AdminController.getVehicleById()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleById(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 138. `PATCH /admin/vehicles/:id`

- **Controller:** `AdminController.updateVehicle()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateVehicle(id, headerId, UpdateVehicleDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateVehicleDto` — raw: `@Body() UpdateVehicleDto: UpdateVehicleDto`

`UpdateVehicleDto` from `src/admin/dto/updatevehicle.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `vin` | `string` | No | @IsOptional(), @IsString() |
| `plateNumber` | `string` | No | @IsOptional(), @IsString() |
| `deviceid` | `number` | No | @IsOptional(), @ToOptionalInt(), @IsNumber() |
| `vehicleTypeId` | `number` | No | @IsOptional(), @ToOptionalInt(), @IsNumber() |
| `planid` | `number` | No | @IsOptional(), @ToOptionalInt(), @IsNumber() |
| `gmtOffset` | `string` | No | @IsOptional(), @ToTrimmedString(), @Matches(/^[+-](0\d\|1[0-4]):[0-5]\d$/) |
| `isActive` | `boolean` | No | @IsOptional(), @ToOptionalBool(), @IsBoolean() |
| `vehicleMeta` | `Record<string, any>` | No | @IsOptional(), @ToOptionalJSON(), @IsObject() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 139. `PATCH /admin/vehicles/:id/config`

- **Controller:** `AdminController.updateVehicleConfig()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateVehicleConfig(vehicleId, headerId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateVehicleConfigDto` — raw: `@Body() dto: UpdateVehicleConfigDto`

`UpdateVehicleConfigDto` from `src/admin/dto/update-vehicle-config.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `speedVariation` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `distanceVariation` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `odometer` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `engineHours` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `ignitionSource` | `'ACC' \| 'MOTION'` | No | @IsOptional(), @ToOptionalUpper(), @IsIn(['ACC', 'MOTION']) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 140. `GET /admin/vehicles/:vehicleId/sensors`

- **Controller:** `AdminController.listVehicleSensors()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.listVehicleSensors(headerId, vehicleId, { search, page, limit, includeLive: includeLive === 'true', })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `search` | `string` | No | `@Query('search') search?: string` |
| `page` | `string` | No | `@Query('page') page?: string` |
| `limit` | `string` | No | `@Query('limit') limit?: string` |
| `includeLive` | `string` | No | `@Query('includeLive') includeLive?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 141. `POST /admin/vehicles/:vehicleId/sensors`

- **Controller:** `AdminController.createVehicleSensor()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.createVehicleSensor(headerId, vehicleId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateVehicleSensorDto` — raw: `@Body() dto: CreateVehicleSensorDto`

`CreateVehicleSensorDto` from `src/user/dto/sensors/create-vehicle-sensor.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MinLength(2) |
| `unit` | `string` | No | @IsOptional(), @IsString() |
| `icon` | `string` | No | @IsOptional(), @IsString() |
| `code` | `string` | Yes | @IsString(), @MinLength(5) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 142. `DELETE /admin/vehicles/:vehicleId/sensors/:sensorId`

- **Controller:** `AdminController.deleteVehicleSensor()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.deleteVehicleSensor(headerId, vehicleId, sensorId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |
| `sensorId` | `number` | Yes | `@Param('sensorId', ParseIntPipe) sensorId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 143. `PATCH /admin/vehicles/:vehicleId/sensors/:sensorId`

- **Controller:** `AdminController.updateVehicleSensor()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateVehicleSensor(headerId, vehicleId, sensorId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |
| `sensorId` | `number` | Yes | `@Param('sensorId', ParseIntPipe) sensorId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateVehicleSensorDto` — raw: `@Body() dto: UpdateVehicleSensorDto`

`UpdateVehicleSensorDto` from `src/user/dto/sensors/update-vehicle-sensor.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MinLength(2) |
| `unit` | `string` | No | @IsOptional(), @IsString() |
| `icon` | `string` | No | @IsOptional(), @IsString() |
| `code` | `string` | No | @IsOptional(), @IsString(), @MinLength(5) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 144. `POST /admin/vehicles/:vehicleId/sensors/run`

- **Controller:** `AdminController.runVehicleSensor()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.runVehicleSensor(headerId, vehicleId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `RunVehicleSensorDto` — raw: `@Body() dto: RunVehicleSensorDto`

`RunVehicleSensorDto` from `src/user/dto/sensors/run-vehicle-sensor.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `code` | `string` | Yes | @IsString(), @MinLength(5) |
| `payload` | `Record<string, unknown>` | Yes | @IsObject() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 145. `GET /admin/vehicles/:vehicleId/sensors/telemetry`

- **Controller:** `AdminController.getVehicleSensorTelemetry()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleSensorTelemetry(headerId, vehicleId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 146. `GET /admin/vehicles/by-imei/:imei/commands`

- **Controller:** `AdminController.getCommandHistoryByImei()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getCommandHistoryByImei(adminId, imei, { limit, cursorId })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `limit` | `string` | No | `@Query('limit') limit?: string` |
| `cursorId` | `string` | No | `@Query('cursorId') cursorId?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() adminId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 147. `GET /admin/vehicles/by-imei/:imei/details`

- **Controller:** `AdminController.getVehicleDetailsByImei()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleDetailsByImei(headerId, imei)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 148. `GET /admin/vehicles/by-imei/:imei/events`

- **Controller:** `AdminController.getVehicleEventsByImei()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleEventsByImei(headerId!, imei, query)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `MapEventsQueryDto` | Yes | `@Query() query: MapEventsQueryDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId?: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 149. `GET /admin/vehicles/by-imei/:imei/events/export`

- **Controller:** `AdminController.exportVehicleEventsCsv()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `source` | `string` | No | `@Query('source') source?: string` |
| `severity` | `string` | No | `@Query('severity') severity?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId?: number` |

**Request/response objects / upload notes**
- `@Res() reply?: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 150. `GET /admin/vehicles/by-imei/:imei/history`

- **Controller:** `AdminController.getVehicleHistoryByImei()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleHistoryByImei(headerId!, imei, { from, to, stopMin, overspeedKph, maxPoints, })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `stopMin` | `string` | No | `@Query('stopMin') stopMin?: string` |
| `overspeedKph` | `string` | No | `@Query('overspeedKph') overspeedKph?: string` |
| `maxPoints` | `string` | No | `@Query('maxPoints') maxPoints?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId?: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 151. `GET /admin/vehicles/by-imei/:imei/logs`

- **Controller:** `AdminController.getVehicleLogsByImei()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleLogsByImei(headerId!, imei, { from, to, limit, beforeId })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `limit` | `string` | No | `@Query('limit') limit?: string` |
| `beforeId` | `string` | No | `@Query('beforeId') beforeId?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId?: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 152. `GET /admin/vehicles/by-imei/:imei/logs/export`

- **Controller:** `AdminController.exportVehicleLogsCsv()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId?: number` |

**Request/response objects / upload notes**
- `@Res() reply?: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 153. `GET /admin/vehicles/by-imei/:imei/replay`

- **Controller:** `AdminController.getVehicleReplayByImei()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleReplayByImei(headerId!, imei, { from, to, maxPoints })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `maxPoints` | `string` | No | `@Query('maxPoints') maxPoints?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId?: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 154. `POST /admin/vehicles/by-imei/:imei/send-command`

- **Controller:** `AdminController.sendDeviceCommandByImei()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.sendDeviceCommandByImei(headerId, imei, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `SendDeviceCommandDto` — raw: `@Body() dto: SendDeviceCommandDto`

`SendDeviceCommandDto` from `src/superadmin/dto/send-device-command.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `command` | `string` | Yes | @IsString(), @IsNotEmpty(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @MaxLength(500) |
| `note` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 155. `GET /admin/vehicles/by-imei/:imei/sensors`

- **Controller:** `AdminController.getVehicleSensorsByImei()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleSensorsByImei(headerId, imei, { includeTelemetryMeta })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `includeTelemetryMeta` | `string` | No | `@Query('includeTelemetryMeta') includeTelemetryMeta?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 156. `GET /admin/vehicles/by-imei/:imei/trail`

- **Controller:** `AdminController.getVehicleTrailByImei()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getVehicleTrailByImei(headerId!, imei, { hours, from, to, maxPoints })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `hours` | `string` | No | `@Query('hours') hours?: string` |
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `maxPoints` | `string` | No | `@Query('maxPoints') maxPoints?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId?: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 157. `GET /admin/whitelabel`

- **Controller:** `AdminController.getWhiteLabelSettings()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.getWhiteLabelSettings(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 158. `PATCH /admin/whitelabel`

- **Controller:** `AdminController.updateWhiteLabelSettings()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.updateWhiteLabelSettings(req, headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 159. `GET /admin/whitelabel/inspect`

- **Controller:** `AdminController.inspectWhiteLabelBranding()`
- **Source:** `src/admin/admin.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.adminService.inspectWhiteLabelBranding(headerId, host)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `host` | `string` | No | `@Query('host') host?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `agent` endpoints

### 160. `POST /agent/commands`

- **Controller:** `AgentController.createCommand()`
- **Source:** `src/agent/controllers/agent.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER
- **Return expression/source:** `{ action: true, message: 'Command received', data: result }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() userId: number` |

**Body / payload**
- `(body)`: `CreateAgentCommandDto` — raw: `@Body() dto: CreateAgentCommandDto`

`CreateAgentCommandDto` from `src/agent/dto/create-agent-command.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `channel` | `'WEB' \| 'API' \| 'WHATSAPP' \| 'WORKFLOW'` | No | @IsString(), @MaxLength(1000), @IsOptional(), @IsEnum(['WEB', 'API', 'WHATSAPP', 'WORKFLOW']) |
| `payload` | `StructuredCommandPayload` | No | @IsOptional(), @ValidateNested(), @Type(() => StructuredCommandPayload) |
| `metadata` | `Record<string, any>` | No | @IsOptional(), @IsObject() |

**Request/response objects / upload notes**
- `@Req() req: any`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 161. `GET /agent/executions/:executionId`

- **Controller:** `AgentController.getExecution()`
- **Source:** `src/agent/controllers/agent.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER
- **Return expression/source:** `{ action: true, message: 'Execution loaded', data: execution }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `params` | `ExecutionIdParamDto` | Yes | `@Param() params: ExecutionIdParamDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() userId: number` |

**Request/response objects / upload notes**
- `@Req() req: any`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 162. `GET /agent/executions/:executionId/status`

- **Controller:** `AgentController.getExecutionStatus()`
- **Source:** `src/agent/controllers/agent.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER
- **Return expression/source:** `{ action: true, message: 'Status loaded', data: status }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `params` | `ExecutionIdParamDto` | Yes | `@Param() params: ExecutionIdParamDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() userId: number` |

**Request/response objects / upload notes**
- `@Req() req: any`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `auth` endpoints

### 163. `GET /auth/checksadmin`

- **Controller:** `AuthController.getChecksAdmin()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Public
- **Return expression/source:** `this.authService.getChecksAdmin()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 164. `POST /auth/createsuperadmin`

- **Controller:** `AuthController.createSuperAdmin()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.authService.createSuperAdmin(superadminDto)`

**Body / payload**
- `(body)`: `CreateSuperAdminDto` — raw: `@Body() superadminDto: CreateSuperAdminDto`

`CreateSuperAdminDto` from `src/auth/dto/superadmin.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString() |
| `email` | `string` | Yes | @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsString() |
| `mobileNumber` | `string` | Yes | @IsString() |
| `username` | `string` | Yes | @IsString() |
| `password` | `string` | Yes | @IsString(), @MinLength(6) |
| `companyName` | `string` | Yes | @IsString() |
| `website` | `string` | No | @IsOptional(), @IsString() |
| `address` | `string` | Yes | @IsString() |
| `country` | `string` | Yes | @IsString() |
| `state` | `string` | Yes | @IsString() |
| `city` | `string` | Yes | @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 165. `POST /auth/email-test`

- **Controller:** `AuthController.testEmail()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Bearer JWT
- **Return expression/source:** `this.authService.testEmailToMe(userId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() userId: number` |

**Body / payload**
- `(body)`: `TestEmailDto` — raw: `@Body() dto: TestEmailDto`

`TestEmailDto` from `src/auth/dto/email-test.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `subject` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `body` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 166. `GET /auth/fcm-web-config`

- **Controller:** `AuthController.getFcmWebConfig()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Public
- **Return expression/source:** `this.authService.getFcmWebConfig()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 167. `POST /auth/forgot-password`

- **Controller:** `AuthController.forgotPassword()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Public
- **Return expression/source:** `this.authService.forgotPassword(dto.identifier, req)`

**Body / payload**
- `(body)`: `ForgotPasswordDto` — raw: `@Body() dto: ForgotPasswordDto`

`ForgotPasswordDto` from `src/auth/dto/forgot-password.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `identifier` | `string` | Yes | @IsNotEmpty(), @IsString() |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 168. `GET /auth/google/client-id`

- **Controller:** `AuthController.getGoogleClientId()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Public
- **Return expression/source:** `this.authService.getGoogleClientId()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 169. `POST /auth/google/login`

- **Controller:** `AuthController.googleLogin()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<AuthResponseDto>`
- **Return expression/source:** `this.authService.googleLogin(dto.code, req)`

**Body / payload**
- `(body)`: `GoogleLoginDto` — raw: `@Body() dto: GoogleLoginDto`

`GoogleLoginDto` from `src/auth/dto/google-login.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `code` | `string` | Yes | @IsNotEmpty(), @IsString() |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 170. `POST /auth/login`

- **Controller:** `AuthController.login()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<AuthResponseDto>`
- **Return expression/source:** `this.authService.login(loginDto, req)`

**Body / payload**
- `(body)`: `LoginDto` — raw: `@Body() loginDto: LoginDto`

`LoginDto` from `src/auth/dto/login.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `identifier` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `password` | `string` | Yes | @IsNotEmpty(), @IsString() |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 488. `POST /auth/refresh-token`

- **Controller:** `AuthController.refreshToken()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<AuthResponseDto>`
- **Return expression/source:** `this.authService.refreshToken(dto.refresh_token)`

**Body / payload**
- `(body)`: `RefreshTokenDto` — raw: `@Body() dto: RefreshTokenDto`

`RefreshTokenDto` from `src/auth/dto/refresh-token.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `refresh_token` | `string` | Yes | @IsString(), @IsNotEmpty({ message: 'refresh_token must not be empty' }), @Transform(({ value }) => String(value).trim()) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 171. `POST /auth/push-test`

- **Controller:** `AuthController.testPush()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Bearer JWT
- **Return expression/source:** `this.authService.testPushToMe(userId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() userId: number` |

**Body / payload**
- `(body)`: `TestPushDto` — raw: `@Body() dto: TestPushDto`

`TestPushDto` from `src/auth/dto/push-token.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `title` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `body` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 172. `DELETE /auth/push-token`

- **Controller:** `AuthController.removePushToken()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Bearer JWT
- **Return expression/source:** `this.authService.removePushToken(userId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() userId: number` |

**Body / payload**
- `(body)`: `RemovePushTokenDto` — raw: `@Body() dto: RemovePushTokenDto`

`RemovePushTokenDto` from `src/auth/dto/push-token.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `token` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `deviceId` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 173. `POST /auth/push-token`

- **Controller:** `AuthController.registerPushToken()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Bearer JWT
- **Return expression/source:** `this.authService.registerPushToken(userId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() userId: number` |

**Body / payload**
- `(body)`: `RegisterPushTokenDto` — raw: `@Body() dto: RegisterPushTokenDto`

`RegisterPushTokenDto` from `src/auth/dto/push-token.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `token` | `string` | Yes | @IsString(), @IsNotEmpty({ message: 'token must not be empty' }), @Transform(({ value }) => String(value).trim()) |
| `platform` | `string` | No | @IsOptional(), @IsString(), @IsIn(['web', 'android', 'ios']) |
| `deviceId` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `userAgent` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 174. `GET /auth/push-tokens/me`

- **Controller:** `AuthController.getMyPushTokens()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Bearer JWT
- **Return expression/source:** `this.authService.getMyPushTokens(userId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() userId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 175. `POST /auth/reset-password`

- **Controller:** `AuthController.resetPassword()`
- **Source:** `src/auth/controllers/auth.controller.ts`
- **Auth:** Public
- **Return expression/source:** `this.authService.resetPassword(dto.token, dto.newPassword, req)`

**Body / payload**
- `(body)`: `ResetPasswordDto` — raw: `@Body() dto: ResetPasswordDto`

`ResetPasswordDto` from `src/auth/dto/reset-password.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `token` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `newPassword` | `string` | Yes | @IsNotEmpty(), @IsString(), @MinLength(6), @MaxLength(35) |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `branding` endpoints

### 176. `GET /branding`

- **Controller:** `AppController.getBranding()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `bug-reports` endpoints

### 177. `POST /bug-reports`

- **Controller:** `BugReportController.create()`
- **Source:** `src/bug-report/bug-report.controller.ts`
- **Auth:** Bearer JWT
- **Return expression/source:** `this.bugReportService.submitBugReport( dto, request.user, this.extractRequestDetails(request), )`

**Body / payload**
- `(body)`: `CreateBugReportDto` — raw: `@Body() dto: CreateBugReportDto`

`CreateBugReportDto` from `src/bug-report/dto/create-bug-report.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `category` | `string` | No | @IsString(), @Transform(trimRequiredString), @IsNotEmpty(), @MinLength(5), @MaxLength(3000), @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(80) |
| `severity` | `BugReportSeverity` | No | @IsOptional(), @Transform(({ value }) => {, @IsEnum(BugReportSeverity) |
| `pageUrl` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(2000) |
| `route` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(500) |
| `title` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(300) |
| `screenshotDataUrl` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @Validate(ScreenshotDataUrlConstraint), @Validate(ScreenshotDataUrlSizeConstraint) |
| `uploadedScreenshotDataUrl` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @Validate(ScreenshotDataUrlConstraint), @Validate(ScreenshotDataUrlSizeConstraint) |
| `browser` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `os` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `device` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `screen` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `network` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `app` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `recentErrors` | `any[]` | No | @IsOptional(), @IsArray(), @ArrayMaxSize(20) |
| `stepsToReproduce` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(2000) |
| `expectedBehavior` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(2000) |
| `actualBehavior` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(2000) |
| `extra` | `Record<string, any>` | No | @IsOptional(), @IsObject() |

**Request/response objects / upload notes**
- `@Req() request: BugReportRequest`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `cities` endpoints

### 178. `GET /cities/:countryCode/:stateCode`

- **Controller:** `AppController.getCities()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ action: true, message: 'Cities fetched successfully', data: this.appService.getCitiesByState(countryCode, stateCode) }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `countryCode` | `string` | Yes | `@Param('countryCode') countryCode: string` |
| `stateCode` | `string` | Yes | `@Param('stateCode') stateCode: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `countries` endpoints

### 179. `GET /countries`

- **Controller:** `AppController.getCountries()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ action: true, message: 'Countries fetched successfully', data: this.appService.getCountries() }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `currencies` endpoints

### 180. `GET /currencies`

- **Controller:** `AppController.getCurrencies()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ action: true, message: 'Currencies fetched successfully', data: this.appService.getCurrencies() }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `dateformats` endpoints

### 181. `GET /dateformats`

- **Controller:** `AppController.getDateFormats()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.appService.getDateFormats()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `devicestypes` endpoints

### 182. `GET /devicestypes`

- **Controller:** `AppController.getDeviceTypes()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Return expression/source:** `this.appService.getDeviceTypes()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `documenttypes` endpoints

### 183. `GET /documenttypes/:documentType`

- **Controller:** `AppController.getDocumentTypes()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Return expression/source:** `await this.appService.getDocumentTypes(documentType)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `documentType` | `string` | Yes | `@Param('documentType') documentType: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `geocoding` endpoints

### 184. `GET /geocoding/precision`

- **Controller:** `GeocodingController.precision()`
- **Source:** `src/geocoding/geocoding.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER, TEAM, DRIVER
- **Return expression/source:** `{ action: true, message: 'Current geocoding precision', data: { precision: p }, }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 185. `GET /geocoding/reverse`

- **Controller:** `GeocodingController.reverse()`
- **Source:** `src/geocoding/geocoding.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER, TEAM, DRIVER
- **Return expression/source:** `{ action: true, message: 'Address resolved', data: { address: result.address, cached: result.source !== 'api', precision, rounded: { lat: latRounded, lon: lonRounded }, providerUsed: result.providerUsed ?? result.sour... \| { action: false, message: 'Geocoding failed internally', data: { address: '' }, }`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `lat` | `string` | Yes | `@Query('lat') latRaw: string` |
| `lng` | `string` | Yes | `@Query('lng') lngRaw: string` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 186. `POST /geocoding/reverse/bulk`

- **Controller:** `GeocodingController.reverseBulk()`
- **Source:** `src/geocoding/geocoding.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN, ADMIN, USER, SUBUSER, TEAM, DRIVER
- **Return expression/source:** `{ action: true, message: `Resolved ${items.length} addresses`, data: { items }, }`

**Body / payload**
- `(body)`: `BulkReverseGeocodeDto` — raw: `@Body() dto: BulkReverseGeocodeDto`

`BulkReverseGeocodeDto` — see `src/geocoding/dto/reverse-geocode.dto.ts` (no simple public fields detected).

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `handledata` endpoints

### 187. `POST /handledata`

- **Controller:** `HandledataController.handleData()`
- **Source:** `src/handledata/handledata.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.handledataService.ingest(payload)`

**Body / payload**
- `(body)`: `any` — raw: `@Body() payload: any`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `health` endpoints

### 188. `GET /health`

- **Controller:** `HealthController.getHealth()`
- **Source:** `src/health/health.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ status: primaryHealth && logsHealth && addressHealth && redisHealth ? 'ok' : 'degraded', timestamp: new Date().toISOString(), service: 'NestJS Backend', build: this.buildFingerprint(), runtime: describeBackendRuntim...`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 189. `GET /health/address-db`

- **Controller:** `HealthController.getAddressDbHealth()`
- **Source:** `src/health/health.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ status: isHealthy ? 'ok' : 'error', database: 'address', timestamp: new Date().toISOString(), }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 190. `GET /health/databases`

- **Controller:** `HealthController.getDatabasesHealth()`
- **Source:** `src/health/health.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ status: primaryHealth && logsHealth && addressHealth ? 'ok' : 'degraded', timestamp: new Date().toISOString(), runtime: describeBackendRuntimeProfile(), redis: { durability: redisDurability, }, databases: { primary:...`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 191. `GET /health/logs-db`

- **Controller:** `HealthController.getLogsDbHealth()`
- **Source:** `src/health/health.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ status: isHealthy ? 'ok' : 'error', database: 'logs', timestamp: new Date().toISOString(), }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 192. `GET /health/primary-db`

- **Controller:** `HealthController.getPrimaryDbHealth()`
- **Source:** `src/health/health.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ status: isHealthy ? 'ok' : 'error', database: 'primary', timestamp: new Date().toISOString(), }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 193. `GET /health/telemetry-diagnostics/:imei`

- **Controller:** `HealthController.getTelemetryDiagnostics()`
- **Source:** `src/health/health.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ status: 'ok', timestamp: new Date().toISOString(), build: this.buildFingerprint(), data: stats ? this.buildImeiTelemetrySummary(imei, stats) : null, }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 194. `GET /health/telemetry-packet/:imei/:sourcePacketId`

- **Controller:** `HealthController.getTelemetryPacket()`
- **Source:** `src/health/health.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ status: 'ok', timestamp: new Date().toISOString(), build: this.buildFingerprint(), data: { imei, sourcePacketId, route, telemetryLog, deviceEventLog, }, }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |
| `sourcePacketId` | `string` | Yes | `@Param('sourcePacketId') sourcePacketId: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 195. `GET /health/telemetry-stats`

- **Controller:** `HealthController.getTelemetryStats()`
- **Source:** `src/health/health.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ status: 'ok', timestamp: new Date().toISOString(), build: this.buildFingerprint(), runtime: describeBackendRuntimeProfile(), redis: { durability: redisDurability, }, data: this.buildGlobalTelemetrySummary(summary), }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 196. `GET /health/telemetry-stats/:imei`

- **Controller:** `HealthController.getImeiTelemetryStats()`
- **Source:** `src/health/health.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ status: 'ok', timestamp: new Date().toISOString(), build: this.buildFingerprint(), data: stats ? this.buildImeiTelemetrySummary(imei, stats) : null, }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `languages` endpoints

### 197. `GET /languages`

- **Controller:** `AppController.getLanguages()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.appService.getLanguages()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `mobileprefix` endpoints

### 198. `GET /mobileprefix`

- **Controller:** `AppController.getMobileCode()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ action: true, message: 'Mobile codes fetched successfully', data: this.appService.getMobileCode() } \| this.appService.getMobileCode()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `policies` endpoints

### 199. `GET /policies`

- **Controller:** `AppController.getPolicies()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ action: true, message: 'Policies fetched successfully', data: policies }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 200. `GET /policies/:type`

- **Controller:** `AppController.getPolicyByType()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ action: false, message: 'Policy not found', data: null } \| { action: true, message: 'Policy fetched successfully', data: policy }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `type` | `string` | Yes | `@Param('type') type: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `public` endpoints

### 201. `GET /public/track/:code`

- **Controller:** `PublicTrackController.getLinkMeta()`
- **Source:** `src/public-track/public-track.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getLinkMeta(code)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 202. `GET /public/track/:code/geofences`

- **Controller:** `PublicTrackController.getGeofences()`
- **Source:** `src/public-track/public-track.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getGeofences(code)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 203. `GET /public/track/:code/telemetry`

- **Controller:** `PublicTrackController.getMapTelemetry()`
- **Source:** `src/public-track/public-track.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getMapTelemetry(code)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 204. `GET /public/track/:code/vehicles/:imei/details`

- **Controller:** `PublicTrackController.getVehicleDetailsByImei()`
- **Source:** `src/public-track/public-track.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getVehicleDetailsByImei(code, imei)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 205. `GET /public/track/:code/vehicles/:imei/history`

- **Controller:** `PublicTrackController.getVehicleHistoryByImei()`
- **Source:** `src/public-track/public-track.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getVehicleHistoryByImei(code, imei, { from, to, stopMin, overspeedKph, maxPoints, })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `stopMin` | `string` | No | `@Query('stopMin') stopMin?: string` |
| `overspeedKph` | `string` | No | `@Query('overspeedKph') overspeedKph?: string` |
| `maxPoints` | `string` | No | `@Query('maxPoints') maxPoints?: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 206. `GET /public/track/:code/vehicles/:imei/logs`

- **Controller:** `PublicTrackController.getVehicleLogsByImei()`
- **Source:** `src/public-track/public-track.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getVehicleLogsByImei(code, imei, { limit, beforeId })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `limit` | `string` | No | `@Query('limit') limit?: string` |
| `beforeId` | `string` | No | `@Query('beforeId') beforeId?: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 207. `GET /public/track/:code/vehicles/:imei/replay`

- **Controller:** `PublicTrackController.getVehicleReplayByImei()`
- **Source:** `src/public-track/public-track.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.publicTrack.getVehicleReplayByImei(code, imei, { from, to, maxPoints })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `code` | `string` | Yes | `@Param('code') code: string` |
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `maxPoints` | `string` | No | `@Query('maxPoints') maxPoints?: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `simproviders` endpoints

### 208. `GET /simproviders`

- **Controller:** `AppController.getSimProviders()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ action: true, message: 'SIM Providers fetched successfully', data: await this.appService.getSimProviders() }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `states` endpoints

### 209. `GET /states/:countryCode`

- **Controller:** `AppController.getStates()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ action: true, message: 'States fetched successfully', data: this.appService.getStatesByCountry(countryCode) }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `countryCode` | `string` | Yes | `@Param('countryCode') countryCode: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `status` endpoints

### 210. `GET /status`

- **Controller:** `AppController.getStatus()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Return expression/source:** `"Running"`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `superadmin` endpoints

### 211. `POST /superadmin/activateadmin/:id`

- **Controller:** `SuperadminController.activateAdmin()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.activateAdmin(adminid, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param("id", ParseIntPipe) adminid: number` |

**Body / payload**
- `(body)`: `ActivateAdminDto` — raw: `@Body() dto: ActivateAdminDto`

`ActivateAdminDto` from `src/superadmin/dto/activateadmin.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `isActive` | `boolean` | Yes | @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 212. `GET /superadmin/admin/:id`

- **Controller:** `SuperadminController.getAdminById()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getAdminById(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 213. `GET /superadmin/admin/:id/activitylogs`

- **Controller:** `SuperadminController.getAdminActivityLogs()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAdminActivityLogs(headerId, id, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `AdminActivityLogsDto` | Yes | `@Query() dto: AdminActivityLogsDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 214. `GET /superadmin/adminlist`

- **Controller:** `SuperadminController.getAdminList()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAdminList(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 215. `GET /superadmin/adminlogin/:id`

- **Controller:** `SuperadminController.adminLogin()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.adminLogin(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param("id", ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 216. `POST /superadmin/adminpasswordupdate`

- **Controller:** `SuperadminController.updateAdminPassword()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateAdminPassword(adminpasswordupdate)`

**Body / payload**
- `(body)`: `AdminPasswordUpdateDto` — raw: `@Body() adminpasswordupdate: AdminPasswordUpdateDto`

`AdminPasswordUpdateDto` from `src/superadmin/dto/adminpasswordupdate.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `adminid` | `string` | Yes | @IsNotEmpty(), @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)) |
| `newpassword` | `string` | Yes | @IsNotEmpty(), @IsString(), @MinLength(6), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)) |
| `confirmpassword` | `string` | Yes | @IsNotEmpty(), @IsString(), @Match('newpassword', { message: 'confirmpassword must match newpassword' }), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 217. `GET /superadmin/adminvehicles/:adminId`

- **Controller:** `SuperadminController.getAdminVehiclesList()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAdminVehiclesList(adminId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `adminId` | `number` | Yes | `@Param('adminId', ParseIntPipe) adminId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 218. `GET /superadmin/appnotifytemplates`

- **Controller:** `SuperadminController.getAppNotifyTemplates()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getAppNotifyTemplates()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 219. `GET /superadmin/appnotifytemplates/:id`

- **Controller:** `SuperadminController.getAppNotifyTemplateById()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getAppNotifyTemplateById(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 220. `PATCH /superadmin/appnotifytemplates/:id`

- **Controller:** `SuperadminController.updateAppNotifyTemplate()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateAppNotifyTemplate(id, appNotifyTemplateDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `AppNotifyTemplateDto` — raw: `@Body() appNotifyTemplateDto: AppNotifyTemplateDto`

`AppNotifyTemplateDto` from `src/superadmin/dto/appnotifytempletes.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `notifySubject` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @Length(2, 120) |
| `message` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(10000) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 221. `POST /superadmin/assigncredits/:id`

- **Controller:** `SuperadminController.assignCredits()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.assignCredits(id, creditsUpdateDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `CreditsUpdateDto` — raw: `@Body() creditsUpdateDto: CreditsUpdateDto`

`CreditsUpdateDto` from `src/superadmin/dto/creditassign.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `credits` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `activity` | `string` | Yes | @IsNotEmpty(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 222. `GET /superadmin/calendar/day`

- **Controller:** `SuperadminController.getCalendarDayDetails()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCalendarDayDetails(dto.date, dto.types)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `CalendarDayDto` | Yes | `@Query() dto: CalendarDayDto` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 223. `GET /superadmin/calendar/events`

- **Controller:** `SuperadminController.getCalendarEvents()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCalendarEvents(dto.from, dto.to, dto.types)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `CalendarRangeDto` | Yes | `@Query() dto: CalendarRangeDto` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 224. `GET /superadmin/calendar/user/:uid`

- **Controller:** `SuperadminController.getCalendarUserDetails()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCalendarUserDetails(uid)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `uid` | `number` | Yes | `@Param('uid', ParseIntPipe) uid: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 225. `GET /superadmin/commands/:cmdId`

- **Controller:** `SuperadminController.getCommandLogByCmdId()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCommandLogByCmdId(cmdId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `cmdId` | `string` | Yes | `@Param('cmdId') cmdId: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 226. `GET /superadmin/commands/status/:cmdId`

- **Controller:** `SuperadminController.getCommandStatus()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCommandStatus(cmdId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `cmdId` | `string` | Yes | `@Param('cmdId') cmdId: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 227. `GET /superadmin/commandtypes`

- **Controller:** `SuperadminController.getCommandTypes()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getCommandTypes()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 228. `POST /superadmin/commandtypes`

- **Controller:** `SuperadminController.createCommandType()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createCommandType(commandTypeDto)`

**Body / payload**
- `(body)`: `any` — raw: `@Body() commandTypeDto: any`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 229. `DELETE /superadmin/commandtypes/:id`

- **Controller:** `SuperadminController.deleteCommandType()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteCommandType(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 230. `PATCH /superadmin/commandtypes/:id`

- **Controller:** `SuperadminController.updateCommandType()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateCommandType(id, commandTypeDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `any` — raw: `@Body() commandTypeDto: any`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 231. `GET /superadmin/companyconfig/:id`

- **Controller:** `SuperadminController.getCompanyConfig()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getCompanyConfig(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 232. `PATCH /superadmin/companyconfig/:id`

- **Controller:** `SuperadminController.updateCompanyConfig()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateCompanyConfig(id, companyConfig)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `CompanyDto` — raw: `@Body() companyConfig: CompanyDto`

`CompanyDto` from `src/admin/dto/company.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 233. `PATCH /superadmin/companydetails`

- **Controller:** `SuperadminController.updateCompanyDetails()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateCompanyConfig(headerId, companyConfig)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CompanyDto` — raw: `@Body() companyConfig: CompanyDto`

`CompanyDto` from `src/admin/dto/company.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 234. `POST /superadmin/createadmin`

- **Controller:** `SuperadminController.createAdmin()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createAdmin(Admindto, headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateAdminDto` — raw: `@Body() Admindto: CreateAdminDto`

`CreateAdminDto` from `src/superadmin/dto/admin.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `email` | `string` | No | @IsOptional(), @IsEmail(), @Transform(({ value }) => String(value).trim().toLowerCase()) |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => value?.toString().trim()) |
| `mobileNumber` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => value?.toString().trim()) |
| `username` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `password` | `string` | Yes | @IsString(), @MinLength(6) |
| `companyName` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `address` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `country` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `state` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `city` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => value?.toString().trim()) |
| `credits` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 235. `GET /superadmin/creditlogs/:id`

- **Controller:** `SuperadminController.getCreditLogs()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCreditLogs(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 236. `GET /superadmin/customcommands`

- **Controller:** `SuperadminController.getCustomCommands()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getCustomCommands(query)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `CustomCommandsQueryDto` | Yes | `@Query() query: CustomCommandsQueryDto` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 237. `POST /superadmin/customcommands`

- **Controller:** `SuperadminController.createCustomCommand()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createCustomCommand(customCommandDto)`

**Body / payload**
- `(body)`: `CustomCommandDto` — raw: `@Body() customCommandDto: CustomCommandDto`

`CustomCommandDto` from `src/superadmin/dto/customcommand.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `deviceTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `commandTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `command` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(500) // command templates can be long |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 238. `DELETE /superadmin/customcommands/:id`

- **Controller:** `SuperadminController.deleteCustomCommand()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteCustomCommand(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 239. `PATCH /superadmin/customcommands/:id`

- **Controller:** `SuperadminController.updateCustomCommand()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateCustomCommand(id, customCommandDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `CustomCommandDto` — raw: `@Body() customCommandDto: CustomCommandDto`

`CustomCommandDto` from `src/superadmin/dto/customcommand.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `deviceTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `commandTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `command` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(500) // command templates can be long |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 240. `GET /superadmin/dashboard/activitylogs`

- **Controller:** `SuperadminController.getDashboardActivityLogs()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getDashboardActivityLogs(headerId, dto)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `DashboardActivityLogsDto` | Yes | `@Query() dto: DashboardActivityLogsDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 241. `GET /superadmin/dashboard/adoptiongraph`

- **Controller:** `SuperadminController.getAdoptionGraph()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAdoptionGraphData()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 242. `GET /superadmin/dashboard/overview`

- **Controller:** `SuperadminController.getDashboardOverview()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getDashboardOverview(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 243. `GET /superadmin/dashboard/recentusers`

- **Controller:** `SuperadminController.getRecentUsers()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getRecentUsers()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 244. `GET /superadmin/dashboard/recentvehicles`

- **Controller:** `SuperadminController.getRecentVehicles()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getRecentVehicles()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 245. `GET /superadmin/dashboard/totalcounts`

- **Controller:** `SuperadminController.getTotalCounts()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getTotalCounts()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 246. `DELETE /superadmin/deleteadmin/:id`

- **Controller:** `SuperadminController.deleteAdmin()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteAdmin(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 247. `POST /superadmin/devices/:imei/send-command`

- **Controller:** `SuperadminController.sendDeviceCommand()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.sendDeviceCommandByImei(headerId, imei, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `SendDeviceCommandDto` — raw: `@Body() dto: SendDeviceCommandDto`

`SendDeviceCommandDto` from `src/superadmin/dto/send-device-command.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `command` | `string` | Yes | @IsString(), @IsNotEmpty(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @MaxLength(500) |
| `note` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 248. `GET /superadmin/devicetypes`

- **Controller:** `SuperadminController.getDeviceTypes()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getDeviceTypes()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 249. `POST /superadmin/devicetypes`

- **Controller:** `SuperadminController.createDeviceType()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createDeviceType(deviceTypeDto)`

**Body / payload**
- `(body)`: `DeviceTypeDto` — raw: `@Body() deviceTypeDto: DeviceTypeDto`

`DeviceTypeDto` from `src/superadmin/dto/devicetype.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `port` | `number` | Yes | @IsInt(), @Min(1), @Max(65535) |
| `manufacturer` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |
| `protocol` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |
| `firmwareVersion` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 250. `DELETE /superadmin/devicetypes/:id`

- **Controller:** `SuperadminController.deleteDeviceType()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteDeviceType(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 251. `PATCH /superadmin/devicetypes/:id`

- **Controller:** `SuperadminController.updateDeviceType()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateDeviceType(id, deviceTypeDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `DeviceTypeDto` — raw: `@Body() deviceTypeDto: DeviceTypeDto`

`DeviceTypeDto` from `src/superadmin/dto/devicetype.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `port` | `number` | Yes | @IsInt(), @Min(1), @Max(65535) |
| `manufacturer` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |
| `protocol` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |
| `firmwareVersion` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 252. `GET /superadmin/documents/:adminId`

- **Controller:** `SuperadminController.getDocuments()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getDocuments(adminId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `adminId` | `number` | Yes | `@Param('adminId', ParseIntPipe) adminId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 253. `GET /superadmin/documenttypes`

- **Controller:** `SuperadminController.getDocumentTypes()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getDocumentTypes()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 254. `POST /superadmin/documenttypes`

- **Controller:** `SuperadminController.createDocumentType()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createDocumentType(documentTypeDto)`

**Body / payload**
- `(body)`: `DocumentTypeDto` — raw: `@Body() documentTypeDto: DocumentTypeDto`

`DocumentTypeDto` from `src/superadmin/dto/documenttype.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `docFor` | `DocForDto` | Yes | @IsEnum(DocForDto, { message: "docFor must be one of: USER, DRIVER, VEHICLE" }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 255. `DELETE /superadmin/documenttypes/:id`

- **Controller:** `SuperadminController.deleteDocumentType()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteDocumentType(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 256. `PATCH /superadmin/documenttypes/:id`

- **Controller:** `SuperadminController.updateDocumentType()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateDocumentType(id, documentTypeDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `DocumentTypeDto` — raw: `@Body() documentTypeDto: DocumentTypeDto`

`DocumentTypeDto` from `src/superadmin/dto/documenttype.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `docFor` | `DocForDto` | Yes | @IsEnum(DocForDto, { message: "docFor must be one of: USER, DRIVER, VEHICLE" }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 257. `GET /superadmin/domainlist`

- **Controller:** `SuperadminController.getDomainList()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getDomainList()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 258. `GET /superadmin/emailtemplates`

- **Controller:** `SuperadminController.getEmailTemplates()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getEmailTemplates()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 259. `GET /superadmin/emailtemplates/:id`

- **Controller:** `SuperadminController.getEmailTemplateById()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getEmailTemplateById(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 260. `PATCH /superadmin/emailtemplates/:id`

- **Controller:** `SuperadminController.updateEmailTemplate()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateEmailTemplate(id, emailTemplateDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `EmailTemplateDto` — raw: `@Body() emailTemplateDto: EmailTemplateDto`

`EmailTemplateDto` from `src/superadmin/dto/emailtemplate.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `emailSubject` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @Length(2, 120) |
| `message` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(10000) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 261. `POST /superadmin/ftkey/deactivate`

- **Controller:** `SuperadminController.deactivateFtkey()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deactivateFtkey()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 262. `POST /superadmin/ftkey/recheck`

- **Controller:** `SuperadminController.recheckFtkey()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.recheckFtkey()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 263. `GET /superadmin/ftkey/status`

- **Controller:** `SuperadminController.getFtkeyStatus()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getFtkeyStatus()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 264. `POST /superadmin/ftkey/validate`

- **Controller:** `SuperadminController.validateFtkey()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.validateAndSaveFtkey(dto.ftkey)`

**Body / payload**
- `(body)`: `ValidateFtkeyDto` — raw: `@Body() dto: ValidateFtkeyDto`

`ValidateFtkeyDto` from `src/superadmin/dto/ftkey.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `ftkey` | `string` | Yes | @IsString(), @IsNotEmpty() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 265. `GET /superadmin/geofences`

- **Controller:** `SuperadminController.getAllGeofences()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAllGeofences()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 266. `GET /superadmin/integrations`

- **Controller:** `SuperadminController.listIntegrations()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.listThirdPartyIntegrations(headerId, query)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `ListThirdPartyIntegrationsQueryDto` | Yes | `@Query() query: ListThirdPartyIntegrationsQueryDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 267. `POST /superadmin/integrations`

- **Controller:** `SuperadminController.upsertIntegration()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.upsertThirdPartyIntegration(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpsertThirdPartyIntegrationDto` — raw: `@Body() dto: UpsertThirdPartyIntegrationDto`

`UpsertThirdPartyIntegrationDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `scope` | `IntegrationScope` | Yes | @IsEnum(IntegrationScope) |
| `adminId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @ValidateIf((o) => o.scope === 'ADMIN') |
| `category` | `IntegrationCategory` | Yes | @IsEnum(IntegrationCategory) |
| `provider` | `IntegrationProvider` | Yes | @IsEnum(IntegrationProvider) |
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Transform(({ value }) => String(value).trim()) |
| `status` | `IntegrationStatus` | No | @IsOptional(), @IsEnum(IntegrationStatus) |
| `isDefault` | `boolean` | No | @IsOptional(), @Transform(({ value }) =>, @IsBoolean() |
| `priority` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(0) |
| `publicConfig` | `any` | No | @IsOptional() |
| `secretJson` | `any` | No | @IsOptional() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 268. `DELETE /superadmin/integrations/:id`

- **Controller:** `SuperadminController.deleteIntegration()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteThirdPartyIntegration(headerId, id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 269. `PATCH /superadmin/integrations/:id`

- **Controller:** `SuperadminController.updateIntegration()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateThirdPartyIntegration(headerId, id, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateThirdPartyIntegrationDto` — raw: `@Body() dto: UpdateThirdPartyIntegrationDto`

`UpdateThirdPartyIntegrationDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `status` | `IntegrationStatus` | No | @IsOptional(), @IsEnum(IntegrationStatus) |
| `isDefault` | `boolean` | No | @IsOptional(), @Transform(({ value }) =>, @IsBoolean() |
| `priority` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(0) |
| `publicConfig` | `any` | No | @IsOptional() |
| `lastError` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 270. `GET /superadmin/integrations/:id/openrouter/models`

- **Controller:** `SuperadminController.getOpenRouterModels()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getOpenRouterModels(headerId, id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 271. `POST /superadmin/integrations/:id/rotate-secret`

- **Controller:** `SuperadminController.rotateIntegrationSecret()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.rotateThirdPartyIntegrationSecret(headerId, id, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `RotateThirdPartyIntegrationSecretDto` — raw: `@Body() dto: RotateThirdPartyIntegrationSecretDto`

`RotateThirdPartyIntegrationSecretDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `secretJson` | `any` | Yes | @IsNotEmpty({ message: 'secretJson must not be empty' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 272. `POST /superadmin/integrations/:id/test-fcm`

- **Controller:** `SuperadminController.testFcmIntegration()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.testFcmIntegration(headerId, id, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `TestFcmIntegrationDto` — raw: `@Body() dto: TestFcmIntegrationDto`

`TestFcmIntegrationDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `token` | `string` | Yes | @IsString(), @IsNotEmpty({ message: 'token must not be empty' }), @Transform(({ value }) => String(value).trim()) |
| `title` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `body` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `data` | `any` | No | @IsOptional() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 273. `POST /superadmin/integrations/:id/test-openrouter`

- **Controller:** `SuperadminController.testOpenRouterIntegration()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.testOpenRouterIntegration(headerId, id, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `TestOpenRouterIntegrationDto` — raw: `@Body() dto: TestOpenRouterIntegrationDto`

`TestOpenRouterIntegrationDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `model` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `prompt` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 274. `POST /superadmin/integrations/:id/test-whatsapp`

- **Controller:** `SuperadminController.testWhatsAppIntegration()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.testWhatsAppIntegration(headerId, id, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `TestWhatsAppIntegrationDto` — raw: `@Body() dto: TestWhatsAppIntegrationDto`

`TestWhatsAppIntegrationDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `phoneNumber` | `string` | Yes | @IsString(), @IsNotEmpty({ message: 'phoneNumber must not be empty' }), @Transform(({ value }) => String(value).trim()) |
| `mode` | `'template' \| 'custom'` | No | @IsOptional(), @IsString(), @Transform(({ value }) => String(value ?? 'template').trim().toLowerCase()) |
| `templateName` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `languageCode` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `message` | `string` | No | @ValidateIf((o) => o.mode === 'custom'), @IsString(), @IsNotEmpty({ message: 'message must not be empty when mode is custom' }), @Transform(({ value }) => (value ? String(value).trim() : value)) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 275. `POST /superadmin/integrations/:id/validate-geocoding`

- **Controller:** `SuperadminController.validateGeocodingIntegration()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.validateGeocodingIntegration(headerId, id, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `ValidateGeocodingIntegrationDto` — raw: `@Body() dto: ValidateGeocodingIntegrationDto`

`ValidateGeocodingIntegrationDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `lat` | `number` | Yes | @Type(() => Number), @IsNumber(), @Min(-90), @Max(90) |
| `lng` | `number` | Yes | @Type(() => Number), @IsNumber(), @Min(-180), @Max(180) |
| `language` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `zoom` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @Max(20) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 276. `POST /superadmin/integrations/:id/validate-google-sso`

- **Controller:** `SuperadminController.validateGoogleSsoIntegration()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.validateGoogleSsoIntegration(headerId, id, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `ValidateGoogleSsoDto` — raw: `@Body() dto: ValidateGoogleSsoDto`

`ValidateGoogleSsoDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `redirectUri` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 277. `GET /superadmin/localization`

- **Controller:** `SuperadminController.getLocalizationData()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getLocalizationData(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 278. `PATCH /superadmin/localization`

- **Controller:** `SuperadminController.updateLocalizationData()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateadminSettings(headerId, localizationDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateSettingsStateDto` — raw: `@Body() localizationDto: UpdateSettingsStateDto`

`UpdateSettingsStateDto` from `src/superadmin/dto/usersetting.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `language` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_LANGUAGES as unknown as string[], { message: "Invalid language" }) |
| `layoutDirection` | `LayoutDirectionDto` | No | @IsOptional(), @IsEnum(LayoutDirectionDto) |
| `dateFormat` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_DATE_FORMATS as unknown as string[], { message: "Invalid dateFormat" }) |
| `use24Hour` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `theme` | `ThemeModeDto` | No | @IsOptional(), @IsEnum(ThemeModeDto) |
| `timezoneOffset` | `string` | No | @IsOptional(), @IsString(), @IsIn(ALLOWED_TIMEZONE_OFFSETS as unknown as string[], { message: "Invalid timezoneOffset" }) |
| `units` | `UnitsDto` | No | @IsOptional(), @IsEnum(UnitsDto) |
| `defaultLat` | `number` | No | @IsOptional() |
| `defaultLon` | `number` | No | @IsOptional() |
| `mapZoom` | `number` | No | @IsOptional() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 279. `GET /superadmin/map-events`

- **Controller:** `SuperadminController.getMapEvents()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getMapEvents(query)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `MapEventsQueryDto` | Yes | `@Query() query: MapEventsQueryDto` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 280. `GET /superadmin/map-telemetry`

- **Controller:** `SuperadminController.getMapTelemetry()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getMapTelemetry()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 281. `GET /superadmin/notifications`

- **Controller:** `SuperadminController.getNotifications()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getNotifications(headerId, query)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `NotificationsQueryDto` | Yes | `@Query() query: NotificationsQueryDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 282. `PATCH /superadmin/notifications/:id/read`

- **Controller:** `SuperadminController.markNotificationRead()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.markNotificationRead(headerId, id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 283. `PATCH /superadmin/notifications/read-all`

- **Controller:** `SuperadminController.markAllNotificationsRead()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.markAllNotificationsRead(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 284. `POST /superadmin/notifications/test-fcm-me`

- **Controller:** `SuperadminController.testFcmToMe()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.testFcmToMe(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `TestFcmToMeDto` — raw: `@Body() dto: TestFcmToMeDto`

`TestFcmToMeDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `title` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `body` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 285. `GET /superadmin/openrouter/models`

- **Controller:** `SuperadminController.listOpenRouterModels()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.listOpenRouterModels(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 286. `GET /superadmin/pois`

- **Controller:** `SuperadminController.getAllPois()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAllPois()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 287. `PATCH /superadmin/policy`

- **Controller:** `SuperadminController.updatePolicy()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updatePolicy(PolicyDto)`

**Body / payload**
- `(body)`: `PolicyDto` — raw: `@Body() PolicyDto: PolicyDto`

`PolicyDto` from `src/superadmin/dto/policy.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `PolicyType` | `PolicyTypeDto` | Yes | @IsEnum(PolicyTypeDto, { message: "type must be one of: PRIVACY_POLICY, SERVICE_TERMS, COOKIES, REFUND" }) |
| `PolicyText` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(200000) // big enterprise content, adjust if needed |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 288. `POST /superadmin/policy`

- **Controller:** `SuperadminController.createPolicy()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getPolicy(Policy_type)`

**Body / payload**
- `PolicyType`: `string` — raw: `@Body('PolicyType') Policy_type: string`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 289. `GET /superadmin/profile`

- **Controller:** `SuperadminController.getProfile()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<string>`
- **Return expression/source:** `this.superadminService.getProfile()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 290. `PATCH /superadmin/profile`

- **Controller:** `SuperadminController.updateProfile()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateProfile(profileDto)`

**Body / payload**
- `(body)`: `ProfileDto` — raw: `@Body() profileDto: ProfileDto`

`ProfileDto` from `src/superadmin/dto/profile.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `mobileNumber` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `addressLine` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `countryCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `stateCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `cityName` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 291. `GET /superadmin/profile/email-subscription`

- **Controller:** `SuperadminController.getEmailSubscription()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, data: { isSubscribed: subscribed, brandOwnerId, scope } }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 292. `POST /superadmin/profile/email-subscription/subscribe`

- **Controller:** `SuperadminController.subscribeEmail()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Subscribed', data: { isSubscribed: true } }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 293. `POST /superadmin/profile/verify/email/confirm`

- **Controller:** `SuperadminController.verifyEmailOtp()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.verifyEmailOtp(headerId, dto.otp)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `VerifyOtpDto` — raw: `@Body() dto: VerifyOtpDto`

`VerifyOtpDto` from `src/verification/dto/verify-otp.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 294. `POST /superadmin/profile/verify/email/request`

- **Controller:** `SuperadminController.requestEmailOtp()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.requestEmailOtp(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 295. `POST /superadmin/profile/verify/whatsapp/confirm`

- **Controller:** `SuperadminController.verifyWhatsAppOtp()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.commsVerification.verifyWhatsAppOtpForSuperadmin(headerId, dto.otp)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `VerifyOtpDto` — raw: `@Body() dto: VerifyOtpDto`

`VerifyOtpDto` from `src/verification/dto/verify-otp.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 296. `POST /superadmin/profile/verify/whatsapp/request`

- **Controller:** `SuperadminController.requestWhatsAppOtp()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.commsVerification.requestWhatsAppOtpForSuperadmin(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 297. `GET /superadmin/routes`

- **Controller:** `SuperadminController.getAllRoutes()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAllRoutes(includeGeodata === 'true')`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `includeGeodata` | `string` | No | `@Query('includeGeodata') includeGeodata?: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 298. `POST /superadmin/server/actions`

- **Controller:** `ServerController.createServerActionJob()`
- **Source:** `src/superadmin/server/server.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `{ action: true, message: 'Server action job created', data: created, }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `ServerActionDto` — raw: `@Body() dto: ServerActionDto`

`ServerActionDto` from `src/superadmin/server/dto/server-action.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `componentId` | `ServerActionComponentId` | Yes | @IsIn(SERVER_COMPONENT_IDS) |
| `action` | `ServerActionType` | Yes | @IsIn(SERVER_ACTIONS), @Validate(ServerActionRulesConstraint) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 299. `GET /superadmin/server/jobs/:id`

- **Controller:** `ServerController.getServerActionJob()`
- **Source:** `src/superadmin/server/server.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `{ action: false, message: 'Job not found' } \| { action: false, message: latestLog?.message \|\| 'Job failed', data: job, } \| { action: true, message: 'Job fetched', data: job, }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 300. `GET /superadmin/server/jobs/:id/stream`

- **Controller:** `ServerController.streamServerActionJob()`
- **Source:** `src/superadmin/server/server.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 301. `GET /superadmin/server/overview`

- **Controller:** `ServerController.getOverview()`
- **Source:** `src/superadmin/server/server.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `{ action: true, message: 'Server overview', data, }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 302. `GET /superadmin/settings/:id`

- **Controller:** `SuperadminController.getSettings()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getadminSettings(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 303. `PATCH /superadmin/settings/:id`

- **Controller:** `SuperadminController.updateSettings()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateadminSettings(id, settingsDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `UpdateSettingsStateDto` — raw: `@Body() settingsDto: UpdateSettingsStateDto`

`UpdateSettingsStateDto` from `src/superadmin/dto/usersetting.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `language` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_LANGUAGES as unknown as string[], { message: "Invalid language" }) |
| `layoutDirection` | `LayoutDirectionDto` | No | @IsOptional(), @IsEnum(LayoutDirectionDto) |
| `dateFormat` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_DATE_FORMATS as unknown as string[], { message: "Invalid dateFormat" }) |
| `use24Hour` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `theme` | `ThemeModeDto` | No | @IsOptional(), @IsEnum(ThemeModeDto) |
| `timezoneOffset` | `string` | No | @IsOptional(), @IsString(), @IsIn(ALLOWED_TIMEZONE_OFFSETS as unknown as string[], { message: "Invalid timezoneOffset" }) |
| `units` | `UnitsDto` | No | @IsOptional(), @IsEnum(UnitsDto) |
| `defaultLat` | `number` | No | @IsOptional() |
| `defaultLon` | `number` | No | @IsOptional() |
| `mapZoom` | `number` | No | @IsOptional() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 304. `GET /superadmin/settings/data-retention/preview`

- **Controller:** `SuperadminController.previewDataRetention()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.previewDataRetention()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 305. `POST /superadmin/settings/data-retention/run`

- **Controller:** `SuperadminController.runDataRetention()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.runDataRetention(body?.dryRun === true)`

**Body / payload**
- `(body)`: `{ dryRun?: boolean }` — raw: `@Body() body?: { dryRun?: boolean }`
  - Inline object: `{ dryRun?: boolean }`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 306. `GET /superadmin/simproviders`

- **Controller:** `SuperadminController.getSimProviders()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getSimProviders()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 307. `POST /superadmin/simproviders`

- **Controller:** `SuperadminController.createSimProvider()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createSimProvider(simProviderDto)`

**Body / payload**
- `(body)`: `SimProviderDto` — raw: `@Body() simProviderDto: SimProviderDto`

`SimProviderDto` from `src/superadmin/dto/simprociders.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `countryCode` | `string` | Yes | @IsString(), @IsNotEmpty(), @Matches(/^[A-Z]{2}$/, { message: "countryCode must be 2 uppercase letters (e.g. IN, NZ)" }) |
| `apnName` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `apnUser` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `apnPassword` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 308. `DELETE /superadmin/simproviders/:id`

- **Controller:** `SuperadminController.deleteSimProvider()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteSimProvider(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 309. `PATCH /superadmin/simproviders/:id`

- **Controller:** `SuperadminController.updateSimProvider()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateSimProvider(id, simProviderDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `SimProviderDto` — raw: `@Body() simProviderDto: SimProviderDto`

`SimProviderDto` from `src/superadmin/dto/simprociders.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `countryCode` | `string` | Yes | @IsString(), @IsNotEmpty(), @Matches(/^[A-Z]{2}$/, { message: "countryCode must be 2 uppercase letters (e.g. IN, NZ)" }) |
| `apnName` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `apnUser` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `apnPassword` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 310. `GET /superadmin/smtpconfig/:id`

- **Controller:** `SuperadminController.getSmtpConfig()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getSmtpConfig(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 311. `PATCH /superadmin/smtpconfig/:id`

- **Controller:** `SuperadminController.updateSmtpConfig()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateSmtpConfig(id, smtpConfig)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `SmtpSettingDto` — raw: `@Body() smtpConfig: SmtpSettingDto`

`SmtpSettingDto` from `src/superadmin/dto/smtp.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `senderName` | `string` | No | @IsOptional(), @IsString() |
| `host` | `string` | No | @IsOptional(), @IsString() |
| `port` | `string \| number` | No | @IsOptional(), @IsOptional(), @Matches(/^\d+$/,{message: 'port must be a numeric string or number'}) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `type` | `SmtpSecurity` | No | @IsOptional(), @IsEnum(SmtpSecurity) |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `replyTo` | `string` | No | @IsOptional(), @IsEmail() |
| `isActive` | `string \| boolean` | No | @IsOptional(), @IsOptional(), @Matches(/^(true\|false)$/i, { message: 'isActive must be a boolean string ("true" or "false")' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 312. `GET /superadmin/smtpsettings`

- **Controller:** `SuperadminController.getSmtpSettings()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getSmtpSettings(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 313. `PATCH /superadmin/smtpsettings`

- **Controller:** `SuperadminController.updateSmtpSettings()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateSmtpConfig(headerId, smtpSettingsDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `SmtpSettingDto` — raw: `@Body() smtpSettingsDto: SmtpSettingDto`

`SmtpSettingDto` from `src/superadmin/dto/smtp.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `senderName` | `string` | No | @IsOptional(), @IsString() |
| `host` | `string` | No | @IsOptional(), @IsString() |
| `port` | `string \| number` | No | @IsOptional(), @IsOptional(), @Matches(/^\d+$/,{message: 'port must be a numeric string or number'}) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `type` | `SmtpSecurity` | No | @IsOptional(), @IsEnum(SmtpSecurity) |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `replyTo` | `string` | No | @IsOptional(), @IsEmail() |
| `isActive` | `string \| boolean` | No | @IsOptional(), @IsOptional(), @Matches(/^(true\|false)$/i, { message: 'isActive must be a boolean string ("true" or "false")' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 314. `GET /superadmin/softwareconfig`

- **Controller:** `SuperadminController.getConfig()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.GetConfig(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 315. `PATCH /superadmin/softwareconfig`

- **Controller:** `SuperadminController.updateConfig()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.updateConfig(headerId, softwareConfigDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `SoftwareConfigDto` — raw: `@Body() softwareConfigDto: SoftwareConfigDto`

`SoftwareConfigDto` from `src/superadmin/dto/softwareconfig.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `geocodingPrecision` | `GeocodingPrecisionDto` | No | @IsOptional(), @IsEnum(GeocodingPrecisionDto) |
| `backupDays` | `number` | No | @IsOptional(), @IsInt(), @Min(0) |
| `allowDemoLogin` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `allowSignup` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `signupCredits` | `number` | No | @IsOptional(), @IsInt(), @Min(0), @Max(2_000_000_000, { message: 'signupCredits must not exceed 2,000,000,000' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 316. `POST /superadmin/ssl/install`

- **Controller:** `SslController.install()`
- **Source:** `src/ssl/ssl.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `{ action: true, message: `SSL ${dto.action} job started`, data: { jobId: job.id, domain: job.domain, action: job.action }, }`

**Body / payload**
- `(body)`: `SslInstallDto` — raw: `@Body() dto: SslInstallDto`

`SslInstallDto` from `src/ssl/dto/ssl.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `domain` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `action` | `SslAction` | Yes | @IsEnum(SslAction) |
| `email` | `string` | No | @IsOptional(), @IsString() |
| `backendProxyPass` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 317. `GET /superadmin/ssl/jobs/:jobId`

- **Controller:** `SslController.getJob()`
- **Source:** `src/ssl/ssl.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `{ action: false, message: 'Job not found', data: null } \| { action: true, message: 'Job state retrieved', data: job }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `jobId` | `string` | Yes | `@Param('jobId') jobId: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 318. `GET /superadmin/ssl/jobs/:jobId/stream`

- **Controller:** `SslStreamController.streamJob()`
- **Source:** `src/ssl/ssl.controller.ts`
- **Auth:** Public
- **Return expression/source:** `final state if (!emitter) { reply.status(200).send({ action: true, message: 'Job already completed', data: job, })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `jobId` | `string` | Yes | `@Param('jobId') jobId: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `token` | `string` | Yes | `@Query('token') token: string` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 319. `GET /superadmin/ssl/status`

- **Controller:** `SslController.getStatus()`
- **Source:** `src/ssl/ssl.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `{ action: true, message: 'SSL status retrieved', data }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 320. `GET /superadmin/support/tickets`

- **Controller:** `SuperadminController.listSupportTickets()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.listSupportTickets(headerId, { status, search, priority, category })`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `status` | `string` | No | `@Query('status') status?: string` |
| `search` | `string` | No | `@Query('search') search?: string` |
| `priority` | `string` | No | `@Query('priority') priority?: string` |
| `category` | `string` | No | `@Query('category') category?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 321. `POST /superadmin/support/tickets`

- **Controller:** `SuperadminController.createSupportTicketOnBehalfOfAdmin()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createSupportTicketOnBehalfOfAdmin(headerId, req, body)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `any` — raw: `@Body() body: any`

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 322. `GET /superadmin/support/tickets/:id`

- **Controller:** `SuperadminController.getSupportTicketById()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getSupportTicketById(ticketId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 323. `POST /superadmin/support/tickets/:id/messages`

- **Controller:** `SuperadminController.replySupportTicket()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.replySupportTicket(ticketId, headerId, req, body)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `ReplySupportTicketDto` — raw: `@Body() body: ReplySupportTicketDto`

`ReplySupportTicketDto` from `src/superadmin/dto/reply-support-ticket.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `message` | `string` | No | @IsOptional(), @IsString(), @MaxLength(5000), @Matches(MEANINGFUL_TEXT, { message: 'Message must contain at least one letter or number' }) |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 324. `PATCH /superadmin/support/tickets/:id/status`

- **Controller:** `SuperadminController.updateSupportTicketStatus()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateSupportTicketStatus(ticketId, headerId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateSupportTicketStatusDto` — raw: `@Body() dto: UpdateSupportTicketStatusDto`

`UpdateSupportTicketStatusDto` from `src/superadmin/dto/update-support-ticket-status.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `status` | `TicketStatusEnum` | Yes | @IsEnum(TicketStatusEnum) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 325. `GET /superadmin/systemvariables`

- **Controller:** `SuperadminController.getSystemVariables()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getSystemVariables()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 326. `POST /superadmin/systemvariables`

- **Controller:** `SuperadminController.createSystemVariable()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createSystemVariable(systemVariableDto)`

**Body / payload**
- `(body)`: `SystemVariableDto` — raw: `@Body() systemVariableDto: SystemVariableDto`

`SystemVariableDto` from `src/superadmin/dto/systemvariable.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `message` | `"name must start with a letter and contain only letters, numbers, and underscore",` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80), @Matches(/^[A-Za-z][A-Za-z0-9_]*$/, { |
| `name` | `string` | Yes |  |
| `initialValue` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(500) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 327. `DELETE /superadmin/systemvariables/:id`

- **Controller:** `SuperadminController.deleteSystemVariable()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteSystemVariable(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 328. `PATCH /superadmin/systemvariables/:id`

- **Controller:** `SuperadminController.updateSystemVariable()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateSystemVariable(id, systemVariableDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `SystemVariableDto` — raw: `@Body() systemVariableDto: SystemVariableDto`

`SystemVariableDto` from `src/superadmin/dto/systemvariable.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `message` | `"name must start with a letter and contain only letters, numbers, and underscore",` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80), @Matches(/^[A-Za-z][A-Za-z0-9_]*$/, { |
| `name` | `string` | Yes |  |
| `initialValue` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(500) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 329. `GET /superadmin/telemetry`

- **Controller:** `SuperadminController.getTelemetrySnapshot()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getTelemetrySnapshot(headerId, imeis)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imeis` | `string` | No | `@Query('imeis') imeis?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 330. `POST /superadmin/testsmtp`

- **Controller:** `SuperadminController.testSmtpSettings()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.testSmtpSettings(headerId, email)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `email`: `string` — raw: `@Body('email') email: string`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 331. `GET /superadmin/topbar-search`

- **Controller:** `SuperadminController.searchTopbar()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.topbarSearch.searchForSuperadmin(headerId, dto)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `TopbarSearchQueryDto` | Yes | `@Query() dto: TopbarSearchQueryDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 332. `GET /superadmin/transactions`

- **Controller:** `SuperadminController.listTransactions()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'OK', data }`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `adminId` | `string` | No | `@Query('adminId') adminId?: string` |
| `status` | `string` | No | `@Query('status') status?: string` |
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `q` | `string` | No | `@Query('q') q?: string` |
| `page` | `string` | No | `@Query('page') page?: string` |
| `limit` | `string` | No | `@Query('limit') limit?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 333. `GET /superadmin/transactions/analytics`

- **Controller:** `SuperadminController.transactionsAnalytics()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'OK', data }`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `adminId` | `string` | No | `@Query('adminId') adminId?: string` |
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `month` | `string` | No | `@Query('month') month?: string` |
| `year` | `string` | No | `@Query('year') year?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 334. `POST /superadmin/transactions/manual`

- **Controller:** `SuperadminController.recordManualTransaction()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Payment recorded', data }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `RecordManualTransactionDto` — raw: `@Body() dto: RecordManualTransactionDto`

`RecordManualTransactionDto` from `src/superadmin/dto/record-manual-transaction.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `adminId` | `number` | Yes | @Type(() => Number), @IsInt() |
| `amount` | `string` | Yes | @IsString(), @Matches(/^\d+(\.\d{1,2})?$/), @MaxLength(12, { message: 'Amount must not exceed 9999999999.99' }) |
| `reference` | `string` | No | @IsOptional(), @IsString(), @MaxLength(100) |
| `paymentMode` | `PaymentMode` | No | @IsOptional(), @IsEnum(PaymentMode) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 335. `POST /superadmin/updateadmin/:id`

- **Controller:** `SuperadminController.updateAdmin()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateAdmin(id, Adminupdatedto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `UpdateAdminDto` — raw: `@Body() Adminupdatedto: UpdateAdminDto`

`UpdateAdminDto` from `src/superadmin/dto/updateadmin.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `mobileNumber` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `addressLine` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `countryCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `stateCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `cityName` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 336. `PATCH /superadmin/updatepassword`

- **Controller:** `SuperadminController.updatePassword()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updatePassword(headerId, passwordDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdatePasswordDto` — raw: `@Body() passwordDto: UpdatePasswordDto`

`UpdatePasswordDto` from `src/superadmin/dto/updatepassword.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `currentPassword` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `newPassword` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(6), @MaxLength(72) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 337. `POST /superadmin/upload/:id`

- **Controller:** `SuperadminController.upload()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `await this.superadminService.handleUpload(req, id) \| { action: false, message: error.message \|\| 'Upload failed', data: null }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 338. `POST /superadmin/uploaddoc`

- **Controller:** `SuperadminController.uploadDocument()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.superadminService.uploadDocumentMultipart(req, headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 339. `DELETE /superadmin/uploaddoc/:id`

- **Controller:** `SuperadminController.deleteDocument()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.superadminService.deleteDocument(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 340. `PATCH /superadmin/uploaddoc/:id`

- **Controller:** `SuperadminController.uploadDocumentUpdate()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `await this.superadminService.updateDocumentMultipart(req, id) \| await this.superadminService.updateDocument(id, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `UpdateDocDto` — raw: `@Body() dto: UpdateDocDto`

`UpdateDocDto` from `src/superadmin/dto/updatedoc.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `title` | `string` | No | @IsOptional(), @IsString(), @MaxLength(255) |
| `docTypeId` | `number` | No | @IsOptional(), @IsInt(), @Min(1) |
| `fileName` | `string` | No | @IsOptional(), @IsString(), @MaxLength(255) |
| `description` | `string` | No | @IsOptional(), @IsString(), @MaxLength(1000) |
| `tags` | `string` | No | @IsOptional(), @IsString(), @MaxLength(2000) |
| `associateType` | `AssociateTypeDto` | No | @IsOptional(), @IsEnum(AssociateTypeDto, { message: 'associateType must be one of: USER, VEHICLE, DRIVER' }) |
| `associateId` | `number` | No | @IsOptional(), @IsInt(), @Min(1) |
| `expiryAt` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `isVisible` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `isVisibleDriver` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 341. `GET /superadmin/vehicles`

- **Controller:** `SuperadminController.getAllVehicles()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getAllVehicles(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 342. `GET /superadmin/vehicles/:id`

- **Controller:** `SuperadminController.getVehicleById()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleById(id, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 343. `GET /superadmin/vehicles/by-imei/:imei/commands`

- **Controller:** `SuperadminController.getCommandHistoryByImei()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getCommandHistoryByImei(imei, { limit, cursorId })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `limit` | `string` | No | `@Query('limit') limit?: string` |
| `cursorId` | `string` | No | `@Query('cursorId') cursorId?: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 344. `GET /superadmin/vehicles/by-imei/:imei/details`

- **Controller:** `SuperadminController.getVehicleDetailsByImei()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleDetailsByImei(imei, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 345. `GET /superadmin/vehicles/by-imei/:imei/events`

- **Controller:** `SuperadminController.getVehicleEventsByImei()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleEventsByImei(imei, query)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `MapEventsQueryDto` | Yes | `@Query() query: MapEventsQueryDto` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 346. `GET /superadmin/vehicles/by-imei/:imei/history`

- **Controller:** `SuperadminController.getVehicleHistoryByImei()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleHistoryByImei(imei, { from, to, stopMin, overspeedKph, maxPoints, })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `stopMin` | `string` | No | `@Query('stopMin') stopMin?: string` |
| `overspeedKph` | `string` | No | `@Query('overspeedKph') overspeedKph?: string` |
| `maxPoints` | `string` | No | `@Query('maxPoints') maxPoints?: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 347. `GET /superadmin/vehicles/by-imei/:imei/logs`

- **Controller:** `SuperadminController.getVehicleLogsByImei()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleLogsByImei(imei, { from, to, limit, beforeId })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `limit` | `string` | No | `@Query('limit') limit?: string` |
| `beforeId` | `string` | No | `@Query('beforeId') beforeId?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId?: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 348. `GET /superadmin/vehicles/by-imei/:imei/replay`

- **Controller:** `SuperadminController.getVehicleReplayByImei()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleReplayByImei(imei, { from, to, maxPoints })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `maxPoints` | `string` | No | `@Query('maxPoints') maxPoints?: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 349. `POST /superadmin/vehicles/by-imei/:imei/send-command`

- **Controller:** `SuperadminController.sendDeviceCommandByImei()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.sendDeviceCommandByImei(headerId, imei, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `SendDeviceCommandDto` — raw: `@Body() dto: SendDeviceCommandDto`

`SendDeviceCommandDto` from `src/superadmin/dto/send-device-command.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `command` | `string` | Yes | @IsString(), @IsNotEmpty(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @MaxLength(500) |
| `note` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 350. `GET /superadmin/vehicles/by-imei/:imei/sensors`

- **Controller:** `SuperadminController.getVehicleSensorsByImei()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleSensorsByImei(imei, headerId, { includeTelemetryMeta, })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `includeTelemetryMeta` | `string` | No | `@Query('includeTelemetryMeta') includeTelemetryMeta?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 351. `GET /superadmin/vehicles/by-imei/:imei/trail`

- **Controller:** `SuperadminController.getVehicleTrailByImei()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getVehicleTrailByImei(imei, { hours, from, to, maxPoints })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `hours` | `string` | No | `@Query('hours') hours?: string` |
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `maxPoints` | `string` | No | `@Query('maxPoints') maxPoints?: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 352. `GET /superadmin/vehicletypes`

- **Controller:** `SuperadminController.getVehicleTypes()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.superadminService.getVehicleTypes()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 353. `POST /superadmin/vehicletypes`

- **Controller:** `SuperadminController.createVehicleType()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.createVehicleType(vehicleTypeDto)`

**Body / payload**
- `(body)`: `VehicleTypeDto` — raw: `@Body() vehicleTypeDto: VehicleTypeDto`

`VehicleTypeDto` from `src/superadmin/dto/vehicletype.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 60) |
| `message` | `"slug must be lowercase and hyphen-separated (e.g. snowplow, mini-truck)",` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 60), @Matches(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, { |
| `slug` | `string` | Yes |  |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 354. `DELETE /superadmin/vehicletypes/:id`

- **Controller:** `SuperadminController.deleteVehicleType()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.deleteVehicleType(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 355. `PATCH /superadmin/vehicletypes/:id`

- **Controller:** `SuperadminController.updateVehicleType()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateVehicleType(id, vehicleTypeDto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `VehicleTypeDto` — raw: `@Body() vehicleTypeDto: VehicleTypeDto`

`VehicleTypeDto` from `src/superadmin/dto/vehicletype.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 60) |
| `message` | `"slug must be lowercase and hyphen-separated (e.g. snowplow, mini-truck)",` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 60), @Matches(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, { |
| `slug` | `string` | Yes |  |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 356. `GET /superadmin/whatsapptemplates`

- **Controller:** `WhatsAppTemplatesController.list()`
- **Source:** `src/superadmin/whatsapp-templates/whatsapp-templates.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.templatesService.listTemplates(query)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `ListWhatsAppTemplatesQueryDto` | Yes | `@Query() query: ListWhatsAppTemplatesQueryDto` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 357. `GET /superadmin/whatsapptemplates/:id`

- **Controller:** `WhatsAppTemplatesController.getOne()`
- **Source:** `src/superadmin/whatsapp-templates/whatsapp-templates.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.templatesService.getTemplate(id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 358. `PATCH /superadmin/whatsapptemplates/:id`

- **Controller:** `WhatsAppTemplatesController.update()`
- **Source:** `src/superadmin/whatsapp-templates/whatsapp-templates.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.templatesService.updateTemplate(id, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Body / payload**
- `(body)`: `UpdateWhatsAppTemplateDto` — raw: `@Body() dto: UpdateWhatsAppTemplateDto`

`UpdateWhatsAppTemplateDto` from `src/superadmin/dto/whatsapp-templates.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `title` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @Length(2, 200) |
| `body` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(1024) |
| `category` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(50) |
| `languageCode` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(10) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 359. `GET /superadmin/whatsapptemplates/meta`

- **Controller:** `WhatsAppTemplatesController.fetchMeta()`
- **Source:** `src/superadmin/whatsapp-templates/whatsapp-templates.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.templatesService.fetchMetaTemplates()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 360. `POST /superadmin/whatsapptemplates/sync`

- **Controller:** `WhatsAppTemplatesController.sync()`
- **Source:** `src/superadmin/whatsapp-templates/whatsapp-templates.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Return expression/source:** `this.templatesService.syncTemplates(dto)`

**Body / payload**
- `(body)`: `SyncWhatsAppTemplatesDto` — raw: `@Body() dto: SyncWhatsAppTemplatesDto`

`SyncWhatsAppTemplatesDto` from `src/superadmin/dto/whatsapp-templates.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `templateIds` | `number[]` | No | @IsOptional(), @IsArray(), @IsInt({ each: true }), @Min(1, { each: true }), @Type(() => Number) |
| `dryRun` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 361. `GET /superadmin/whitelabel`

- **Controller:** `SuperadminController.getWhiteLabelSettings()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.getWhiteLabelSettings(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 362. `PATCH /superadmin/whitelabel`

- **Controller:** `SuperadminController.updateWhiteLabelSettings()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.updateWhiteLabelSettings(req, headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 363. `GET /superadmin/whitelabel/inspect`

- **Controller:** `SuperadminController.inspectWhiteLabelBranding()`
- **Source:** `src/superadmin/superadmin.controller.ts`
- **Auth:** Bearer JWT; roles: SUPERADMIN
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.superadminService.inspectWhiteLabelBranding(host)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `host` | `string` | No | `@Query('host') host?: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `timezones` endpoints

### 364. `GET /timezones`

- **Controller:** `AppController.getTimezones()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Timezones fetched successfully', data: await this.appService.getTimezones() }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `unsubscribe` endpoints

### 365. `GET /unsubscribe`

- **Controller:** `AppController.unsubscribe()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<void>`
- **Return expression/source:** `sendHtml( '<h2>Invalid link</h2>' + '<p>This unsubscribe link is invalid or has expired.</p>', ) \| sendHtml( '<h2>Invalid link</h2>' + '<p>This unsubscribe link is invalid or has expired.</p>', ) \| sendHtml( '<h2>Unsubscribed</h2>' + '<p>You have been unsubscribed from email notifications.</p>' + '<p style="margin-top:16px`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `u` | `string` | Yes | `@Query('u') u: string` |
| `b` | `string` | Yes | `@Query('b') b: string` |
| `s` | `string` | Yes | `@Query('s') s: string` |
| `t` | `string` | Yes | `@Query('t') t: string` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `user` endpoints

### 366. `GET /user/commands/:cmdId`

- **Controller:** `UserController.getCommandLogByCmdId()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getCommandLogByCmdId(userId, cmdId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `cmdId` | `string` | Yes | `@Param('cmdId') cmdId: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() userId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 367. `POST /user/commands/send-bulk`

- **Controller:** `UserController.sendCommandBulk()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.sendCommandBulk(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `SendCommandBulkDto` — raw: `@Body() dto: SendCommandBulkDto`

`SendCommandBulkDto` from `src/user/dto/send-command-bulk.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `mode` | `SendCommandBulkMode` | Yes | @IsEnum(SendCommandBulkMode) |
| `vehicleIds` | `number[]` | No | @ValidateIf((o) => o.mode === SendCommandBulkMode.SELECTED && !o.items?.length), @IsOptional(), @IsArray(), @ArrayMinSize(1), @IsInt({ each: true }), @Type(() => Number) |
| `command` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |
| `items` | `SendCommandBulkItem[]` | No | @IsOptional(), @IsArray(), @ArrayMinSize(1), @ValidateNested({ each: true }), @Type(() => SendCommandBulkItem) |
| `note` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 368. `GET /user/commands/status/:cmdId`

- **Controller:** `UserController.getCommandStatus()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getCommandStatus(cmdId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `cmdId` | `string` | Yes | `@Param('cmdId') cmdId: string` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 369. `PATCH /user/companydetails`

- **Controller:** `UserController.updateOwnCompanyDetails()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateCompanyDetails(headerId, companyDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CompanyDto` — raw: `@Body() companyDto: CompanyDto`

`CompanyDto` from `src/admin/dto/company.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 370. `GET /user/customcommands`

- **Controller:** `UserController.getUserCustomCommands()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserCustomCommands(query)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `CustomCommandsQueryDto` | Yes | `@Query() query: CustomCommandsQueryDto` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 371. `GET /user/dashboard/day-night-comparison`

- **Controller:** `UserController.getDayNightComparison()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDayNightComparison(headerId, { vehicleId, from, to })`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `string` | No | `@Query('vehicleId') vehicleId?: string` |
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 372. `GET /user/dashboard/fleet-status`

- **Controller:** `UserController.getUserFleetStatus()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserFleetStatus(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 373. `GET /user/dashboard/recent-alerts`

- **Controller:** `UserController.getDashboardRecentAlerts()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDashboardRecentAlerts(headerId, { vehicleId: Number.isFinite(vid) ? vid : undefined, limit: limit ? parseInt(limit, 10) : undefined, beforeId: beforeId ? parseInt(beforeId, 10) : undefined, from, })`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `string` | No | `@Query('vehicleId') vehicleId?: string` |
| `limit` | `string` | No | `@Query('limit') limit?: string` |
| `beforeId` | `string` | No | `@Query('beforeId') beforeId?: string` |
| `from` | `string` | No | `@Query('from') from?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 374. `GET /user/dashboard/recent-alerts/:id`

- **Controller:** `UserController.getDashboardRecentAlertDetail()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDashboardRecentAlertDetail(headerId, id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 375. `PATCH /user/dashboard/recent-alerts/:id/read`

- **Controller:** `UserController.markDashboardRecentAlertRead()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.markDashboardRecentAlertRead(headerId, id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 376. `GET /user/dashboard/top-performing-assets`

- **Controller:** `UserController.topPerformingAssets()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getTopPerformingAssets(headerId, { from, to, limit })`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `limit` | `string` | No | `@Query('limit') limit?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 377. `GET /user/dashboard/usage-last-7-days`

- **Controller:** `UserController.getUsageLast7Days()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUsageLast7Days(headerId, Number.isFinite(vid) ? vid : undefined)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `string` | No | `@Query('vehicleId') vehicleId?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 378. `GET /user/dashboard/weekly-comparison`

- **Controller:** `UserController.weeklyComparison()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getWeeklyComparison(headerId, Number.isFinite(vid) ? vid : undefined)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `string` | No | `@Query('vehicleId') vehicleId?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 379. `GET /user/dashboards`

- **Controller:** `UserController.listDashboards()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.listUserDashboards(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 380. `POST /user/dashboards`

- **Controller:** `UserController.createDashboard()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createUserDashboard(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateDashboardDto` — raw: `@Body() dto: CreateDashboardDto`

`CreateDashboardDto` from `src/user/dto/dashboard.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 381. `DELETE /user/dashboards/:id`

- **Controller:** `UserController.deleteDashboard()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteUserDashboard(headerId, dashboardId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) dashboardId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 382. `GET /user/dashboards/:id`

- **Controller:** `UserController.getDashboard()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserDashboardById(headerId, dashboardId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) dashboardId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 383. `PUT /user/dashboards/:id`

- **Controller:** `UserController.updateDashboard()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateUserDashboard(headerId, dashboardId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) dashboardId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateDashboardDto` — raw: `@Body() dto: UpdateDashboardDto`

`UpdateDashboardDto` from `src/user/dto/dashboard.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `config` | `any` | No | @IsOptional() |
| `version` | `number` | Yes | @IsInt(), @Min(1) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 384. `GET /user/drivers`

- **Controller:** `UserController.getDrivers()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDrivers(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 385. `POST /user/drivers`

- **Controller:** `UserController.createDriver()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createDriver(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateUserDriverDto` — raw: `@Body() dto: CreateUserDriverDto`

`CreateUserDriverDto` from `src/user/dto/create-driver.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MaxLength(120) |
| `mobilePrefix` | `string` | Yes | @IsString(), @MaxLength(10) |
| `mobile` | `string` | Yes | @IsString(), @MaxLength(20) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `username` | `string` | Yes | @IsString(), @MaxLength(50) |
| `password` | `string` | Yes | @IsString(), @MaxLength(100) |
| `countryCode` | `string` | Yes | @IsString(), @MaxLength(5) |
| `stateCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `city` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `address` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(20) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 386. `DELETE /user/drivers/:id`

- **Controller:** `UserController.deleteDriver()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteDriver(driverId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 387. `GET /user/drivers/:id`

- **Controller:** `UserController.getDriverById()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDriverById(driverId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 388. `PATCH /user/drivers/:id`

- **Controller:** `UserController.updateDriver()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateDriver(driverId, headerId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateUserDriverDto` — raw: `@Body() dto: UpdateUserDriverDto`

`UpdateUserDriverDto` from `src/user/dto/update-driver.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `mobile` | `string` | No | @IsOptional(), @IsString(), @MaxLength(20) |
| `email` | `string` | No | @IsOptional(), @IsEmail(), @MaxLength(254) |
| `username` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `password` | `string` | No | @IsOptional(), @IsString(), @MaxLength(100) |
| `countryCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(5) |
| `StateCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `city` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `address` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(12) |
| `isactive` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `attributes` | `Record<string, any> \| string` | No | @IsOptional() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 389. `POST /user/drivers/:id/assign-vehicle`

- **Controller:** `UserController.assignDriverToVehicle()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.assignDriverToVehicle(driverId, dto.vehicleId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `AssignDriverVehicleDto` — raw: `@Body() dto: AssignDriverVehicleDto`

`AssignDriverVehicleDto` from `src/user/dto/assign-driver-vehicle.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | @ToRequiredInt(), @IsNumber() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 390. `GET /user/drivers/:id/documents`

- **Controller:** `UserController.getDriverDocuments()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDriverDocuments(driverId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 391. `POST /user/drivers/:id/documents`

- **Controller:** `UserController.uploadDriverDocument()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.uploadDriverDocumentMultipart(req, driverId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 392. `DELETE /user/drivers/:id/documents/:docId`

- **Controller:** `UserController.deleteDriverDocument()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteDriverDocument(driverId, docId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |
| `docId` | `number` | Yes | `@Param('docId', ParseIntPipe) docId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 393. `PATCH /user/drivers/:id/documents/:docId`

- **Controller:** `UserController.updateDriverDocument()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateDriverDocumentMultipart(req, driverId, docId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |
| `docId` | `number` | Yes | `@Param('docId', ParseIntPipe) docId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 394. `GET /user/drivers/:id/logs`

- **Controller:** `UserController.getDriverLogs()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getDriverLogs(driverId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 395. `POST /user/drivers/:id/unassign-vehicle`

- **Controller:** `UserController.unassignDriverFromVehicle()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.unassignDriverFromVehicle(driverId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) driverId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 396. `GET /user/geofences`

- **Controller:** `UserController.listGeofences()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserGeofences(headerId, { q, isActive, type })`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `q` | `string` | No | `@Query('q') q?: string` |
| `isActive` | `string` | No | `@Query('isActive') isActive?: string` |
| `type` | `string` | No | `@Query('type') type?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 397. `POST /user/geofences`

- **Controller:** `UserController.createGeofence()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createUserGeofence(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateGeofenceDto` — raw: `@Body() dto: CreateGeofenceDto`

`CreateGeofenceDto` from `src/user/dto/geofence.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `type` | `GeofenceType` | Yes | @IsEnum(GeofenceType) |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `geodata` | `GeofenceGeoData` | No | @IsObject(), @IsOptional() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 398. `DELETE /user/geofences/:id`

- **Controller:** `UserController.deleteGeofence()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteUserGeofence(headerId, geofenceId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) geofenceId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 399. `GET /user/geofences/:id`

- **Controller:** `UserController.getGeofenceById()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserGeofenceById(headerId, geofenceId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) geofenceId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 400. `PATCH /user/geofences/:id`

- **Controller:** `UserController.updateGeofence()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateUserGeofence(headerId, geofenceId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) geofenceId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateGeofenceDto` — raw: `@Body() dto: UpdateGeofenceDto`

`UpdateGeofenceDto` from `src/user/dto/geofence.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsString(), @IsOptional(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `type` | `GeofenceType` | No | @IsEnum(GeofenceType), @IsOptional() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `geodata` | `GeofenceGeoData` | No | @IsObject(), @IsOptional() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 401. `POST /user/landmarkbulkjobs`

- **Controller:** `UserController.createLandmarkBulkJob()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Landmark bulk job created', data: created }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateLandmarkBulkJobDto` — raw: `@Body() dto: CreateLandmarkBulkJobDto`

`CreateLandmarkBulkJobDto` from `src/user/dto/landmarkbulkjobs.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `geofenceRows` | `GeofenceBulkRowDto[]` | No | @IsDefined(), @IsEnum(LandmarkEntityType), @IsOptional(), @IsArray(), @ValidateNested({ each: true }), @Type(() => GeofenceBulkRowDto) |
| `poiRows` | `PoiBulkRowDto[]` | No | @IsOptional(), @IsArray(), @ValidateNested({ each: true }), @Type(() => PoiBulkRowDto) |
| `routeRows` | `RouteBulkRowDto[]` | No | @IsOptional(), @IsArray(), @ValidateNested({ each: true }), @Type(() => RouteBulkRowDto) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 402. `GET /user/landmarkbulkjobs/:id`

- **Controller:** `UserController.getLandmarkBulkJob()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: false, message: 'Job not found' } \| { action: true, message: 'Job fetched', data: job }`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 403. `GET /user/landmarkbulkjobs/:id/failed.csv`

- **Controller:** `UserController.downloadLandmarkFailedCsv()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 404. `GET /user/landmarkbulkjobs/:id/stream`

- **Controller:** `UserController.streamLandmarkBulkJob()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `string` | Yes | `@Param('id') id: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 405. `GET /user/localization`

- **Controller:** `UserController.getLocalizationData()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getLocalizationData(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 406. `PATCH /user/localization`

- **Controller:** `UserController.updateLocalizationData()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateLocalizationSettings(headerId, localizationDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateSettingsStateDto` — raw: `@Body() localizationDto: UpdateSettingsStateDto`

`UpdateSettingsStateDto` from `src/superadmin/dto/usersetting.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `language` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_LANGUAGES as unknown as string[], { message: "Invalid language" }) |
| `layoutDirection` | `LayoutDirectionDto` | No | @IsOptional(), @IsEnum(LayoutDirectionDto) |
| `dateFormat` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_DATE_FORMATS as unknown as string[], { message: "Invalid dateFormat" }) |
| `use24Hour` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `theme` | `ThemeModeDto` | No | @IsOptional(), @IsEnum(ThemeModeDto) |
| `timezoneOffset` | `string` | No | @IsOptional(), @IsString(), @IsIn(ALLOWED_TIMEZONE_OFFSETS as unknown as string[], { message: "Invalid timezoneOffset" }) |
| `units` | `UnitsDto` | No | @IsOptional(), @IsEnum(UnitsDto) |
| `defaultLat` | `number` | No | @IsOptional() |
| `defaultLon` | `number` | No | @IsOptional() |
| `mapZoom` | `number` | No | @IsOptional() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 407. `GET /user/map-events`

- **Controller:** `UserController.getMapEvents()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapEvents(headerId, query)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `MapEventsQueryDto` | Yes | `@Query() query: MapEventsQueryDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 408. `GET /user/map-telemetry`

- **Controller:** `UserController.getMapTelemetry()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapTelemetry(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 409. `GET /user/notification-settings`

- **Controller:** `UserController.getNotificationSettings()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getNotificationSettings(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 410. `PUT /user/notification-settings`

- **Controller:** `UserController.updateNotificationSettings()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateNotificationSettings(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `any` — raw: `@Body() dto: any`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 411. `GET /user/notifications`

- **Controller:** `UserController.getUserNotifications()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserNotifications(headerId, query)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `NotificationsQueryDto` | Yes | `@Query() query: NotificationsQueryDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 412. `PATCH /user/notifications/:id/read`

- **Controller:** `UserController.markUserNotificationRead()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.markUserNotificationRead(headerId, id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 413. `GET /user/notifications/preferences`

- **Controller:** `UserController.getNotificationPreferences()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getNotificationPreferences(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 414. `PUT /user/notifications/preferences`

- **Controller:** `UserController.updateNotificationPreferences()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateNotificationPreferences(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `any` — raw: `@Body() dto: any`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 415. `PATCH /user/notifications/read-all`

- **Controller:** `UserController.markAllUserNotificationsRead()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.markAllUserNotificationsRead(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 416. `POST /user/notifications/test-fcm-me`

- **Controller:** `UserController.testFcmToMe()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.testFcmToMe(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `any` — raw: `@Body() dto: any`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 417. `GET /user/notifications/vehicle`

- **Controller:** `UserController.getVehicleNotificationsForTopbar()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getVehicleNotificationsForTopbar(headerId, { ...query, vehicleId })`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `NotificationsQueryDto` | Yes | `@Query() query: NotificationsQueryDto` |
| `vehicleId` | `string` | No | `@Query('vehicleId') vehicleId?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 418. `PATCH /user/notifications/vehicle/:id/read`

- **Controller:** `UserController.markVehicleNotificationReadForTopbar()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.markVehicleNotificationReadForTopbar(headerId, id)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) id: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 419. `PATCH /user/notifications/vehicle/read-all`

- **Controller:** `UserController.markAllVehicleNotificationsReadForTopbar()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.markAllVehicleNotificationsReadForTopbar(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 420. `GET /user/pois`

- **Controller:** `UserController.listPois()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserPois(headerId, { q, isActive })`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `q` | `string` | No | `@Query('q') q?: string` |
| `isActive` | `string` | No | `@Query('isActive') isActive?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 421. `POST /user/pois`

- **Controller:** `UserController.createPoi()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createUserPoi(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreatePoiDto` — raw: `@Body() dto: CreatePoiDto`

`CreatePoiDto` from `src/user/dto/poi.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `category` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `iconSlug` | `string` | No | @IsString(), @IsOptional() |
| `toleranceMeters` | `number` | No | @IsNumber(), @IsOptional(), @Min(0) |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `coordinates` | `PoiCoordinatesDto` | Yes | @IsObject(), @ValidateNested(), @Type(() => PoiCoordinatesDto) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 422. `DELETE /user/pois/:id`

- **Controller:** `UserController.deletePoi()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteUserPoi(headerId, poiId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) poiId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 423. `GET /user/pois/:id`

- **Controller:** `UserController.getPoiById()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserPoiById(headerId, poiId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) poiId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 424. `PATCH /user/pois/:id`

- **Controller:** `UserController.updatePoi()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateUserPoi(headerId, poiId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) poiId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdatePoiDto` — raw: `@Body() dto: UpdatePoiDto`

`UpdatePoiDto` from `src/user/dto/poi.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsString(), @IsOptional(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `category` | `string` | No | @IsString(), @IsOptional() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `iconSlug` | `string` | No | @IsString(), @IsOptional() |
| `toleranceMeters` | `number \| null` | No | @IsNumber(), @IsOptional(), @Min(0) |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `coordinates` | `PoiCoordinatesDto` | No | @IsObject(), @IsOptional(), @ValidateNested(), @Type(() => PoiCoordinatesDto) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 425. `GET /user/profile`

- **Controller:** `UserController.getProfile()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getProfile(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 426. `PATCH /user/profile`

- **Controller:** `UserController.updateProfile()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateProfile(headerId, profileDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `ProfileDto` — raw: `@Body() profileDto: ProfileDto`

`ProfileDto` from `src/superadmin/dto/profile.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `mobileNumber` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `addressLine` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `countryCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `stateCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `cityName` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 427. `GET /user/profile/email-subscription`

- **Controller:** `UserController.getEmailSubscription()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, data: { isSubscribed: subscribed, brandOwnerId, scope } }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 428. `POST /user/profile/email-subscription/subscribe`

- **Controller:** `UserController.subscribeEmail()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'Subscribed', data: { isSubscribed: true } }`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 429. `POST /user/profile/verify/email/confirm`

- **Controller:** `UserController.verifyEmailOtp()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.verifyEmailOtp(headerId, dto.otp)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `VerifyOtpDto` — raw: `@Body() dto: VerifyOtpDto`

`VerifyOtpDto` from `src/verification/dto/verify-otp.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 430. `POST /user/profile/verify/email/request`

- **Controller:** `UserController.requestEmailOtp()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.requestEmailOtp(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 431. `POST /user/profile/verify/whatsapp/confirm`

- **Controller:** `UserController.verifyWhatsAppOtp()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.verifyWhatsAppOtp(headerId, dto.otp)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `VerifyOtpDto` — raw: `@Body() dto: VerifyOtpDto`

`VerifyOtpDto` from `src/verification/dto/verify-otp.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 432. `POST /user/profile/verify/whatsapp/request`

- **Controller:** `UserController.requestWhatsAppOtp()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.verificationService.requestWhatsAppOtp(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 433. `GET /user/routes`

- **Controller:** `UserController.listRoutes()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserRoutes(headerId, { q, isActive, includeGeodata })`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `q` | `string` | No | `@Query('q') q?: string` |
| `isActive` | `string` | No | `@Query('isActive') isActive?: string` |
| `includeGeodata` | `string` | No | `@Query('includeGeodata') includeGeodata?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 434. `POST /user/routes`

- **Controller:** `UserController.createRoute()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createUserRoute(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateRouteDto` — raw: `@Body() dto: CreateRouteDto`

`CreateRouteDto` from `src/user/dto/route.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `toleranceMeters` | `number` | No | @IsNumber(), @IsOptional(), @Min(1) |
| `geodata` | `RouteGeoData` | No | @IsObject(), @IsOptional() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 435. `DELETE /user/routes/:id`

- **Controller:** `UserController.deleteRoute()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteUserRoute(headerId, routeId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) routeId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 436. `GET /user/routes/:id`

- **Controller:** `UserController.getRouteById()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserRouteById(headerId, routeId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) routeId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 437. `PATCH /user/routes/:id`

- **Controller:** `UserController.updateRoute()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateUserRoute(headerId, routeId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) routeId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateRouteDto` — raw: `@Body() dto: UpdateRouteDto`

`UpdateRouteDto` from `src/user/dto/route.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsString(), @IsOptional(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `toleranceMeters` | `number` | No | @IsNumber(), @IsOptional(), @Min(1) |
| `geodata` | `RouteGeoData` | No | @IsObject(), @IsOptional() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 438. `GET /user/sharetracklinks`

- **Controller:** `UserController.listShareTrackLinks()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.listShareTrackLinks(headerId, query)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `ListShareTrackLinksDto` | Yes | `@Query() query: ListShareTrackLinksDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 439. `POST /user/sharetracklinks`

- **Controller:** `UserController.createShareTrackLink()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createShareTrackLink(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateShareTrackLinkDto` — raw: `@Body() dto: CreateShareTrackLinkDto`

`CreateShareTrackLinkDto` from `src/user/dto/sharetracklinks/create-sharetracklink.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayMinSize(1), @toIntArray(), @IsInt({ each: true }) |
| `expiryAt` | `string` | Yes | @IsDateString() |
| `isGeofence` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `isHistory` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 440. `DELETE /user/sharetracklinks/:id`

- **Controller:** `UserController.deleteShareTrackLink()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteShareTrackLink(headerId, shareLinkId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) shareLinkId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 441. `GET /user/sharetracklinks/:id`

- **Controller:** `UserController.getShareTrackLinkById()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getShareTrackLinkById(headerId, shareLinkId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) shareLinkId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 442. `PATCH /user/sharetracklinks/:id`

- **Controller:** `UserController.updateShareTrackLink()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateShareTrackLink(headerId, shareLinkId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) shareLinkId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateShareTrackLinkDto` — raw: `@Body() dto: UpdateShareTrackLinkDto`

`UpdateShareTrackLinkDto` from `src/user/dto/sharetracklinks/update-sharetracklink.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `vehicleIds` | `number[]` | No | @IsOptional(), @IsArray(), @ArrayMinSize(1), @toIntArray(), @IsInt({ each: true }) |
| `expiryAt` | `string` | No | @IsOptional(), @IsDateString() |
| `isGeofence` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `isHistory` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 443. `GET /user/subusers`

- **Controller:** `UserController.listSubUsers()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.listSubUsers(headerId, { search, page, limit })`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `search` | `string` | No | `@Query('search') search?: string` |
| `page` | `string` | No | `@Query('page') page?: string` |
| `limit` | `string` | No | `@Query('limit') limit?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 444. `POST /user/subusers`

- **Controller:** `UserController.createSubUser()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createSubUser(headerId, dto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateSubUserDto` — raw: `@Body() dto: CreateSubUserDto`

`CreateSubUserDto` from `src/user/dto/subusers/create-subuser.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MinLength(2) |
| `username` | `string` | No | @IsOptional(), @IsString(), @MinLength(3) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString() |
| `mobileNumber` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d{7,15}$/, { message: 'mobileNumber must be 7-15 digits' }) |
| `password` | `string` | No | @IsOptional(), @IsString(), @MinLength(6) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 445. `DELETE /user/subusers/:id`

- **Controller:** `UserController.deleteSubUser()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteSubUser(headerId, subUserId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) subUserId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 446. `GET /user/subusers/:id`

- **Controller:** `UserController.getSubUserById()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getSubUserById(headerId, subUserId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) subUserId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 447. `PATCH /user/subusers/:id`

- **Controller:** `UserController.updateSubUser()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateSubUser(headerId, subUserId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) subUserId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateSubUserDto` — raw: `@Body() dto: UpdateSubUserDto`

`UpdateSubUserDto` from `src/user/dto/subusers/update-subuser.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MinLength(2) |
| `username` | `string` | No | @IsOptional(), @IsString(), @MinLength(3) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString() |
| `mobileNumber` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d{7,15}$/, { message: 'mobileNumber must be 7-15 digits' }) |
| `password` | `string` | No | @IsOptional(), @IsString(), @MinLength(6) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 448. `GET /user/subusers/:id/vehicles`

- **Controller:** `UserController.getSubUserVehicles()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getSubUserVehicles(headerId, subUserId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) subUserId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 449. `POST /user/subusers/:id/vehicles/assign`

- **Controller:** `UserController.assignSubUserVehicles()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.assignSubUserVehicles(headerId, subUserId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) subUserId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `AssignSubUserVehiclesDto` — raw: `@Body() dto: AssignSubUserVehiclesDto`

`AssignSubUserVehiclesDto` from `src/user/dto/subusers/assign-subuser-vehicles.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayNotEmpty(), @IsInt({ each: true }), @Min(1, { each: true }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 450. `POST /user/subusers/:id/vehicles/unassign`

- **Controller:** `UserController.unassignSubUserVehicles()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.unassignSubUserVehicles(headerId, subUserId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) subUserId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UnassignSubUserVehiclesDto` — raw: `@Body() dto: UnassignSubUserVehiclesDto`

`UnassignSubUserVehiclesDto` from `src/user/dto/subusers/unassign-subuser-vehicles.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayNotEmpty(), @IsInt({ each: true }), @Min(1, { each: true }) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 451. `GET /user/systemvariables`

- **Controller:** `UserController.getUserSystemVariables()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserSystemVariables()`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 452. `GET /user/tickets`

- **Controller:** `UserController.listTickets()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.listTickets(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 453. `POST /user/tickets`

- **Controller:** `UserController.createTicket()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createTicket(headerId, req)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 454. `GET /user/tickets/:id`

- **Controller:** `UserController.getTicketConversation()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getTicketConversation(ticketId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 455. `POST /user/tickets/:id`

- **Controller:** `UserController.addTicketMessage()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.addTicketMessage(ticketId, headerId, req)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) ticketId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 456. `GET /user/topbar-search`

- **Controller:** `UserController.searchTopbar()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.topbarSearch.searchForUser(headerId, dto)`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `TopbarSearchQueryDto` | Yes | `@Query() dto: TopbarSearchQueryDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 457. `GET /user/transactions`

- **Controller:** `UserController.listUserTransactions()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `{ action: true, message: 'OK', data }`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `status` | `string` | No | `@Query('status') status?: string` |
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `q` | `string` | No | `@Query('q') q?: string` |
| `page` | `string` | No | `@Query('page') page?: string` |
| `limit` | `string` | No | `@Query('limit') limit?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 458. `PATCH /user/updatepassword`

- **Controller:** `UserController.updatePassword()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updatePassword(headerId, passwordDto)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdatePasswordDto` — raw: `@Body() passwordDto: UpdatePasswordDto`

`UpdatePasswordDto` from `src/superadmin/dto/updatepassword.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `currentPassword` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `newPassword` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(6), @MaxLength(72) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 459. `POST /user/upload`

- **Controller:** `UserController.uploadProfile()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.uploadProfileImage(req, headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 460. `GET /user/vehicles`

- **Controller:** `UserController.getUserVehicles()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getUserVehicles(headerId)`

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 461. `GET /user/vehicles/:id`

- **Controller:** `UserController.getVehicleById()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getVehicleById(vehicleId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 462. `PATCH /user/vehicles/:id`

- **Controller:** `UserController.updateVehicleById()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateVehicleById(vehicleId, headerId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateUserVehicleDto` — raw: `@Body() dto: UpdateUserVehicleDto`

`UpdateUserVehicleDto` from `src/user/dto/update-vehicle.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @ToTrimmedString(), @IsString() |
| `plateNumber` | `string \| null` | No | @IsOptional(), @ToOptionalNullIfEmptyString(), @IsString() |
| `vin` | `string \| null` | No | @IsOptional(), @ToOptionalNullIfEmptyString(), @IsString() |
| `vehicleTypeId` | `number` | No | @IsOptional(), @ToOptionalInt(), @IsNumber() |
| `gmtOffset` | `string \| null` | No | @IsOptional(), @ToOptionalNullIfEmptyString(), @Matches(/^[+-](0\d\|1[0-4]):[0-5]\d$/) |
| `vehicleMeta` | `Record<string, any>` | No | @IsOptional(), @ToOptionalJSON(), @IsObject() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 463. `PATCH /user/vehicles/:id/config`

- **Controller:** `UserController.updateVehicleConfig()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateVehicleConfig(vehicleId, headerId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateVehicleConfigDto` — raw: `@Body() dto: UpdateVehicleConfigDto`

`UpdateVehicleConfigDto` from `src/admin/dto/update-vehicle-config.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `speedVariation` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `distanceVariation` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `odometer` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `engineHours` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `ignitionSource` | `'ACC' \| 'MOTION'` | No | @IsOptional(), @ToOptionalUpper(), @IsIn(['ACC', 'MOTION']) |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 464. `GET /user/vehicles/:id/documents`

- **Controller:** `UserController.getVehicleDocuments()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getVehicleDocuments(vehicleId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 465. `POST /user/vehicles/:id/documents`

- **Controller:** `UserController.uploadVehicleDocument()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.uploadVehicleDocumentMultipart(req, vehicleId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 466. `DELETE /user/vehicles/:id/documents/:docId`

- **Controller:** `UserController.deleteVehicleDocument()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteVehicleDocument(vehicleId, docId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |
| `docId` | `number` | Yes | `@Param('docId', ParseIntPipe) docId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 467. `PATCH /user/vehicles/:id/documents/:docId`

- **Controller:** `UserController.updateVehicleDocument()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateVehicleDocumentMultipart(req, vehicleId, docId, headerId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `id` | `number` | Yes | `@Param('id', ParseIntPipe) vehicleId: number` |
| `docId` | `number` | Yes | `@Param('docId', ParseIntPipe) docId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Request/response objects / upload notes**
- `@Req() req: FastifyRequest`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 468. `GET /user/vehicles/:vehicleId/commands`

- **Controller:** `UserController.getCommandHistoryByVehicleId()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getCommandHistoryByVehicleId(userId, vehicleId, { limit, cursorId })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `limit` | `string` | No | `@Query('limit') limit?: string` |
| `cursorId` | `string` | No | `@Query('cursorId') cursorId?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() userId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 469. `GET /user/vehicles/:vehicleId/sensors`

- **Controller:** `UserController.listVehicleSensors()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.listVehicleSensors(headerId, vehicleId, { search, page, limit, includeLive: includeLive === 'true', })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `search` | `string` | No | `@Query('search') search?: string` |
| `page` | `string` | No | `@Query('page') page?: string` |
| `limit` | `string` | No | `@Query('limit') limit?: string` |
| `includeLive` | `string` | No | `@Query('includeLive') includeLive?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 470. `POST /user/vehicles/:vehicleId/sensors`

- **Controller:** `UserController.createVehicleSensor()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.createVehicleSensor(headerId, vehicleId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `CreateVehicleSensorDto` — raw: `@Body() dto: CreateVehicleSensorDto`

`CreateVehicleSensorDto` from `src/user/dto/sensors/create-vehicle-sensor.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MinLength(2) |
| `unit` | `string` | No | @IsOptional(), @IsString() |
| `icon` | `string` | No | @IsOptional(), @IsString() |
| `code` | `string` | Yes | @IsString(), @MinLength(5) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 471. `DELETE /user/vehicles/:vehicleId/sensors/:sensorId`

- **Controller:** `UserController.deleteVehicleSensor()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.deleteVehicleSensor(headerId, vehicleId, sensorId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |
| `sensorId` | `number` | Yes | `@Param('sensorId', ParseIntPipe) sensorId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 472. `PATCH /user/vehicles/:vehicleId/sensors/:sensorId`

- **Controller:** `UserController.updateVehicleSensor()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.updateVehicleSensor(headerId, vehicleId, sensorId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |
| `sensorId` | `number` | Yes | `@Param('sensorId', ParseIntPipe) sensorId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `UpdateVehicleSensorDto` — raw: `@Body() dto: UpdateVehicleSensorDto`

`UpdateVehicleSensorDto` from `src/user/dto/sensors/update-vehicle-sensor.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MinLength(2) |
| `unit` | `string` | No | @IsOptional(), @IsString() |
| `icon` | `string` | No | @IsOptional(), @IsString() |
| `code` | `string` | No | @IsOptional(), @IsString(), @MinLength(5) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 473. `GET /user/vehicles/:vehicleId/sensors/:sensorId/history`

- **Controller:** `UserController.getSensorHistory()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getVehicleSensorHistory(headerId, vehicleId, sensorId, { from, to, maxPoints })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |
| `sensorId` | `number` | Yes | `@Param('sensorId', ParseIntPipe) sensorId: number` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `maxPoints` | `string` | No | `@Query('maxPoints') maxPoints?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 474. `POST /user/vehicles/:vehicleId/sensors/run`

- **Controller:** `UserController.runVehicleSensor()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.runVehicleSensor(headerId, vehicleId, dto)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Body / payload**
- `(body)`: `RunVehicleSensorDto` — raw: `@Body() dto: RunVehicleSensorDto`

`RunVehicleSensorDto` from `src/user/dto/sensors/run-vehicle-sensor.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `code` | `string` | Yes | @IsString(), @MinLength(5) |
| `payload` | `Record<string, unknown>` | Yes | @IsObject() |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 475. `GET /user/vehicles/:vehicleId/sensors/telemetry`

- **Controller:** `UserController.getVehicleSensorTelemetry()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getVehicleSensorTelemetry(headerId, vehicleId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 476. `GET /user/vehicles/:vehicleId/telemetry`

- **Controller:** `UserController.getVehicleTelemetrySnapshot()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getVehicleTelemetrySnapshot(headerId, vehicleId)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | `@Param('vehicleId', ParseIntPipe) vehicleId: number` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 477. `GET /user/vehicles/by-imei/:imei/details`

- **Controller:** `UserController.getVehicleDetailsByImei()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleDetailsByImei(headerId, imei)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 478. `GET /user/vehicles/by-imei/:imei/events`

- **Controller:** `UserController.getVehicleEventsByImei()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleEventsByImei(headerId, imei, query)`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `(object)` | `MapEventsQueryDto` | Yes | `@Query() query: MapEventsQueryDto` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 479. `GET /user/vehicles/by-imei/:imei/history`

- **Controller:** `UserController.getVehicleHistoryByImei()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleHistoryByImei(headerId, imei, { from, to, stopMin, overspeedKph, maxPoints, })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `stopMin` | `string` | No | `@Query('stopMin') stopMin?: string` |
| `overspeedKph` | `string` | No | `@Query('overspeedKph') overspeedKph?: string` |
| `maxPoints` | `string` | No | `@Query('maxPoints') maxPoints?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 480. `GET /user/vehicles/by-imei/:imei/logs`

- **Controller:** `UserController.getVehicleLogsByIMEI()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleLogsByImei(headerId, imei, { from, to, limit, beforeId, })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `limit` | `string` | No | `@Query('limit') limit?: string` |
| `beforeId` | `string` | No | `@Query('beforeId') beforeId?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 481. `GET /user/vehicles/by-imei/:imei/replay`

- **Controller:** `UserController.getVehicleReplayByImei()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleReplayByImei(headerId, imei, { from, to, maxPoints, })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `from` | `string` | Yes | `@Query('from') from: string` |
| `to` | `string` | Yes | `@Query('to') to: string` |
| `maxPoints` | `string` | No | `@Query('maxPoints') maxPoints?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 482. `GET /user/vehicles/by-imei/:imei/sensors`

- **Controller:** `UserController.getVehicleSensorsByImei()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleSensorsByImei(headerId, imei, { includeTelemetryMeta, })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `includeTelemetryMeta` | `string` | No | `@Query('includeTelemetryMeta') includeTelemetryMeta?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 483. `GET /user/vehicles/by-imei/:imei/trail`

- **Controller:** `UserController.getVehicleTrailByImei()`
- **Source:** `src/user/user.controller.ts`
- **Auth:** Bearer JWT; roles: ADMIN, USER
- **Controller return type:** `Promise<any>`
- **Return expression/source:** `this.userService.getMapVehicleTrailByImei(headerId, imei, { hours, from, to, maxPoints, })`

**Path params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `imei` | `string` | Yes | `@Param('imei') imei: string` |

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `hours` | `string` | No | `@Query('hours') hours?: string` |
| `from` | `string` | No | `@Query('from') from?: string` |
| `to` | `string` | No | `@Query('to') to?: string` |
| `maxPoints` | `string` | No | `@Query('maxPoints') maxPoints?: string` |

**Headers / derived request context**
| Name | Type / meaning | Raw |
|---|---|---|
| `JWT user id via @HeaderId()` | `number` | `@HeaderId() headerId: number` |

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `vehicletypes` endpoints

### 484. `GET /vehicletypes`

- **Controller:** `AppController.getVehicleTypes()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `version` endpoints

### 485. `GET /version`

- **Controller:** `AppController.getVersion()`
- **Source:** `src/app.controller.ts`
- **Auth:** Public
- **Return expression/source:** `{ action : true, message: 'Version fetched successfully', version: '2.5.8' }`

**Payload:** none detected from the controller signature.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

## `webhooks` endpoints

### 486. `GET /webhooks/whatsapp`

- **Controller:** `WhatsappWebhookController.verify()`
- **Source:** `src/webhooks/whatsapp-webhook.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<void>`

**Query params**
| Name | Type | Required | Raw |
|---|---|---:|---|
| `hub.mode` | `string` | Yes | `@Query('hub.mode') mode: string` |
| `hub.verify_token` | `string` | Yes | `@Query('hub.verify_token') token: string` |
| `hub.challenge` | `string` | Yes | `@Query('hub.challenge') challenge: string` |

**Request/response objects / upload notes**
- `@Res() reply: FastifyReply`

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

### 487. `POST /webhooks/whatsapp`

- **Controller:** `WhatsappWebhookController.inbound()`
- **Source:** `src/webhooks/whatsapp-webhook.controller.ts`
- **Auth:** Public
- **Controller return type:** `Promise<void>`
- **Return expression/source:** `200 quickly to avoid Meta retries const sendOk = () => { if (!reply.sent) reply.status(HttpStatus.OK).send('EVENT_RECEIVED')`

**Request/response objects / upload notes**
- `@Req() req: RawBodyRequest<FastifyRequest>`
- `@Res() reply: FastifyReply`
- When the controller uses `FastifyRequest`, payload may be parsed manually; for upload/document endpoints this usually means `multipart/form-data`.

**Standard successful HTTP response envelope**
```json
{ "status": "success", "data": "<controller return value>", "timestamp": "<ISO date>" }
```

---

## DTO / payload schema appendix

The following DTOs/interfaces were referenced directly by controller method signatures. Full source remains authoritative.

### `ActivateAdminDto`

`ActivateAdminDto` from `src/superadmin/dto/activateadmin.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `isActive` | `boolean` | Yes | @IsBoolean() |

### `AdminActivityLogsDto`

`AdminActivityLogsDto` from `src/admin/dto/admin-activity-logs.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(5), @Max(50) |
| `cursorId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `from` | `string` | No | @IsOptional(), @IsDateString() |
| `to` | `string` | No | @IsOptional(), @IsDateString() |
| `q` | `string` | No | @IsOptional(), @IsString() |
| `userId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `actionPrefix` | `string` | No | @IsOptional(), @IsString() |
| `entity` | `string` | No | @IsOptional(), @IsString() |

### `AdminCalendarDayDto`

`AdminCalendarDayDto` from `src/admin/dto/calendar.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `message` | `'date must be in YYYY-MM-DD format',` | Yes | @IsString(), @Matches(/^\d{4}-\d{2}-\d{2}$/, { |
| `date` | `string` | Yes |  |
| `types` | `string` | No | @IsOptional(), @IsString(), @Validate(IsValidEventTypes) |
| `rk` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+$/, { message: 'rk must be a numeric string' }) |

### `AdminCalendarRangeDto`

`AdminCalendarRangeDto` from `src/admin/dto/calendar.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `message` | `'from must be in YYYY-MM-DD format',` | Yes | @IsString(), @Matches(/^\d{4}-\d{2}-\d{2}$/, { |
| `from` | `string` | Yes |  |
| `message` | `'to must be in YYYY-MM-DD format',` | Yes | @IsString(), @Matches(/^\d{4}-\d{2}-\d{2}$/, { |
| `to` | `string` | Yes | @Validate(IsValidDateRange) |
| `types` | `string` | No | @IsOptional(), @IsString(), @Validate(IsValidEventTypes) |
| `rk` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+$/, { message: 'rk must be a numeric string' }) |

### `AdminConfigDto`

`AdminConfigDto` from `src/admin/dto/adminconfig.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `allowSignup` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `signupCredits` | `number` | No | @IsOptional(), @IsInt(), @Min(0) |

### `AdminDashboardSummaryDto`

`AdminDashboardSummaryDto` from `src/admin/dto/admin-dashboard-summary.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `months` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(3), @Max(24) |
| `listLimit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(5), @Max(25) |
| `currency` | `string` | No | @IsOptional(), @IsString(), @Length(3, 3) |
| `rk` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt() |

### `AdminEventLogsDto`

`AdminEventLogsDto` from `src/admin/dto/admin-event-logs.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @Max(200) |
| `cursorId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `from` | `string` | No | @IsOptional(), @IsDateString() |
| `to` | `string` | No | @IsOptional(), @IsDateString() |
| `vehicleId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `userId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `source` | `string` | No | @IsOptional(), @IsString() |
| `severity` | `string` | No | @IsOptional(), @IsString(), @IsIn(['INFO', 'WARNING', 'CRITICAL']) |
| `isRead` | `boolean` | No | @IsOptional(), @Transform(({ value }) => {, @IsBoolean() |
| `q` | `string` | No | @IsOptional(), @IsString() |
| `dedupe` | `boolean` | No | @IsOptional(), @Transform(({ value }) => {, @IsBoolean() |

### `AdminPasswordUpdateDto`

`AdminPasswordUpdateDto` from `src/superadmin/dto/adminpasswordupdate.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `adminid` | `string` | Yes | @IsNotEmpty(), @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)) |
| `newpassword` | `string` | Yes | @IsNotEmpty(), @IsString(), @MinLength(6), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)) |
| `confirmpassword` | `string` | Yes | @IsNotEmpty(), @IsString(), @Match('newpassword', { message: 'confirmpassword must match newpassword' }), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)) |

### `AdminRenewVehiclesDto`

`AdminRenewVehiclesDto` from `src/admin/dto/admin-transactions.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `userId` | `number` | Yes | @Type(() => Number), @IsInt(), @Min(1) |
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayMinSize(1), @Type(() => Number), @IsInt({ each: true }) |
| `paymentMode` | `PaymentMode` | No | @IsOptional(), @IsEnum(PaymentMode) |
| `reference` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `amountOverride` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+(\.\d{1,2})?$/, { message: 'amountOverride must be a valid decimal string (e.g., "150.00")' }) |

### `AdminTelemetryLogsDto`

`AdminTelemetryLogsDto` from `src/admin/dto/admin-telemetry-logs.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @Max(500) |
| `beforeId` | `string` | No | @IsOptional(), @IsString() |
| `from` | `string` | No | @IsOptional(), @IsDateString() |
| `to` | `string` | No | @IsOptional(), @IsDateString() |
| `vehicleId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `imei` | `string` | No | @IsOptional(), @IsString() |
| `packetType` | `string` | No | @IsOptional(), @IsString(), @IsIn(['LOCATION', 'HISTORY', 'ALARM', 'HEARTBEAT', 'COMMAND', 'EVENT', 'UNKNOWN']) |

### `AdminUpdateTicketStatusDto`

`AdminUpdateTicketStatusDto` from `src/admin/dto/admin-update-ticket-status.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `status` | `TicketStatusEnum` | Yes | @IsEnum(TicketStatusEnum) |

### `AppNotifyTemplateDto`

`AppNotifyTemplateDto` from `src/superadmin/dto/appnotifytempletes.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `notifySubject` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @Length(2, 120) |
| `message` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(10000) |

### `AssignDriverVehicleDto`

`AssignDriverVehicleDto` from `src/user/dto/assign-driver-vehicle.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `vehicleId` | `number` | Yes | @ToRequiredInt(), @IsNumber() |

### `AssignSubUserVehiclesDto`

`AssignSubUserVehiclesDto` from `src/user/dto/subusers/assign-subuser-vehicles.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayNotEmpty(), @IsInt({ each: true }), @Min(1, { each: true }) |

### `BulkReverseGeocodeDto`

`BulkReverseGeocodeDto` — see `src/geocoding/dto/reverse-geocode.dto.ts` (no simple public fields detected).

### `CalendarDayDto`

`CalendarDayDto` from `src/superadmin/dto/calendar.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `message` | `'date must be in YYYY-MM-DD format',` | Yes | @IsString(), @Matches(/^\d{4}-\d{2}-\d{2}$/, { |
| `date` | `string` | Yes |  |
| `types` | `string` | No | @IsOptional(), @IsString(), @Validate(IsValidEventTypes) |
| `rk` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+$/, { message: 'rk must be a numeric string' }) |

### `CalendarRangeDto`

`CalendarRangeDto` from `src/superadmin/dto/calendar.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `message` | `'from must be in YYYY-MM-DD format',` | Yes | @IsString(), @Matches(/^\d{4}-\d{2}-\d{2}$/, { |
| `from` | `string` | Yes |  |
| `message` | `'to must be in YYYY-MM-DD format',` | Yes | @IsString(), @Matches(/^\d{4}-\d{2}-\d{2}$/, { |
| `to` | `string` | Yes | @Validate(IsValidDateRange) |
| `types` | `string` | No | @IsOptional(), @IsString(), @Validate(IsValidEventTypes) |
| `rk` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d+$/, { message: 'rk must be a numeric string' }) |

### `CompanyDto`

`CompanyDto` from `src/admin/dto/company.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |

### `CreateAdminDto`

`CreateAdminDto` from `src/superadmin/dto/admin.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `email` | `string` | No | @IsOptional(), @IsEmail(), @Transform(({ value }) => String(value).trim().toLowerCase()) |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => value?.toString().trim()) |
| `mobileNumber` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => value?.toString().trim()) |
| `username` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `password` | `string` | Yes | @IsString(), @MinLength(6) |
| `companyName` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `address` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `country` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `state` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `city` | `string` | Yes | @IsString(), @Transform(({ value }) => String(value).trim()) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => value?.toString().trim()) |
| `credits` | `string` | No | @IsOptional(), @IsString() |

### `CreateAgentCommandDto`

`CreateAgentCommandDto` from `src/agent/dto/create-agent-command.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `channel` | `'WEB' \| 'API' \| 'WHATSAPP' \| 'WORKFLOW'` | No | @IsString(), @MaxLength(1000), @IsOptional(), @IsEnum(['WEB', 'API', 'WHATSAPP', 'WORKFLOW']) |
| `payload` | `StructuredCommandPayload` | No | @IsOptional(), @ValidateNested(), @Type(() => StructuredCommandPayload) |
| `metadata` | `Record<string, any>` | No | @IsOptional(), @IsObject() |

### `CreateBugReportDto`

`CreateBugReportDto` from `src/bug-report/dto/create-bug-report.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `category` | `string` | No | @IsString(), @Transform(trimRequiredString), @IsNotEmpty(), @MinLength(5), @MaxLength(3000), @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(80) |
| `severity` | `BugReportSeverity` | No | @IsOptional(), @Transform(({ value }) => {, @IsEnum(BugReportSeverity) |
| `pageUrl` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(2000) |
| `route` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(500) |
| `title` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(300) |
| `screenshotDataUrl` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @Validate(ScreenshotDataUrlConstraint), @Validate(ScreenshotDataUrlSizeConstraint) |
| `uploadedScreenshotDataUrl` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @Validate(ScreenshotDataUrlConstraint), @Validate(ScreenshotDataUrlSizeConstraint) |
| `browser` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `os` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `device` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `screen` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `network` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `app` | `Record<string, any>` | No | @IsOptional(), @IsObject() |
| `recentErrors` | `any[]` | No | @IsOptional(), @IsArray(), @ArrayMaxSize(20) |
| `stepsToReproduce` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(2000) |
| `expectedBehavior` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(2000) |
| `actualBehavior` | `string` | No | @IsOptional(), @IsString(), @Transform(trimOptionalString), @MaxLength(2000) |
| `extra` | `Record<string, any>` | No | @IsOptional(), @IsObject() |

### `CreateDashboardDto`

`CreateDashboardDto` from `src/user/dto/dashboard.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty() |

### `CreateDeviceDto`

`CreateDeviceDto` from `src/admin/dto/createdevice.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `imei` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(5, 20), @Matches(/^\d+$/, { message: "imei must contain digits only" }) |
| `deviceTypeId` | `number` | Yes | @Transform(({ value }) => {, @IsInt(), @Min(1) |

### `CreateDriverBulkJobDto`

`CreateDriverBulkJobDto` — see `src/admin/dto/driverbulkjobs.dto.ts` (no simple public fields detected).

### `CreateDriverDto`

`CreateDriverDto` from `src/admin/dto/createdriver.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MaxLength(120) |
| `mobilePrefix` | `string` | Yes | @IsString(), @MaxLength(10) |
| `mobile` | `string` | Yes | @IsString(), @MaxLength(20) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `primaryUserid` | `string \| number` | Yes | @IsString() |
| `username` | `string` | Yes | @IsString(), @MaxLength(50) |
| `password` | `string` | Yes | @IsString(), @MaxLength(100) |
| `countryCode` | `string` | Yes | @IsString(), @MaxLength(5) |
| `stateCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `city` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `address` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(20) |

### `CreateGeofenceDto`

`CreateGeofenceDto` from `src/user/dto/geofence.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `type` | `GeofenceType` | Yes | @IsEnum(GeofenceType) |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `geodata` | `GeofenceGeoData` | No | @IsObject(), @IsOptional() |

### `CreateInventoryBulkJobDto`

`CreateInventoryBulkJobDto` from `src/admin/dto/inventorybulkjobs.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `deviceTypeId` | `string` | No | @IsDefined(), @IsString(), @Transform(({ value }) => trim(value)), @IsNotEmpty(), @IsIn(['devices', 'simcards', 'both']), @IsOptional(), @IsString(), @Transform(({ value }) => trim(value)) |
| `providerId` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => trim(value)) |

### `CreateLandmarkBulkJobDto`

`CreateLandmarkBulkJobDto` from `src/user/dto/landmarkbulkjobs.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `geofenceRows` | `GeofenceBulkRowDto[]` | No | @IsDefined(), @IsEnum(LandmarkEntityType), @IsOptional(), @IsArray(), @ValidateNested({ each: true }), @Type(() => GeofenceBulkRowDto) |
| `poiRows` | `PoiBulkRowDto[]` | No | @IsOptional(), @IsArray(), @ValidateNested({ each: true }), @Type(() => PoiBulkRowDto) |
| `routeRows` | `RouteBulkRowDto[]` | No | @IsOptional(), @IsArray(), @ValidateNested({ each: true }), @Type(() => RouteBulkRowDto) |

### `CreatePoiDto`

`CreatePoiDto` from `src/user/dto/poi.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `category` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `iconSlug` | `string` | No | @IsString(), @IsOptional() |
| `toleranceMeters` | `number` | No | @IsNumber(), @IsOptional(), @Min(0) |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `coordinates` | `PoiCoordinatesDto` | Yes | @IsObject(), @ValidateNested(), @Type(() => PoiCoordinatesDto) |

### `CreatePricingPlanDto`

`CreatePricingPlanDto` from `src/admin/dto/createpricingplan.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `durationDays` | `number` | Yes | @IsInt(), @Min(1) |
| `price` | `number` | Yes | @IsNumber(), @Min(0) |
| `currency` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(3, 3), @Matches(/^[A-Z]{3}$/, { message: "currency must be a 3-letter ISO code" }) |

### `CreateRouteDto`

`CreateRouteDto` from `src/user/dto/route.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `toleranceMeters` | `number` | No | @IsNumber(), @IsOptional(), @Min(1) |
| `geodata` | `RouteGeoData` | No | @IsObject(), @IsOptional() |

### `CreateShareTrackLinkDto`

`CreateShareTrackLinkDto` from `src/user/dto/sharetracklinks/create-sharetracklink.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayMinSize(1), @toIntArray(), @IsInt({ each: true }) |
| `expiryAt` | `string` | Yes | @IsDateString() |
| `isGeofence` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `isHistory` | `boolean` | No | @IsOptional(), @IsBoolean() |

### `CreateSubUserDto`

`CreateSubUserDto` from `src/user/dto/subusers/create-subuser.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MinLength(2) |
| `username` | `string` | No | @IsOptional(), @IsString(), @MinLength(3) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString() |
| `mobileNumber` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d{7,15}$/, { message: 'mobileNumber must be 7-15 digits' }) |
| `password` | `string` | No | @IsOptional(), @IsString(), @MinLength(6) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

### `CreateSuperAdminDto`

`CreateSuperAdminDto` from `src/auth/dto/superadmin.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString() |
| `email` | `string` | Yes | @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsString() |
| `mobileNumber` | `string` | Yes | @IsString() |
| `username` | `string` | Yes | @IsString() |
| `password` | `string` | Yes | @IsString(), @MinLength(6) |
| `companyName` | `string` | Yes | @IsString() |
| `website` | `string` | No | @IsOptional(), @IsString() |
| `address` | `string` | Yes | @IsString() |
| `country` | `string` | Yes | @IsString() |
| `state` | `string` | Yes | @IsString() |
| `city` | `string` | Yes | @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

### `CreateTeamMemberDto`

`CreateTeamMemberDto` from `src/admin/dto/createteam.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `email` | `string` | Yes | @IsEmail(), @IsNotEmpty() |
| `mobilePrefix` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `mobileNumber` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `username` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `password` | `string` | Yes | @IsString(), @IsNotEmpty() |

### `CreateUserBulkJobDto`

`CreateUserBulkJobDto` — see `src/admin/dto/userbulkjobs.dto.ts` (no simple public fields detected).

### `CreateUserDriverDto`

`CreateUserDriverDto` from `src/user/dto/create-driver.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MaxLength(120) |
| `mobilePrefix` | `string` | Yes | @IsString(), @MaxLength(10) |
| `mobile` | `string` | Yes | @IsString(), @MaxLength(20) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `username` | `string` | Yes | @IsString(), @MaxLength(50) |
| `password` | `string` | Yes | @IsString(), @MaxLength(100) |
| `countryCode` | `string` | Yes | @IsString(), @MaxLength(5) |
| `stateCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `city` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `address` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(20) |

### `CreateUserDto`

`CreateUserDto` from `src/admin/dto/createuser.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString() |
| `email` | `string` | No | @IsOptional(), @IsString() |
| `mobilePrefix` | `string` | Yes | @IsString() |
| `mobileNumber` | `string` | Yes | @IsString() |
| `username` | `string` | Yes | @IsString() |
| `password` | `string` | Yes | @IsString() |
| `companyName` | `string` | No | @IsOptional(), @IsString() |
| `address` | `string` | Yes | @IsString() |
| `countryCode` | `string` | Yes | @IsString() |
| `stateCode` | `string` | No | @IsOptional(), @IsString() |
| `city` | `string` | No | @IsOptional(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

### `CreateVehicleBulkJobDto`

`CreateVehicleBulkJobDto` — see `src/admin/dto/vehiclebulkjobs.dto.ts` (no simple public fields detected).

### `CreateVehicleDto`

`CreateVehicleDto` from `src/admin/dto/createvehicle.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `vin` | `string` | No | @IsDefined(), @IsString(), @Transform(({ value }) => trim(value)), @IsNotEmpty(), @MaxLength(120), @IsOptional(), @IsString(), @Transform(({ value }) => trim(value)), @MaxLength(64) |
| `plateNumber` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => trim(value)), @MaxLength(32) |

### `CreateVehicleSensorDto`

`CreateVehicleSensorDto` from `src/user/dto/sensors/create-vehicle-sensor.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @MinLength(2) |
| `unit` | `string` | No | @IsOptional(), @IsString() |
| `icon` | `string` | No | @IsOptional(), @IsString() |
| `code` | `string` | Yes | @IsString(), @MinLength(5) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

### `CreditsUpdateDto`

`CreditsUpdateDto` from `src/superadmin/dto/creditassign.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `credits` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `activity` | `string` | Yes | @IsNotEmpty(), @IsString() |

### `CustomCommandDto`

`CustomCommandDto` from `src/superadmin/dto/customcommand.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `deviceTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `commandTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `command` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(500) // command templates can be long |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

### `CustomCommandsQueryDto`

`CustomCommandsQueryDto` from `src/superadmin/dto/custom-commands-query.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `deviceTypeId` | `string` | No | @IsOptional(), @IsString() |
| `commandTypeId` | `string` | No | @IsOptional(), @IsString() |
| `activeOnly` | `string` | No | @IsOptional(), @IsString() |
| `rk` | `string` | No | @IsOptional(), @IsString() |

### `DashboardActivityLogsDto`

`DashboardActivityLogsDto` from `src/superadmin/dto/dashboard-activity-logs.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(5), @Max(50) |
| `cursorId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `actorId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `from` | `string` | No | @IsOptional(), @IsDateString() |
| `to` | `string` | No | @IsOptional(), @IsDateString() |
| `rk` | `string` | No | @IsOptional(), @IsString() |

### `DeviceAndSimDto`

`DeviceAndSimDto` from `src/admin/dto/deviceandsim.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `imei` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(5, 20), @Matches(/^\d+$/, { message: "imei must contain digits only" }) |
| `deviceTypeId` | `number` | Yes | @ToInt(), @IsInt(), @Min(1) |
| `simNumber` | `string` | Yes | @ToStringish(), @IsString(), @IsNotEmpty() |
| `imsi` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `providerId` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `iccid` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |

### `DeviceTypeDto`

`DeviceTypeDto` from `src/superadmin/dto/devicetype.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `port` | `number` | Yes | @IsInt(), @Min(1), @Max(65535) |
| `manufacturer` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |
| `protocol` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |
| `firmwareVersion` | `string \| null` | No | @IsOptional(), @IsString(), @Length(1, 120) |

### `DocumentTypeDto`

`DocumentTypeDto` from `src/superadmin/dto/documenttype.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `docFor` | `DocForDto` | Yes | @IsEnum(DocForDto, { message: "docFor must be one of: USER, DRIVER, VEHICLE" }) |

### `EmailTemplateDto`

`EmailTemplateDto` from `src/superadmin/dto/emailtemplate.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `emailSubject` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @Length(2, 120) |
| `message` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(10000) |

### `ExecutionIdParamDto`

`ExecutionIdParamDto` — see `src/agent/dto/execution-id-param.dto.ts` (no simple public fields detected).

### `ForgotPasswordDto`

`ForgotPasswordDto` from `src/auth/dto/forgot-password.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `identifier` | `string` | Yes | @IsNotEmpty(), @IsString() |

### `GoogleLoginDto`

`GoogleLoginDto` from `src/auth/dto/google-login.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `code` | `string` | Yes | @IsNotEmpty(), @IsString() |

### `ListShareTrackLinksDto`

`ListShareTrackLinksDto` from `src/user/dto/sharetracklinks/list-sharetracklinks.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `search` | `string` | No | @IsOptional(), @IsString() |
| `page` | `string` | No | @IsOptional(), @IsString() |
| `limit` | `string` | No | @IsOptional(), @IsString() |

### `ListThirdPartyIntegrationsQueryDto`

`ListThirdPartyIntegrationsQueryDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `scope` | `IntegrationScope` | No | @IsOptional(), @IsEnum(IntegrationScope) |
| `adminId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @ValidateIf((o) => o.scope === 'ADMIN') |
| `category` | `IntegrationCategory` | No | @IsOptional(), @IsEnum(IntegrationCategory) |
| `provider` | `IntegrationProvider` | No | @IsOptional(), @IsEnum(IntegrationProvider) |

### `ListWhatsAppTemplatesQueryDto`

`ListWhatsAppTemplatesQueryDto` from `src/superadmin/dto/whatsapp-templates.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `type` | `string` | No | @IsOptional(), @IsString() |
| `languageCode` | `string` | No | @IsOptional(), @IsString() |
| `isActive` | `boolean` | No | @IsOptional(), @Transform(({ value }) => {, @IsBoolean() |
| `rk` | `string` | No | @IsOptional() |

### `LoginDto`

`LoginDto` from `src/auth/dto/login.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `identifier` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `password` | `string` | Yes | @IsNotEmpty(), @IsString() |

### `MapEventsQueryDto`

`MapEventsQueryDto` from `src/superadmin/dto/map-events.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `limit` | `string` | No | @IsOptional(), @IsNumberString() |
| `beforeId` | `string` | No | @IsOptional(), @IsString() |
| `from` | `string` | No | @IsOptional(), @IsISO8601() |
| `to` | `string` | No | @IsOptional(), @IsISO8601() |
| `source` | `string` | No | @IsOptional(), @IsIn(['SYSTEM', 'GEOFENCE', 'OVERSPEED', 'IGNITION', 'REMINDER', 'SENSOR', 'DRIVER', 'COMMAND']) |
| `severity` | `string` | No | @IsOptional(), @IsIn(['INFO', 'WARNING', 'CRITICAL']) |

### `NotificationsQueryDto`

`NotificationsQueryDto` from `src/superadmin/dto/notifications.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `limit` | `string` | No | @IsOptional(), @IsNumberString() |
| `beforeId` | `string` | No | @IsOptional(), @IsNumberString() |
| `unreadOnly` | `string` | No | @IsOptional(), @IsBooleanString() |

### `PolicyDto`

`PolicyDto` from `src/superadmin/dto/policy.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `PolicyType` | `PolicyTypeDto` | Yes | @IsEnum(PolicyTypeDto, { message: "type must be one of: PRIVACY_POLICY, SERVICE_TERMS, COOKIES, REFUND" }) |
| `PolicyText` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(200000) // big enterprise content, adjust if needed |

### `ProfileDto`

`ProfileDto` from `src/superadmin/dto/profile.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `mobileNumber` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `addressLine` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `countryCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `stateCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `cityName` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

### `QuickDeviceDto`

`QuickDeviceDto` from `src/admin/dto/quickdevice.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `imei` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(4, 20), @Matches(/^\d+$/, { message: "imei must contain digits only" }) |
| `deviceTypeId` | `number` | Yes | @IsInt(), @Min(1) |
| `simNumber` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(5, 30), @Matches(/^\d+$/, { message: "simNumber must contain digits only" }) |

### `RecordManualTransactionDto`

`RecordManualTransactionDto` from `src/superadmin/dto/record-manual-transaction.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `adminId` | `number` | Yes | @Type(() => Number), @IsInt() |
| `amount` | `string` | Yes | @IsString(), @Matches(/^\d+(\.\d{1,2})?$/), @MaxLength(12, { message: 'Amount must not exceed 9999999999.99' }) |
| `reference` | `string` | No | @IsOptional(), @IsString(), @MaxLength(100) |
| `paymentMode` | `PaymentMode` | No | @IsOptional(), @IsEnum(PaymentMode) |

### `RegisterPushTokenDto`

`RegisterPushTokenDto` from `src/auth/dto/push-token.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `token` | `string` | Yes | @IsString(), @IsNotEmpty({ message: 'token must not be empty' }), @Transform(({ value }) => String(value).trim()) |
| `platform` | `string` | No | @IsOptional(), @IsString(), @IsIn(['web', 'android', 'ios']) |
| `deviceId` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `userAgent` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

### `RemovePushTokenDto`

`RemovePushTokenDto` from `src/auth/dto/push-token.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `token` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `deviceId` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

### `ReplySupportTicketDto`

`ReplySupportTicketDto` from `src/superadmin/dto/reply-support-ticket.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `message` | `string` | No | @IsOptional(), @IsString(), @MaxLength(5000), @Matches(MEANINGFUL_TEXT, { message: 'Message must contain at least one letter or number' }) |

### `ResetPasswordDto`

`ResetPasswordDto` from `src/auth/dto/reset-password.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `token` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `newPassword` | `string` | Yes | @IsNotEmpty(), @IsString(), @MinLength(6), @MaxLength(35) |

### `RotateThirdPartyIntegrationSecretDto`

`RotateThirdPartyIntegrationSecretDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `secretJson` | `any` | Yes | @IsNotEmpty({ message: 'secretJson must not be empty' }) |

### `RunVehicleSensorDto`

`RunVehicleSensorDto` from `src/user/dto/sensors/run-vehicle-sensor.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `code` | `string` | Yes | @IsString(), @MinLength(5) |
| `payload` | `Record<string, unknown>` | Yes | @IsObject() |

### `SendCommandBulkDto`

`SendCommandBulkDto` from `src/user/dto/send-command-bulk.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `mode` | `SendCommandBulkMode` | Yes | @IsEnum(SendCommandBulkMode) |
| `vehicleIds` | `number[]` | No | @ValidateIf((o) => o.mode === SendCommandBulkMode.SELECTED && !o.items?.length), @IsOptional(), @IsArray(), @ArrayMinSize(1), @IsInt({ each: true }), @Type(() => Number) |
| `command` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |
| `items` | `SendCommandBulkItem[]` | No | @IsOptional(), @IsArray(), @ArrayMinSize(1), @ValidateNested({ each: true }), @Type(() => SendCommandBulkItem) |
| `note` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |

### `SendDeviceCommandDto`

`SendDeviceCommandDto` from `src/superadmin/dto/send-device-command.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `command` | `string` | Yes | @IsString(), @IsNotEmpty(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @MaxLength(500) |
| `note` | `string` | No | @IsOptional(), @IsString(), @MaxLength(500) |

### `ServerActionDto`

`ServerActionDto` from `src/superadmin/server/dto/server-action.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `componentId` | `ServerActionComponentId` | Yes | @IsIn(SERVER_COMPONENT_IDS) |
| `action` | `ServerActionType` | Yes | @IsIn(SERVER_ACTIONS), @Validate(ServerActionRulesConstraint) |

### `SimCardDto`

`SimCardDto` from `src/admin/dto/sim.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `simNumber` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `imsi` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `providerId` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `iccid` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `isActive` | `boolean` | No | @IsOptional() |
| `status` | `'IN_STOCK' \| 'IN_USE' \| 'IN_SCRAP'` | No | @IsOptional(), @ToStringish(), @IsString() |

### `SimProviderDto`

`SimProviderDto` from `src/superadmin/dto/simprociders.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80) |
| `countryCode` | `string` | Yes | @IsString(), @IsNotEmpty(), @Matches(/^[A-Z]{2}$/, { message: "countryCode must be 2 uppercase letters (e.g. IN, NZ)" }) |
| `apnName` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `apnUser` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `apnPassword` | `string \| null` | No | @IsOptional(), @IsString(), @MaxLength(120) |

### `SmtpSettingDto`

`SmtpSettingDto` from `src/superadmin/dto/smtp.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `senderName` | `string` | No | @IsOptional(), @IsString() |
| `host` | `string` | No | @IsOptional(), @IsString() |
| `port` | `string \| number` | No | @IsOptional(), @IsOptional(), @Matches(/^\d+$/,{message: 'port must be a numeric string or number'}) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `type` | `SmtpSecurity` | No | @IsOptional(), @IsEnum(SmtpSecurity) |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `replyTo` | `string` | No | @IsOptional(), @IsEmail() |
| `isActive` | `string \| boolean` | No | @IsOptional(), @IsOptional(), @Matches(/^(true\|false)$/i, { message: 'isActive must be a boolean string ("true" or "false")' }) |

### `SoftwareConfigDto`

`SoftwareConfigDto` from `src/superadmin/dto/softwareconfig.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `geocodingPrecision` | `GeocodingPrecisionDto` | No | @IsOptional(), @IsEnum(GeocodingPrecisionDto) |
| `backupDays` | `number` | No | @IsOptional(), @IsInt(), @Min(0) |
| `allowDemoLogin` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `allowSignup` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `signupCredits` | `number` | No | @IsOptional(), @IsInt(), @Min(0), @Max(2_000_000_000, { message: 'signupCredits must not exceed 2,000,000,000' }) |

### `SslInstallDto`

`SslInstallDto` from `src/ssl/dto/ssl.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `domain` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `action` | `SslAction` | Yes | @IsEnum(SslAction) |
| `email` | `string` | No | @IsOptional(), @IsString() |
| `backendProxyPass` | `string` | No | @IsOptional(), @IsString() |

### `SyncWhatsAppTemplatesDto`

`SyncWhatsAppTemplatesDto` from `src/superadmin/dto/whatsapp-templates.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `templateIds` | `number[]` | No | @IsOptional(), @IsArray(), @IsInt({ each: true }), @Min(1, { each: true }), @Type(() => Number) |
| `dryRun` | `boolean` | No | @IsOptional(), @IsBoolean() |

### `SystemVariableDto`

`SystemVariableDto` from `src/superadmin/dto/systemvariable.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `message` | `"name must start with a letter and contain only letters, numbers, and underscore",` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 80), @Matches(/^[A-Za-z][A-Za-z0-9_]*$/, { |
| `name` | `string` | Yes |  |
| `initialValue` | `string` | Yes | @IsString(), @IsNotEmpty(), @MaxLength(500) |

### `TestEmailDto`

`TestEmailDto` from `src/auth/dto/email-test.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `subject` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `body` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

### `TestFcmIntegrationDto`

`TestFcmIntegrationDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `token` | `string` | Yes | @IsString(), @IsNotEmpty({ message: 'token must not be empty' }), @Transform(({ value }) => String(value).trim()) |
| `title` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `body` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `data` | `any` | No | @IsOptional() |

### `TestFcmToMeDto`

`TestFcmToMeDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `title` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `body` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

### `TestOpenRouterIntegrationDto`

`TestOpenRouterIntegrationDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `model` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `prompt` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

### `TestPushDto`

`TestPushDto` from `src/auth/dto/push-token.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `title` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `body` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

### `TestWhatsAppIntegrationDto`

`TestWhatsAppIntegrationDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `phoneNumber` | `string` | Yes | @IsString(), @IsNotEmpty({ message: 'phoneNumber must not be empty' }), @Transform(({ value }) => String(value).trim()) |
| `mode` | `'template' \| 'custom'` | No | @IsOptional(), @IsString(), @Transform(({ value }) => String(value ?? 'template').trim().toLowerCase()) |
| `templateName` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `languageCode` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `message` | `string` | No | @ValidateIf((o) => o.mode === 'custom'), @IsString(), @IsNotEmpty({ message: 'message must not be empty when mode is custom' }), @Transform(({ value }) => (value ? String(value).trim() : value)) |

### `TopbarSearchQueryDto`

`TopbarSearchQueryDto` from `src/topbar-search/dto/topbar-search.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `q` | `string` | Yes | @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @IsString(), @IsNotEmpty(), @MinLength(2), @MaxLength(80) |
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @Max(30) |

### `UnassignSubUserVehiclesDto`

`UnassignSubUserVehiclesDto` from `src/user/dto/subusers/unassign-subuser-vehicles.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `vehicleIds` | `number[]` | Yes | @IsArray(), @ArrayNotEmpty(), @IsInt({ each: true }), @Min(1, { each: true }) |

### `UpdateAdminDto`

`UpdateAdminDto` from `src/superadmin/dto/updateadmin.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `mobileNumber` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `addressLine` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `countryCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `stateCode` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `cityName` | `string` | Yes | @IsNotEmpty(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @IsString() |

### `UpdateCompanyDto`

`UpdateCompanyDto` from `src/admin/dto/updatecompany.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `websiteUrl` | `string` | No | @IsOptional(), @IsUrl({}, { message: 'websiteUrl must be a valid URL' }) |
| `customDomain` | `string` | No | @IsOptional(), @IsString() |
| `socialLinks` | `Record<string, string>` | No | @IsOptional(), @IsObject() |
| `primaryColor` | `string` | No | @IsOptional(), @IsString() |
| `secondaryColor` | `string` | No | @IsOptional(), @IsString() |
| `navbarColor` | `string` | No | @IsOptional(), @IsString() |

### `UpdateDashboardDto`

`UpdateDashboardDto` from `src/user/dto/dashboard.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `config` | `any` | No | @IsOptional() |
| `version` | `number` | Yes | @IsInt(), @Min(1) |

### `UpdateDeviceDto`

`UpdateDeviceDto` from `src/admin/dto/updatedevice.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `simId` | `number \| null` | No | @IsOptional(), @IsInt(), @Min(0) |
| `deviceTypeId` | `number \| null` | No | @IsOptional(), @IsInt(), @Min(1) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `message` | `"status must be one of: IN_STOCK, IN_USE, IN_SCRAP",` | No | @IsOptional(), @IsEnum(DeviceInventoryStatusDto, { |
| `status` | `DeviceInventoryStatusDto` | No |  |

### `UpdateDocDto`

`UpdateDocDto` from `src/superadmin/dto/updatedoc.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `title` | `string` | No | @IsOptional(), @IsString(), @MaxLength(255) |
| `docTypeId` | `number` | No | @IsOptional(), @IsInt(), @Min(1) |
| `fileName` | `string` | No | @IsOptional(), @IsString(), @MaxLength(255) |
| `description` | `string` | No | @IsOptional(), @IsString(), @MaxLength(1000) |
| `tags` | `string` | No | @IsOptional(), @IsString(), @MaxLength(2000) |
| `associateType` | `AssociateTypeDto` | No | @IsOptional(), @IsEnum(AssociateTypeDto, { message: 'associateType must be one of: USER, VEHICLE, DRIVER' }) |
| `associateId` | `number` | No | @IsOptional(), @IsInt(), @Min(1) |
| `expiryAt` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `isVisible` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `isVisibleDriver` | `boolean` | No | @IsOptional(), @IsBoolean() |

### `UpdateDriverDto`

`UpdateDriverDto` from `src/admin/dto/updatedriver.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `mobile` | `string` | No | @IsOptional(), @IsString(), @MaxLength(20) |
| `email` | `string` | No | @IsOptional(), @IsEmail(), @MaxLength(254) |
| `username` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `password` | `string` | No | @IsOptional(), @IsString(), @MaxLength(100) |
| `countryCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(5) |
| `StateCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `city` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `address` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(12) |
| `isactive` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `attributes` | `Record<string, any> \| string` | No | @IsOptional() |

### `UpdateGeofenceDto`

`UpdateGeofenceDto` from `src/user/dto/geofence.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsString(), @IsOptional(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `type` | `GeofenceType` | No | @IsEnum(GeofenceType), @IsOptional() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `geodata` | `GeofenceGeoData` | No | @IsObject(), @IsOptional() |

### `UpdatePasswordDto`

`UpdatePasswordDto` from `src/superadmin/dto/updatepassword.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `currentPassword` | `string` | Yes | @IsString(), @IsNotEmpty() |
| `newPassword` | `string` | Yes | @IsString(), @IsNotEmpty(), @MinLength(6), @MaxLength(72) |

### `UpdatePoiDto`

`UpdatePoiDto` from `src/user/dto/poi.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsString(), @IsOptional(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `category` | `string` | No | @IsString(), @IsOptional() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `iconSlug` | `string` | No | @IsString(), @IsOptional() |
| `toleranceMeters` | `number \| null` | No | @IsNumber(), @IsOptional(), @Min(0) |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `coordinates` | `PoiCoordinatesDto` | No | @IsObject(), @IsOptional(), @ValidateNested(), @Type(() => PoiCoordinatesDto) |

### `UpdateRouteDto`

`UpdateRouteDto` from `src/user/dto/route.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsString(), @IsOptional(), @MinLength(2) |
| `description` | `string` | No | @IsString(), @IsOptional() |
| `color` | `string` | No | @IsString(), @IsOptional() |
| `isActive` | `boolean` | No | @IsBoolean(), @IsOptional() |
| `toleranceMeters` | `number` | No | @IsNumber(), @IsOptional(), @Min(1) |
| `geodata` | `RouteGeoData` | No | @IsObject(), @IsOptional() |

### `UpdateSettingsStateDto`

`UpdateSettingsStateDto` from `src/superadmin/dto/usersetting.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `language` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_LANGUAGES as unknown as string[], { message: "Invalid language" }) |
| `layoutDirection` | `LayoutDirectionDto` | No | @IsOptional(), @IsEnum(LayoutDirectionDto) |
| `dateFormat` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @IsIn(ALLOWED_DATE_FORMATS as unknown as string[], { message: "Invalid dateFormat" }) |
| `use24Hour` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `theme` | `ThemeModeDto` | No | @IsOptional(), @IsEnum(ThemeModeDto) |
| `timezoneOffset` | `string` | No | @IsOptional(), @IsString(), @IsIn(ALLOWED_TIMEZONE_OFFSETS as unknown as string[], { message: "Invalid timezoneOffset" }) |
| `units` | `UnitsDto` | No | @IsOptional(), @IsEnum(UnitsDto) |
| `defaultLat` | `number` | No | @IsOptional() |
| `defaultLon` | `number` | No | @IsOptional() |
| `mapZoom` | `number` | No | @IsOptional() |

### `UpdateShareTrackLinkDto`

`UpdateShareTrackLinkDto` from `src/user/dto/sharetracklinks/update-sharetracklink.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `vehicleIds` | `number[]` | No | @IsOptional(), @IsArray(), @ArrayMinSize(1), @toIntArray(), @IsInt({ each: true }) |
| `expiryAt` | `string` | No | @IsOptional(), @IsDateString() |
| `isGeofence` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `isHistory` | `boolean` | No | @IsOptional(), @IsBoolean() |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

### `UpdateSmtpConfigDto`

`UpdateSmtpConfigDto` from `src/admin/dto/updatesmtpconfig.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `senderName` | `string` | No | @IsOptional(), @IsString() |
| `host` | `string` | No | @IsOptional(), @IsString() |
| `port` | `string \| number` | No | @IsOptional(), @IsOptional(), @Matches(/^\d+$/,{message: 'port must be a numeric string or number'}) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `type` | `SmtpSecurity` | No | @IsOptional(), @IsEnum(SmtpSecurity) |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `replyTo` | `string` | No | @IsOptional(), @IsEmail() |
| `isActive` | `string \| boolean` | No | @IsOptional(), @IsOptional(), @Matches(/^(true\|false)$/i, { message: 'isActive must be a boolean string ("true" or "false")' }) |

### `UpdateSubUserDto`

`UpdateSubUserDto` from `src/user/dto/subusers/update-subuser.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MinLength(2) |
| `username` | `string` | No | @IsOptional(), @IsString(), @MinLength(3) |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString() |
| `mobileNumber` | `string` | No | @IsOptional(), @IsString(), @Matches(/^\d{7,15}$/, { message: 'mobileNumber must be 7-15 digits' }) |
| `password` | `string` | No | @IsOptional(), @IsString(), @MinLength(6) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

### `UpdateSupportTicketStatusDto`

`UpdateSupportTicketStatusDto` from `src/superadmin/dto/update-support-ticket-status.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `status` | `TicketStatusEnum` | Yes | @IsEnum(TicketStatusEnum) |

### `UpdateTeamMemberDto`

`UpdateTeamMemberDto` from `src/admin/dto/updateteam.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `email` | `string` | No | @IsOptional(), @IsEmail() |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString() |
| `mobileNumber` | `string` | No | @IsOptional(), @IsString() |
| `username` | `string` | No | @IsOptional(), @IsString() |
| `password` | `string` | No | @IsOptional(), @IsString() |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

### `UpdateThirdPartyIntegrationDto`

`UpdateThirdPartyIntegrationDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `status` | `IntegrationStatus` | No | @IsOptional(), @IsEnum(IntegrationStatus) |
| `isDefault` | `boolean` | No | @IsOptional(), @Transform(({ value }) =>, @IsBoolean() |
| `priority` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(0) |
| `publicConfig` | `any` | No | @IsOptional() |
| `lastError` | `string` | No | @IsOptional(), @IsString() |

### `UpdateUserDriverDto`

`UpdateUserDriverDto` from `src/user/dto/update-driver.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MaxLength(120) |
| `mobilePrefix` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `mobile` | `string` | No | @IsOptional(), @IsString(), @MaxLength(20) |
| `email` | `string` | No | @IsOptional(), @IsEmail(), @MaxLength(254) |
| `username` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `password` | `string` | No | @IsOptional(), @IsString(), @MaxLength(100) |
| `countryCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(5) |
| `StateCode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `city` | `string` | No | @IsOptional(), @IsString(), @MaxLength(50) |
| `address` | `string` | No | @IsOptional(), @IsString(), @MaxLength(200) |
| `pincode` | `string` | No | @IsOptional(), @IsString(), @MaxLength(12) |
| `isactive` | `string` | No | @IsOptional(), @IsString(), @MaxLength(10) |
| `attributes` | `Record<string, any> \| string` | No | @IsOptional() |

### `UpdateUserDto`

`UpdateUserDto` from `src/admin/dto/updateuser.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `roleId` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `name` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `email` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `mobilePrefix` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `mobileNumber` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `username` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `password` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `companyName` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `address` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `countryCode` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `stateCode` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `city` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `pincode` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |
| `isActive` | `string` | No | @IsOptional(), @ToStringish(), @IsString() |

### `UpdateUserVehicleDto`

`UpdateUserVehicleDto` from `src/user/dto/update-vehicle.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @ToTrimmedString(), @IsString() |
| `plateNumber` | `string \| null` | No | @IsOptional(), @ToOptionalNullIfEmptyString(), @IsString() |
| `vin` | `string \| null` | No | @IsOptional(), @ToOptionalNullIfEmptyString(), @IsString() |
| `vehicleTypeId` | `number` | No | @IsOptional(), @ToOptionalInt(), @IsNumber() |
| `gmtOffset` | `string \| null` | No | @IsOptional(), @ToOptionalNullIfEmptyString(), @Matches(/^[+-](0\d\|1[0-4]):[0-5]\d$/) |
| `vehicleMeta` | `Record<string, any>` | No | @IsOptional(), @ToOptionalJSON(), @IsObject() |

### `UpdateVehicleConfigDto`

`UpdateVehicleConfigDto` from `src/admin/dto/update-vehicle-config.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `speedVariation` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `distanceVariation` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `odometer` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `engineHours` | `number` | No | @IsOptional(), @ToOptionalFloat(), @IsNumber(), @Min(0) |
| `ignitionSource` | `'ACC' \| 'MOTION'` | No | @IsOptional(), @ToOptionalUpper(), @IsIn(['ACC', 'MOTION']) |

### `UpdateVehicleDto`

`UpdateVehicleDto` from `src/admin/dto/updatevehicle.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString() |
| `vin` | `string` | No | @IsOptional(), @IsString() |
| `plateNumber` | `string` | No | @IsOptional(), @IsString() |
| `deviceid` | `number` | No | @IsOptional(), @ToOptionalInt(), @IsNumber() |
| `vehicleTypeId` | `number` | No | @IsOptional(), @ToOptionalInt(), @IsNumber() |
| `planid` | `number` | No | @IsOptional(), @ToOptionalInt(), @IsNumber() |
| `gmtOffset` | `string` | No | @IsOptional(), @ToTrimmedString(), @Matches(/^[+-](0\d\|1[0-4]):[0-5]\d$/) |
| `isActive` | `boolean` | No | @IsOptional(), @ToOptionalBool(), @IsBoolean() |
| `vehicleMeta` | `Record<string, any>` | No | @IsOptional(), @ToOptionalJSON(), @IsObject() |

### `UpdateVehicleSensorDto`

`UpdateVehicleSensorDto` from `src/user/dto/sensors/update-vehicle-sensor.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | No | @IsOptional(), @IsString(), @MinLength(2) |
| `unit` | `string` | No | @IsOptional(), @IsString() |
| `icon` | `string` | No | @IsOptional(), @IsString() |
| `code` | `string` | No | @IsOptional(), @IsString(), @MinLength(5) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

### `UpdateWhatsAppTemplateDto`

`UpdateWhatsAppTemplateDto` from `src/superadmin/dto/whatsapp-templates.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `title` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @Length(2, 200) |
| `body` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(1024) |
| `category` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(50) |
| `languageCode` | `string` | No | @IsOptional(), @IsString(), @IsNotEmpty(), @MaxLength(10) |
| `isActive` | `boolean` | No | @IsOptional(), @IsBoolean() |

### `UpsertThirdPartyIntegrationDto`

`UpsertThirdPartyIntegrationDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `scope` | `IntegrationScope` | Yes | @IsEnum(IntegrationScope) |
| `adminId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @ValidateIf((o) => o.scope === 'ADMIN') |
| `category` | `IntegrationCategory` | Yes | @IsEnum(IntegrationCategory) |
| `provider` | `IntegrationProvider` | Yes | @IsEnum(IntegrationProvider) |
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Transform(({ value }) => String(value).trim()) |
| `status` | `IntegrationStatus` | No | @IsOptional(), @IsEnum(IntegrationStatus) |
| `isDefault` | `boolean` | No | @IsOptional(), @Transform(({ value }) =>, @IsBoolean() |
| `priority` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(0) |
| `publicConfig` | `any` | No | @IsOptional() |
| `secretJson` | `any` | No | @IsOptional() |

### `UserActivityLogsDto`

`UserActivityLogsDto` from `src/admin/dto/user-activity-logs.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `limit` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(5), @Max(50) |
| `cursorId` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1) |
| `from` | `string` | No | @IsOptional(), @IsDateString() |
| `to` | `string` | No | @IsOptional(), @IsDateString() |
| `q` | `string` | No | @IsOptional(), @IsString() |
| `actionPrefix` | `string` | No | @IsOptional(), @IsString() |

### `ValidateFtkeyDto`

`ValidateFtkeyDto` from `src/superadmin/dto/ftkey.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `ftkey` | `string` | Yes | @IsString(), @IsNotEmpty() |

### `ValidateGeocodingIntegrationDto`

`ValidateGeocodingIntegrationDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `lat` | `number` | Yes | @Type(() => Number), @IsNumber(), @Min(-90), @Max(90) |
| `lng` | `number` | Yes | @Type(() => Number), @IsNumber(), @Min(-180), @Max(180) |
| `language` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |
| `zoom` | `number` | No | @IsOptional(), @Type(() => Number), @IsInt(), @Min(1), @Max(20) |

### `ValidateGoogleSsoDto`

`ValidateGoogleSsoDto` from `src/superadmin/dto/third-party-integrations.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `redirectUri` | `string` | No | @IsOptional(), @IsString(), @Transform(({ value }) => (value ? String(value).trim() : undefined)) |

### `VehicleTypeDto`

`VehicleTypeDto` from `src/superadmin/dto/vehicletype.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `name` | `string` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 60) |
| `message` | `"slug must be lowercase and hyphen-separated (e.g. snowplow, mini-truck)",` | Yes | @IsString(), @IsNotEmpty(), @Length(2, 60), @Matches(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, { |
| `slug` | `string` | Yes |  |

### `VerifyOtpDto`

`VerifyOtpDto` from `src/verification/dto/verify-otp.dto.ts`

| Field | Type | Required | Validation / decorators |
|---|---|---:|---|
| `otp` | `string` | Yes | @IsString(), @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)), @Length(6, 6, { message: 'OTP must be exactly 6 digits' }), @Matches(/^\d{6}$/, { message: 'OTP must contain only digits' }) |

## Full indexed DTO class list

| DTO/interface | Source | Fields detected |
|---|---|---:|
| `ActivateAdminDto` | `src/superadmin/dto/activateadmin.ts` | 1 |
| `ActivityLogInput` | `src/activity-log/activity-log.service.ts` | 9 |
| `AdminActivityLogsDto` | `src/admin/dto/admin-activity-logs.dto.ts` | 8 |
| `AdminCalendarDayDto` | `src/admin/dto/calendar.dto.ts` | 4 |
| `AdminCalendarRangeDto` | `src/admin/dto/calendar.dto.ts` | 6 |
| `AdminConfigDto` | `src/admin/dto/adminconfig.dto.ts` | 2 |
| `AdminCreateMyTicketDto` | `src/admin/dto/admin-create-my-ticket.dto.ts` | 4 |
| `AdminCreateTicketDto` | `src/admin/dto/admin-create-ticket.dto.ts` | 6 |
| `AdminDashboardSummaryDto` | `src/admin/dto/admin-dashboard-summary.dto.ts` | 4 |
| `AdminEventLogsDto` | `src/admin/dto/admin-event-logs.dto.ts` | 11 |
| `AdminPasswordUpdateDto` | `src/superadmin/dto/adminpasswordupdate.dto.ts` | 3 |
| `AdminRenewVehiclesDto` | `src/admin/dto/admin-transactions.dto.ts` | 5 |
| `AdminReplyMyTicketDto` | `src/admin/dto/admin-reply-my-ticket.dto.ts` | 1 |
| `AdminReplyTicketDto` | `src/admin/dto/admin-reply-ticket.dto.ts` | 1 |
| `AdminTelemetryLogsDto` | `src/admin/dto/admin-telemetry-logs.dto.ts` | 7 |
| `AdminUpdateTicketStatusDto` | `src/admin/dto/admin-update-ticket-status.dto.ts` | 1 |
| `AgentCommand` | `src/agent/interfaces/agent-command.interface.ts` | 10 |
| `AgentCommandEntities` | `src/agent/interfaces/agent-command.interface.ts` | 9 |
| `AgentResponse` | `src/agent/interfaces/agent-response.interface.ts` | 9 |
| `AppNotifyTemplateDto` | `src/superadmin/dto/appnotifytempletes.dto.ts` | 2 |
| `AssignDriverVehicleDto` | `src/user/dto/assign-driver-vehicle.dto.ts` | 1 |
| `AssignSubUserVehiclesDto` | `src/user/dto/subusers/assign-subuser-vehicles.dto.ts` | 1 |
| `AuthResponseDto` | `src/auth/dto/auth-response.dto.ts` | 23 |
| `AuthenticatedBugReportUser` | `src/bug-report/bug-report.service.ts` | 8 |
| `BrandingInspectionResult` | `src/branding/branding-resolver.service.ts` | 12 |
| `BugReportRequestDetails` | `src/bug-report/bug-report.service.ts` | 7 |
| `BulkPointDto` | `src/geocoding/dto/reverse-geocode.dto.ts` | 0 |
| `BulkReverseGeocodeDto` | `src/geocoding/dto/reverse-geocode.dto.ts` | 0 |
| `CachedBrandIdentity` | `src/email/services/email-brand-cache.service.ts` | 11 |
| `CachedEmailTemplate` | `src/email/services/email-template-cache.service.ts` | 4 |
| `CachedSmtpSetting` | `src/email/services/smtp-cache.service.ts` | 11 |
| `CachedVehicle` | `src/notifications/notification-cache.service.ts` | 4 |
| `CalendarDayDto` | `src/superadmin/dto/calendar.dto.ts` | 4 |
| `CalendarRangeDto` | `src/superadmin/dto/calendar.dto.ts` | 6 |
| `CanonicalTelemetry` | `src/handledata/types/telemetry-normalizer.ts` | 19 |
| `CommandResult` | `src/common/utils/executecommands.ts` | 5 |
| `CommandStatusResult` | `src/agent/application/device-command-dispatcher.service.ts` | 15 |
| `CompanyDto` | `src/admin/dto/company.dto.ts` | 5 |
| `ComponentInfo` | `src/superadmin/server/server.types.ts` | 8 |
| `CreateAdminDto` | `src/superadmin/dto/admin.dto.ts` | 13 |
| `CreateAgentCommandDto` | `src/agent/dto/create-agent-command.dto.ts` | 3 |
| `CreateBugReportDto` | `src/bug-report/dto/create-bug-report.dto.ts` | 18 |
| `CreateDashboardDto` | `src/user/dto/dashboard.dto.ts` | 1 |
| `CreateDeviceDto` | `src/admin/dto/createdevice.dto.ts` | 2 |
| `CreateDriverBulkJobDto` | `src/admin/dto/driverbulkjobs.dto.ts` | 0 |
| `CreateDriverDto` | `src/admin/dto/createdriver.dto.ts` | 12 |
| `CreateExecutionParams` | `src/agent/orchestrator/execution-store.service.ts` | 4 |
| `CreateGeofenceDto` | `src/user/dto/geofence.dto.ts` | 6 |
| `CreateInventoryBulkJobDto` | `src/admin/dto/inventorybulkjobs.dto.ts` | 2 |
| `CreateLandmarkBulkJobDto` | `src/user/dto/landmarkbulkjobs.dto.ts` | 3 |
| `CreatePoiDto` | `src/user/dto/poi.dto.ts` | 8 |
| `CreatePricingPlanDto` | `src/admin/dto/createpricingplan.dto.ts` | 4 |
| `CreateRouteDto` | `src/user/dto/route.dto.ts` | 6 |
| `CreateShareTrackLinkDto` | `src/user/dto/sharetracklinks/create-sharetracklink.dto.ts` | 4 |
| `CreateSubUserDto` | `src/user/dto/subusers/create-subuser.dto.ts` | 7 |
| `CreateSuperAdminDto` | `src/auth/dto/superadmin.dto.ts` | 13 |
| `CreateTeamMemberDto` | `src/admin/dto/createteam.dto.ts` | 6 |
| `CreateTicketDto` | `src/user/dto/create-ticket.dto.ts` | 4 |
| `CreateTicketMessageDto` | `src/user/dto/create-ticket-message.dto.ts` | 1 |
| `CreateUserBulkJobDto` | `src/admin/dto/userbulkjobs.dto.ts` | 0 |
| `CreateUserDriverDto` | `src/user/dto/create-driver.dto.ts` | 11 |
| `CreateUserDto` | `src/admin/dto/createuser.dto.ts` | 12 |
| `CreateVehicleBulkJobDto` | `src/admin/dto/vehiclebulkjobs.dto.ts` | 0 |
| `CreateVehicleDto` | `src/admin/dto/createvehicle.dto.ts` | 2 |
| `CreateVehicleSensorDto` | `src/user/dto/sensors/create-vehicle-sensor.dto.ts` | 5 |
| `CreditsUpdateDto` | `src/superadmin/dto/creditassign.dto.ts` | 2 |
| `CustomCommandDto` | `src/superadmin/dto/customcommand.dto.ts` | 4 |
| `CustomCommandsQueryDto` | `src/superadmin/dto/custom-commands-query.dto.ts` | 4 |
| `DashboardActivityLogsDto` | `src/superadmin/dto/dashboard-activity-logs.dto.ts` | 6 |
| `DataRetentionCleanupSummary` | `src/data-retention/data-retention-cleanup.service.ts` | 13 |
| `DataRetentionTableResult` | `src/data-retention/data-retention-cleanup.service.ts` | 8 |
| `DateRange` | `src/agent/utils/command-normalizer.ts` | 2 |
| `DayUtcBounds` | `src/common/time/timezone-context.service.ts` | 2 |
| `DeviceAndSimDto` | `src/admin/dto/deviceandsim.dto.ts` | 6 |
| `DeviceCommandLogListQuery` | `src/common/utils/device-command-log.util.ts` | 2 |
| `DeviceCommandLogRecord` | `src/common/utils/device-command-log.util.ts` | 22 |
| `DeviceStatusEntry` | `src/dashboard/map-vehicle-status.service.ts` | 3 |
| `DeviceTypeDto` | `src/superadmin/dto/devicetype.dto.ts` | 5 |
| `DispatchCommandParams` | `src/agent/application/device-command-dispatcher.service.ts` | 9 |
| `DispatchCommandResult` | `src/agent/application/device-command-dispatcher.service.ts` | 4 |
| `DistanceReportResult` | `src/agent/application/report-builder.service.ts` | 4 |
| `DocumentTypeDto` | `src/superadmin/dto/documenttype.dto.ts` | 2 |
| `DriverBulkJobRowDto` | `src/admin/dto/driverbulkjobs.dto.ts` | 5 |
| `EmailTemplateDto` | `src/superadmin/dto/emailtemplate.dto.ts` | 2 |
| `EventCandidate` | `src/notifications/services/notification-event-detector.service.ts` | 9 |
| `ExecuteCommandOptions` | `src/common/utils/executecommands.ts` | 5 |
| `ExecutionIdParamDto` | `src/agent/dto/execution-id-param.dto.ts` | 0 |
| `FcmDiagnostics` | `src/common/utils/firebase-fcm.client.ts` | 4 |
| `FcmErrorClassification` | `src/common/utils/firebase-fcm.client.ts` | 4 |
| `FcmSendResult` | `src/common/utils/firebase-fcm.client.ts` | 2 |
| `FleetStatusBuckets` | `src/dashboard/live-status.service.ts` | 7 |
| `ForgotPasswordDto` | `src/auth/dto/forgot-password.dto.ts` | 1 |
| `GeofenceBulkRowDto` | `src/user/dto/landmarkbulkjobs.dto.ts` | 8 |
| `GetOrCreateAddressOpts` | `src/geocoding/geocoding.service.ts` | 2 |
| `GlobalProcessingStats` | `src/common/services/telemetry-stats.service.ts` | 48 |
| `GoogleLoginDto` | `src/auth/dto/google-login.dto.ts` | 1 |
| `HandleCommandParams` | `src/agent/orchestrator/orchestrator.service.ts` | 6 |
| `HistoryAnalyticsData` | `src/common/services/telemetry-playback.service.ts` | 8 |
| `HistoryLoadData` | `src/common/services/telemetry-playback.service.ts` | 12 |
| `HistoryPlaybackData` | `src/common/services/telemetry-playback.service.ts` | 5 |
| `HistorySegmentData` | `src/common/services/telemetry-playback.service.ts` | 10 |
| `HistoryStopMarkerData` | `src/common/services/telemetry-playback.service.ts` | 7 |
| `IAgent` | `src/agent/interfaces/agent.interface.ts` | 2 |
| `ImeiProcessingStats` | `src/common/services/telemetry-stats.service.ts` | 36 |
| `InstallInfo` | `src/superadmin/server/server.types.ts` | 4 |
| `InstallPaths` | `src/superadmin/server/server.types.ts` | 4 |
| `IntegrationCreateDefaults` | `src/stack/third-party-integrations.service.ts` | 5 |
| `IntegrationIdentity` | `src/stack/third-party-integrations.service.ts` | 5 |
| `InventoryBulkJobRowDto` | `src/admin/dto/inventorybulkjobs.dto.ts` | 4 |
| `LatencySnapshot` | `src/common/services/telemetry-stats.service.ts` | 4 |
| `LicenseCachePayload` | `src/licensing/license.types.ts` | 4 |
| `LicenseSnapshot` | `src/licensing/license.types.ts` | 18 |
| `LicenseValidationRequest` | `src/licensing/license.types.ts` | 5 |
| `ListOpenRouterModelsParams` | `src/common/utils/openrouter.client.ts` | 3 |
| `ListShareTrackLinksDto` | `src/user/dto/sharetracklinks/list-sharetracklinks.dto.ts` | 3 |
| `ListThirdPartyIntegrationsQueryDto` | `src/superadmin/dto/third-party-integrations.dto.ts` | 4 |
| `ListWhatsAppTemplatesQueryDto` | `src/superadmin/dto/whatsapp-templates.dto.ts` | 4 |
| `LiveStatusBuckets` | `src/dashboard/live-status.service.ts` | 6 |
| `LocalLicenseSnapshot` | `src/licensing/license.types.ts` | 12 |
| `LoggerConfig` | `src/common/config/winston.config.ts` | 8 |
| `LoginDto` | `src/auth/dto/login.dto.ts` | 2 |
| `MapEventItem` | `src/superadmin/superadmin.service.ts` | 11 |
| `MapEventsQueryDto` | `src/superadmin/dto/map-events.dto.ts` | 6 |
| `MarkParsedParams` | `src/agent/orchestrator/execution-store.service.ts` | 5 |
| `NormalizedGeocodeResult` | `src/common/utils/reverse-geocoding.client.ts` | 8 |
| `NotifDispatchPayload` | `src/queue/notification-dispatch.worker.ts` | 1 |
| `NotificationCandidate` | `src/notifications/notification-engine.ts` | 6 |
| `NotificationEvaluationResult` | `src/queue/notification-evaluate.worker.ts` | 14 |
| `NotificationsQueryDto` | `src/superadmin/dto/notifications.dto.ts` | 3 |
| `OSInfo` | `src/common/utils/identifyos.ts` | 5 |
| `OpenRouterDiagnostics` | `src/common/utils/openrouter.client.ts` | 6 |
| `OpenRouterError` | `src/common/utils/openrouter.client.ts` | 6 |
| `OpenRouterSuccess` | `src/common/utils/openrouter.client.ts` | 4 |
| `ParsedCommand` | `src/agent/orchestrator/command-parser.service.ts` | 4 |
| `ParsedDeviceCommandLogQuery` | `src/common/utils/device-command-log.util.ts` | 2 |
| `PoiBulkRowDto` | `src/user/dto/landmarkbulkjobs.dto.ts` | 4 |
| `PoiCoordinatesDto` | `src/user/dto/poi.dto.ts` | 2 |
| `PolicyDto` | `src/superadmin/dto/policy.dto.ts` | 2 |
| `ProfileDto` | `src/superadmin/dto/profile.dto.ts` | 9 |
| `ProviderChoice` | `src/geocoding/geocoding.service.ts` | 5 |
| `PublicBrandingResult` | `src/branding/branding-resolver.service.ts` | 13 |
| `QueryAgentExecutionDto` | `src/agent/dto/query-agent-execution.dto.ts` | 1 |
| `QuickDeviceDto` | `src/admin/dto/quickdevice.dto.ts` | 3 |
| `RateSnapshot` | `src/common/services/telemetry-stats.service.ts` | 3 |
| `RecipientInfo` | `src/email/services/email-context.resolver.ts` | 5 |
| `RecordManualTransactionDto` | `src/superadmin/dto/record-manual-transaction.dto.ts` | 4 |
| `RegisterDto` | `src/auth/dto/register.dto.ts` | 6 |
| `RegisterPushTokenDto` | `src/auth/dto/push-token.dto.ts` | 4 |
| `RemoteLicenseValidationResponse` | `src/licensing/license.types.ts` | 8 |
| `RemovePushTokenDto` | `src/auth/dto/push-token.dto.ts` | 2 |
| `RenderEmailInput` | `src/email/services/email-renderer.service.ts` | 8 |
| `RenderedEmail` | `src/email/services/email-renderer.service.ts` | 3 |
| `ReplayPlaybackData` | `src/common/services/telemetry-playback.service.ts` | 8 |
| `ReplayPlaybackPoint` | `src/common/services/telemetry-playback.service.ts` | 14 |
| `ReplyContext` | `src/webhooks/whatsapp-reply.service.ts` | 4 |
| `ReplySupportTicketDto` | `src/superadmin/dto/reply-support-ticket.dto.ts` | 1 |
| `ResetPasswordDto` | `src/auth/dto/reset-password.dto.ts` | 2 |
| `ResolvedAddress` | `src/geocoding/geocoding.service.ts` | 5 |
| `ResolvedEmailContext` | `src/email/services/email-context.resolver.ts` | 3 |
| `ResolvedSmtp` | `src/comms/types/comms.types.ts` | 10 |
| `ResolvedVehicle` | `src/agent/application/vehicle-access.service.ts` | 9 |
| `ReverseGeocodeDiagnostics` | `src/common/utils/reverse-geocoding.client.ts` | 8 |
| `ReverseGeocodeParams` | `src/common/utils/reverse-geocoding.client.ts` | 8 |
| `RotateThirdPartyIntegrationSecretDto` | `src/superadmin/dto/third-party-integrations.dto.ts` | 1 |
| `RoundedPoint` | `src/geocoding/geocoding.service.ts` | 4 |
| `RouteBulkRowDto` | `src/user/dto/landmarkbulkjobs.dto.ts` | 3 |
| `RunVehicleSensorDto` | `src/user/dto/sensors/run-vehicle-sensor.dto.ts` | 2 |
| `SendCommandBulkDto` | `src/user/dto/send-command-bulk.dto.ts` | 5 |
| `SendDeviceCommandDto` | `src/superadmin/dto/send-device-command.dto.ts` | 2 |
| `SendEmailParams` | `src/comms/types/comms.types.ts` | 10 |
| `SendEmailResult` | `src/comms/types/comms.types.ts` | 4 |
| `SendFcmToTokenParams` | `src/common/utils/firebase-fcm.client.ts` | 8 |
| `SendPushParams` | `src/comms/types/comms.types.ts` | 5 |
| `SendPushResult` | `src/comms/types/comms.types.ts` | 2 |
| `SendWhatsAppByTypeParams` | `src/comms/types/comms.types.ts` | 4 |
| `SendWhatsAppMessageParams` | `src/common/utils/whatsapp-cloud.client.ts` | 5 |
| `SendWhatsAppTemplateParams` | `src/comms/types/comms.types.ts` | 4 |
| `SendWhatsAppTemplateResult` | `src/comms/types/comms.types.ts` | 3 |
| `SendWhatsAppTextParams` | `src/comms/types/comms.types.ts` | 2 |
| `SerializedDeviceCommandLog` | `src/common/utils/device-command-log.util.ts` | 22 |
| `ServerActionDto` | `src/superadmin/server/dto/server-action.dto.ts` | 2 |
| `ServerOverviewResponse` | `src/superadmin/server/server.types.ts` | 8 |
| `SimCardDto` | `src/admin/dto/sim.dto.ts` | 6 |
| `SimProviderDto` | `src/superadmin/dto/simprociders.dto.ts` | 5 |
| `SmtpResolution` | `src/email/services/email-context.resolver.ts` | 3 |
| `SmtpResolverInput` | `src/comms/services/smtp-resolver.service.ts` | 2 |
| `SmtpSettingDto` | `src/superadmin/dto/smtp.dto.ts` | 9 |
| `SoftwareConfigDto` | `src/superadmin/dto/softwareconfig.dto.ts` | 5 |
| `SseStreamOptions` | `src/common/utils/sse-stream.ts` | 1 |
| `SslInstallDto` | `src/ssl/dto/ssl.dto.ts` | 4 |
| `SslJobState` | `src/ssl/ssl.service.ts` | 9 |
| `SslStatusInfo` | `src/ssl/ssl.service.ts` | 9 |
| `StructuredCommandPayload` | `src/agent/dto/create-agent-command.dto.ts` | 5 |
| `SyncResultItem` | `src/superadmin/whatsapp-templates/whatsapp-templates.service.ts` | 7 |
| `SyncWhatsAppTemplatesDto` | `src/superadmin/dto/whatsapp-templates.dto.ts` | 2 |
| `SystemMetrics` | `src/superadmin/server/server.types.ts` | 22 |
| `SystemVariableDto` | `src/superadmin/dto/systemvariable.dto.ts` | 3 |
| `TelemetryGpsCandidate` | `src/handledata/types/telemetry-normalizer.ts` | 4 |
| `TelemetryInput` | `src/notifications/services/notification-event-detector.service.ts` | 10 |
| `TelemetryMetricComputation` | `src/stack/telemetry-metric-computation.ts` | 10 |
| `TelemetryMetricPacket` | `src/stack/telemetry-metric-computation.ts` | 11 |
| `TelemetryMetricPolicy` | `src/stack/telemetry-metric-computation.ts` | 7 |
| `TelemetryOrigin` | `src/handledata/types/telemetry-normalizer.ts` | 8 |
| `TelemetryRecord` | `src/realtime/types/telemetry-record.ts` | 22 |
| `TelemetrySnapshot` | `src/notifications/notification-engine.ts` | 8 |
| `TemplateVars` | `src/notifications/whatsapp-templates.local.ts` | 6 |
| `TestEmailDto` | `src/auth/dto/email-test.dto.ts` | 2 |
| `TestFcmIntegrationDto` | `src/superadmin/dto/third-party-integrations.dto.ts` | 4 |
| `TestFcmToMeDto` | `src/superadmin/dto/third-party-integrations.dto.ts` | 2 |
| `TestOpenRouterChatParams` | `src/common/utils/openrouter.client.ts` | 5 |
| `TestOpenRouterIntegrationDto` | `src/superadmin/dto/third-party-integrations.dto.ts` | 2 |
| `TestPushDto` | `src/auth/dto/push-token.dto.ts` | 2 |
| `TestWhatsAppIntegrationDto` | `src/superadmin/dto/third-party-integrations.dto.ts` | 5 |
| `TimelineStampedValue` | `src/common/utils/telemetry-timeline.util.ts` | 2 |
| `TimezoneContext` | `src/common/time/timezone-context.service.ts` | 3 |
| `TopbarSearchAction` | `src/topbar-search/dto/topbar-search.dto.ts` | 9 |
| `TopbarSearchGroup` | `src/topbar-search/dto/topbar-search.dto.ts` | 3 |
| `TopbarSearchQueryDto` | `src/topbar-search/dto/topbar-search.dto.ts` | 2 |
| `TopbarSearchResult` | `src/topbar-search/dto/topbar-search.dto.ts` | 8 |
| `TraceContext` | `src/handledata/types/telemetry-normalizer.ts` | 9 |
| `TrailPlaybackData` | `src/common/services/telemetry-playback.service.ts` | 5 |
| `TrailPlaybackPoint` | `src/common/services/telemetry-playback.service.ts` | 8 |
| `UnassignSubUserVehiclesDto` | `src/user/dto/subusers/unassign-subuser-vehicles.dto.ts` | 1 |
| `UpdateAdminDto` | `src/superadmin/dto/updateadmin.dto.ts` | 9 |
| `UpdateCompanyDto` | `src/admin/dto/updatecompany.dto.ts` | 7 |
| `UpdateDashboardDto` | `src/user/dto/dashboard.dto.ts` | 3 |
| `UpdateDeviceDto` | `src/admin/dto/updatedevice.dto.ts` | 5 |
| `UpdateDocDto` | `src/superadmin/dto/updatedoc.dto.ts` | 10 |
| `UpdateDriverDto` | `src/admin/dto/updatedriver.dto.ts` | 13 |
| `UpdateGeofenceDto` | `src/user/dto/geofence.dto.ts` | 6 |
| `UpdatePasswordDto` | `src/superadmin/dto/updatepassword.dto.ts` | 2 |
| `UpdatePoiDto` | `src/user/dto/poi.dto.ts` | 8 |
| `UpdateRouteDto` | `src/user/dto/route.dto.ts` | 6 |
| `UpdateSettingsStateDto` | `src/superadmin/dto/usersetting.dto.ts` | 10 |
| `UpdateShareTrackLinkDto` | `src/user/dto/sharetracklinks/update-sharetracklink.dto.ts` | 5 |
| `UpdateSmtpConfigDto` | `src/admin/dto/updatesmtpconfig.dto.ts` | 9 |
| `UpdateSubUserDto` | `src/user/dto/subusers/update-subuser.dto.ts` | 7 |
| `UpdateSupportTicketStatusDto` | `src/superadmin/dto/update-support-ticket-status.dto.ts` | 1 |
| `UpdateTeamMemberDto` | `src/admin/dto/updateteam.dto.ts` | 7 |
| `UpdateThirdPartyIntegrationDto` | `src/superadmin/dto/third-party-integrations.dto.ts` | 5 |
| `UpdateUserDriverDto` | `src/user/dto/update-driver.dto.ts` | 13 |
| `UpdateUserDto` | `src/admin/dto/updateuser.dto.ts` | 14 |
| `UpdateUserVehicleDto` | `src/user/dto/update-vehicle.dto.ts` | 6 |
| `UpdateVehicleConfigDto` | `src/admin/dto/update-vehicle-config.dto.ts` | 5 |
| `UpdateVehicleDto` | `src/admin/dto/updatevehicle.dto.ts` | 9 |
| `UpdateVehicleSensorDto` | `src/user/dto/sensors/update-vehicle-sensor.dto.ts` | 5 |
| `UpdateWhatsAppTemplateDto` | `src/superadmin/dto/whatsapp-templates.dto.ts` | 5 |
| `UploadDocDto` | `src/superadmin/dto/uploaddoc.dto.ts` | 12 |
| `UpsertThirdPartyIntegrationDto` | `src/superadmin/dto/third-party-integrations.dto.ts` | 10 |
| `UserActivityLogsDto` | `src/admin/dto/user-activity-logs.dto.ts` | 6 |
| `UserBulkJobRowDto` | `src/admin/dto/userbulkjobs.dto.ts` | 5 |
| `UserSettingsDto` | `src/superadmin/dto/usersetting.dto.ts` | 10 |
| `ValidateFtkeyDto` | `src/superadmin/dto/ftkey.dto.ts` | 1 |
| `ValidateGeocodingIntegrationDto` | `src/superadmin/dto/third-party-integrations.dto.ts` | 4 |
| `ValidateGoogleSsoDto` | `src/superadmin/dto/third-party-integrations.dto.ts` | 1 |
| `VehicleBulkJobRowDto` | `src/admin/dto/vehiclebulkjobs.dto.ts` | 2 |
| `VehicleBulkRowDto` | `src/admin/dto/createvehiclebulkjob.dto.ts` | 2 |
| `VehicleRefParams` | `src/agent/application/vehicle-access.service.ts` | 6 |
| `VehicleTypeDto` | `src/superadmin/dto/vehicletype.dto.ts` | 3 |
| `VerifyOtpDto` | `src/verification/dto/verify-otp.dto.ts` | 1 |
| `WhatsAppApiError` | `src/common/utils/whatsapp-cloud.client.ts` | 7 |
| `WhatsAppApiSuccess` | `src/common/utils/whatsapp-cloud.client.ts` | 5 |
| `WhatsAppDiagnostics` | `src/common/utils/whatsapp-cloud.client.ts` | 8 |
| `WhatsAppGatewayResult` | `src/communications/whatsapp/whatsapp-gateway.service.ts` | 5 |
| `WireTraceEvent` | `src/common/services/wire-trace.service.ts` | 24 |
| `commandTypeDto` | `src/superadmin/dto/commandtype.dto.ts` | 3 |