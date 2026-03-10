# FleetStack Missing APIs — Client Report (Admin Module)

Sources used:
- `FleetStack-API-Reference.md` (primary)
- `X-Fleet.postman_collection.json`
- `FleetStack-API-Reference-Missing.md`
- `Admin-Buy-Credits-API-Map.md`

Date: 2026-03-09

## 1) Executive Summary

### What is working (major Admin integrations already implemented)
- Admin Home dashboard (summary/status/recent activity)
- Admin Users (list, filters, details, enable/disable)
- Admin Vehicles/Drivers/Devices/SIM screens (list + actions where endpoints exist)
- Admin Support tickets (list/messages/status)
- Admin Calendar and Admin Logs/Activity
- Admin Map telemetry
- Admin Profile + update flows

### What is blocked by missing/unclear APIs
- Admin **Notify Users** send/broadcast API is not documented/confirmed.
- Admin **Notification Preferences** persistence APIs are not documented/confirmed.
- Admin **Buy Credits** is missing checkout/verification/receipt APIs.
- Admin **Transaction Details/Receipt** APIs are missing.

---

## 2) Missing APIs (by feature)

### A) Admin “Notify Users” (send notification)

#### Confirmed available
- `GET /admin/users`
  - Source: **MD + Postman**
  - Purpose: recipient list/search source for modal
- `GET /admin/shortusers`
  - Source: **MD + Postman**
  - Purpose: lightweight recipient list

#### Missing / unclear
- Send notification endpoint (Email/In-app broadcast) for Admin
  - Method + path: **Not found in MD/Postman**
  - Source: **Not found**
  - Why needed: `Admin Notify Users` modal send action
  - Required capability:
    - send to selected users
    - select channel(s) (email/in-app/push)
    - optional subject
    - required message

Required payload keys (capability-level):
- `channel` (or `channels`)
- `userIds`
- `subject` (optional)
- `message` (required)

---

### B) Mobile Notification Preferences (Vehicle alerts + DND)

#### Confirmed available (inbox/read state)
- `GET /admin/notifications`
- `PATCH /admin/notifications/read-all`
- `PATCH /admin/notifications/:id/read`
  - Source: **MD**
  - Postman status: **Not found** (mismatch; see section 3)
  - Why relevant: notifications inbox/read state only

#### Missing / unclear (preferences persistence)
- Admin preferences storage endpoints for toggles are not found:
  - `allNotifications`
  - `vehicleOffline`
  - `overspeed`
  - `ignition`
  - `geofence`
  - `sos`
  - `systemAlert`
  - `dndEnabled` (+ optional DND schedule)

- Method + path: **Not found for Admin**
- Source: **Not found in MD/Postman**
- Why needed: `Admin Notification Preferences` screen persistence

Optional but recommended capability (also missing for Admin):
- Device push token registration/update/remove (FCM/APNs)
  - Source: **Not found for Admin in MD/Postman**

---

### C) Buy Credits / Payments end-to-end

#### Found endpoints
- `GET /admin/pricingplans` (plans/packages)
  - Source: **MD + Postman**
- `GET /admin/transactions`, `GET /admin/transactions/analytics`, `GET /admin/payments`
  - Source: **MD + Postman**
- Renewal purchase-like endpoints:
  - `POST /admin/payments/renew` (MD + Postman)
  - `POST /admin/transactions/renew` (Postman only)

#### Missing
- Checkout/payment-intent or payment-link endpoint
  - Method + path: **Not found**
  - Source: **Not found in MD/Postman**
- Payment verification/confirm endpoint
  - Method + path: **Not found**
  - Source: **Not found in MD/Postman**
- Invoice/receipt download endpoint
  - Method + path: **Not found**
  - Source: **Not found in MD/Postman**

#### Why needed
- `Admin Buy Credits` UX requires order -> checkout -> verify -> receipt flow.

---

### D) Transactions details/receipt

#### Confirmed available
- `GET /admin/transactions`
- `GET /admin/transactions/analytics`
  - Source: **MD + Postman**

#### Missing
- Transaction details by id
  - Expected capability: `GET /admin/transactions/:id` (or equivalent)
  - Source: **Not found in MD/Postman**
- Receipt/invoice for transaction
  - Expected capability: `/receipt` or `/invoice` endpoint
  - Source: **Not found in MD/Postman**

#### Why needed
- `Admin Transactions` 3-dot menu: “View details” and “Receipt”.

---

## 3) MD vs Postman mismatches (needs confirmation)

### Mismatch 1 — Admin notifications inbox endpoints
- MD:
  - `GET /admin/notifications`
  - `PATCH /admin/notifications/read-all`
  - `PATCH /admin/notifications/:id/read`
- Postman:
  - **Not found** in current collection snapshot
- Impact:
  - Inbox integration can be based on MD, but Postman parity is missing.

### Mismatch 2 — Admin email-subscription endpoints
- MD:
  - `GET /admin/profile/email-subscription`
  - `POST /admin/profile/email-subscription/subscribe`
- Postman:
  - **Not found**
- Impact:
  - Email subscription/verification flows cannot be Postman-validated.

### Mismatch 3 — Renew path divergence
- MD:
  - `POST /admin/payments/renew`
- Postman:
  - `POST /admin/payments/renew`
  - `POST /admin/transactions/renew` (**extra path not in MD**)
- Impact:
  - Need canonical path decision.

### Mismatch 4 — Renew payload keys differ
- MD body keys for `POST /admin/payments/renew`:
  - `userId`, `vehicleIds`, `paymentMode`, `reference`, `amountOverride`
- Postman body keys for `POST /admin/payments/renew`:
  - `planId`, `vehicleIds`
- Impact:
  - Frontend request contract is ambiguous.

### Mismatch 5 — Admin ticket create payload differs
- MD (`POST /admin/tickets`) example keys:
  - `fromUserId`, `title`, `category`, `priority`, `message`
- Postman (`POST /admin/tickets`) body keys:
  - `userId`, `subject`, `message`
- Impact:
  - Ticket create form payload contract needs finalization.

---

## 4) Recommended endpoints (capabilities)

> Naming/path is intentionally left as “Backend to confirm final path” where source is missing.

### A) Notify Users send capability
- Method + path: **Backend to confirm final path**
- Suggested request keys:
```json
{
  "channel": null,
  "userIds": [],
  "subject": null,
  "message": null
}
```
- Suggested response keys:
```json
{
  "success": null,
  "message": null,
  "sentCount": null,
  "failedCount": null
}
```

### B) Admin notification preferences persistence
- GET preferences: **Backend to confirm final path**
- PATCH preferences: **Backend to confirm final path**
- Suggested request keys:
```json
{
  "allNotifications": null,
  "vehicleOffline": null,
  "overspeed": null,
  "ignition": null,
  "geofence": null,
  "sos": null,
  "systemAlert": null,
  "dndEnabled": null,
  "dndStartTime": null,
  "dndEndTime": null
}
```
- Suggested response keys:
```json
{
  "preferences": null,
  "updatedAt": null
}
```

### C) Push token registration capability (optional but recommended)
- Register/update/remove token: **Backend to confirm final path**
- Suggested request keys:
```json
{
  "platform": null,
  "deviceToken": null,
  "appVersion": null
}
```

### D) Buy Credits payment flow completion
- Create checkout/payment-intent: **Backend to confirm final path**
- Verify/confirm payment: **Backend to confirm final path**
- Receipt/invoice retrieval: **Backend to confirm final path**
- Suggested request keys (checkout):
```json
{
  "planId": null,
  "amount": null,
  "currency": null,
  "returnUrl": null,
  "cancelUrl": null
}
```
- Suggested request keys (verify):
```json
{
  "orderId": null,
  "paymentId": null,
  "signature": null,
  "reference": null
}
```

### E) Transaction details + receipt
- Transaction details by id: **Backend to confirm final path**
- Receipt/invoice by transaction id: **Backend to confirm final path**
- Suggested response keys (details):
```json
{
  "id": null,
  "status": null,
  "method": null,
  "amount": null,
  "currency": null,
  "gatewayFee": null,
  "tax": null,
  "credits": null,
  "reference": null,
  "invoiceNumber": null,
  "createdAt": null
}
```

---

## Appendix — Endpoint evidence snapshots

### Admin notify-related (recipient side)
- `GET /admin/users` — Source: MD + Postman
- `GET /admin/shortusers` — Source: MD + Postman
- Send/broadcast endpoint — Source: Not found

### Admin notifications inbox
- MD lists `GET/PATCH /admin/notifications*`
- Postman snapshot does not contain `/admin/notifications*`

### Admin buy-credits/payment references
- `GET /admin/pricingplans` — MD + Postman
- `GET /admin/transactions` — MD + Postman
- `GET /admin/transactions/analytics` — MD + Postman
- `GET /admin/payments` — MD + Postman
- `POST /admin/payments/renew` — MD + Postman (payload mismatch)
- `POST /admin/transactions/renew` — Postman only
