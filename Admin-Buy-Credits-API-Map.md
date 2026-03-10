# Admin Buy Credits API Map

Sources compared:
- `FleetStack-API-Reference.md` (preferred source of truth when conflicts exist)
- `X-Fleet.postman_collection.json`

Scope:
- Primary: Admin buy credits flow (balance, packages, purchase, checkout/verify, history, invoices)
- Secondary: Superadmin credit/billing endpoints that may support admin credit operations

## 1) Summary

- Buy-credits related endpoints discovered (Admin + supporting Superadmin): **15**
- Admin endpoints directly usable for Buy Credits UX today: **10**
- Dedicated payment checkout/intent endpoint found: **0**
- Dedicated payment verification/confirm endpoint found: **0**
- Dedicated invoice/receipt fetch endpoint found: **0**

## 2) Recommended UI Flow Mapping

| Flow Step | Endpoint(s) | Status |
|---|---|---|
| A) Show current balance | `GET /admin/profile` (candidate `User.credits`), `GET /admin/dashboard/summary` (no explicit credits key) | Partial |
| B) List available credit packages/plans | `GET /admin/pricingplans` | Available |
| C) Create purchase/order | `POST /admin/payments/renew` (MD), `POST /admin/transactions/renew` (Postman only) | Partial / conflict |
| D) Get checkout link / payment intent | Not found | Missing |
| E) Verify payment / mark paid | Not found | Missing |
| F) Transactions/history | `GET /admin/transactions`, `GET /admin/payments`, `GET /admin/transactions/analytics` | Available |
| G) Invoice/receipt | Not found | Missing |

## 3) Endpoint Inventory (Summary Table)

| Method | Path | Purpose | Auth | Source |
|---|---|---|---|---|
| GET | `/admin/profile` | Candidate source for current admin credit balance (`User.credits` model) | Yes (Admin token) | MD + Postman |
| GET | `/admin/dashboard/summary` | Dashboard totals/revenue context (not explicit credits balance) | Yes (Admin token) | MD (not in Postman scan for this feature) |
| GET | `/admin/pricingplans` | List plans/packages | Yes (Admin token) | MD + Postman |
| POST | `/admin/pricingplans` | Create plan/package | Yes (Admin token) | MD + Postman |
| PATCH | `/admin/pricingplans/:id` | Update plan/package | Yes (Admin token) | MD + Postman |
| POST | `/admin/payments/renew` | Create renewal payment transaction | Yes (Admin token) | MD + Postman |
| POST | `/admin/transactions/renew` | Renew vehicles via transactions route | Yes (Admin token) | Postman only |
| GET | `/admin/payments` | Payments list/history | Yes (Admin token) | MD + Postman |
| GET | `/admin/transactions` | Transactions list/history | Yes (Admin token) | MD + Postman |
| GET | `/admin/transactions/analytics` | Aggregated transaction metrics | Yes (Admin token) | MD + Postman |
| POST | `/superadmin/assigncredits/:id` | Assign/deduct credits for an admin/user (supporting flow) | Yes (Superadmin token) | MD + Postman |
| GET | `/superadmin/creditlogs/:id` | Credit log timeline (supporting flow) | Yes (Superadmin token) | MD + Postman |
| GET | `/superadmin/transactions` | Superadmin transaction list | Yes (Superadmin token) | MD + Postman |
| GET | `/superadmin/transactions/analytics` | Superadmin transaction analytics | Yes (Superadmin token) | MD + Postman |
| POST | `/superadmin/transactions/manual` | Record manual transaction | Yes (Superadmin token) | MD + Postman |

## 4) Endpoint Details (params/body/response keys)

Notes:
- Keys below are **keys only** (no real values).
- Response keys are listed only when present in MD examples/models.

### `GET /admin/profile`
- Purpose: candidate for current balance (via `User` model `credits`).
- Query params: none documented.
- Body keys: none.
- Response keys (MD model: `User`):
  - `uid`, `name`, `email`, `username`, `mobilePrefix`, `mobileNumber`, `isEmailVerified`, `isMobileVerified`, `loginType`, `parentUserId`, `isActive`, `profileUrl`, `credits`, `createdAt`, `updatedAt`.

### `GET /admin/dashboard/summary`
- Purpose: dashboard financial context (not explicit wallet balance endpoint).
- Query params (MD): `months`, `listLimit`, `currency`.
- Body keys: none.
- Response keys (MD sample):
  - `action`, `data.totalVehicles`, `data.totalUsers`, `data.lastMonthRevenue`, `data.thisMonthRevenue`, `data.pendingAmount`, `data.expiryThisWeek`, `data.expiryThisMonth`, `data.expiryPreview`, `data.vehicleLiveStatus`, `data.recentPayments`, `data.forecastRevenue`, `data.monthGraph`.

### `GET /admin/pricingplans`
- Purpose: package/plan list.
- Query params: none documented.
- Body keys: none.
- Response keys (MD model: `PricingPlan`):
  - `id`, `name`, `price`, `currency`, `durationDays`, `adminUserId`, `isActive`, `createdAt`, `updatedAt`.

### `POST /admin/pricingplans`
- Purpose: create package/plan.
- Query params: none documented.
- Body keys (MD + Postman):
  - `name`, `durationDays`, `price`, `currency`.
- Response keys: not explicitly documented.

### `PATCH /admin/pricingplans/:id`
- Purpose: update package/plan.
- Query params: none documented.
- Body keys (MD + Postman):
  - `name`, `durationDays`, `price`, `currency`.
- Response keys: not explicitly documented.

### `POST /admin/payments/renew`
- Purpose: create renewal payment.
- Query params: none documented.
- Body keys (MD):
  - `userId`, `vehicleIds`, `paymentMode`, `reference`, `amountOverride`.
- Body keys (Postman sample):
  - `vehicleIds`, `planId`.
- Response keys: not explicitly documented.

### `POST /admin/transactions/renew` (Postman only)
- Purpose: alternate renew endpoint under transactions folder.
- Query params: none in Postman sample.
- Body keys (Postman sample):
  - `vehicleIds`, `planId`.
- Response keys: not documented in MD.

### `GET /admin/payments`
- Purpose: payment history list.
- Query params: not documented in MD.
- Body keys: none.
- Response keys: not explicitly documented.

### `GET /admin/transactions`
- Purpose: transaction history list.
- Query params: not documented in MD.
- Body keys: none.
- Response keys (MD model: `Transaction`):
  - `id`, `fromUserId`, `toUserId`, `amount`, `currency`, `status`, `reference`, `paymentMode`, `createdAt`, `updatedAt`.

### `GET /admin/transactions/analytics`
- Purpose: transaction analytics.
- Query params: not documented in MD.
- Body keys: none.
- Response keys: not explicitly documented.

### `POST /superadmin/assigncredits/:id`
- Purpose: assign/deduct credits to target account.
- Query params: none.
- Body keys (MD + Postman):
  - `credits`, `activity`.
- Response keys: not explicitly documented.

### `GET /superadmin/creditlogs/:id`
- Purpose: credit logs for target account.
- Query params: none documented.
- Body keys: none.
- Response keys: not explicitly documented.

### `GET /superadmin/transactions`
- Purpose: superadmin transaction list.
- Query params (MD):
  - `adminId`, `status`, `from`, `to`, `q`, `page`, `limit`.
- Body keys: none.
- Response keys: not explicitly documented.

### `GET /superadmin/transactions/analytics`
- Purpose: superadmin analytics for billing.
- Query params (MD):
  - `adminId`, `from`, `to`, `month`, `year`.
- Body keys: none.
- Response keys: not explicitly documented.

### `POST /superadmin/transactions/manual`
- Purpose: manual transaction entry.
- Query params: none.
- Body keys (MD):
  - `adminId`, `amount`, `reference`, `paymentMode`.
- Body keys (Postman sample):
  - `adminId`, `amount`, `currency`, `notes`.
- Response keys: not explicitly documented.

## 5) Missing Pieces for Admin Buy Credits

### 5.1 Missing create-purchase endpoint?
- **Partially available** via renewal endpoints:
  - `POST /admin/payments/renew` (MD)
  - `POST /admin/transactions/renew` (Postman only)
- Gap: these appear vehicle-renewal centric, not a clear generic “buy credits/top-up wallet” contract.

### 5.2 Missing verify-payment endpoint?
- **Missing**: no explicit Admin endpoint for payment verification/confirmation in either source.

### 5.3 Missing packages-list endpoint?
- **Not missing**: `GET /admin/pricingplans` exists.

### 5.4 Missing checkout/payment-intent endpoint?
- **Missing**: no explicit endpoint for checkout session/payment link/payment intent (`stripe|razorpay|paystack|checkout|order`) in either source.

### 5.5 Missing invoice/receipt endpoint?
- **Missing**: no explicit invoice/receipt retrieval endpoint found for Admin buy credits flow.

## 6) Source Discrepancies (MD vs Postman)

1. **Renew endpoint path mismatch**
   - MD: `POST /admin/payments/renew`
   - Postman: `POST /admin/payments/renew` **and** `POST /admin/transactions/renew`
   - Recommendation: pick one canonical route and document the other as alias/deprecated if applicable.

2. **Renew payload mismatch**
   - MD body keys: `userId`, `vehicleIds`, `paymentMode`, `reference`, `amountOverride`
   - Postman sample body keys: `vehicleIds`, `planId`
   - Recommendation: document required vs optional keys clearly, including `planId` if supported.

3. **Manual transaction payload mismatch**
   - MD body keys: `adminId`, `amount`, `reference`, `paymentMode`
   - Postman sample body keys: `adminId`, `amount`, `currency`, `notes`
   - Recommendation: reconcile required keys and accepted variants.

4. **Current balance contract not explicit**
   - MD has `User.credits` model field, but no dedicated Admin credits-balance endpoint for Buy Credits screen.
   - Recommendation: document canonical balance source for Admin UI.

## 7) Suggested UI Screens (API-backed)

1. **Buy Credits screen**
   - Data: current balance (`GET /admin/profile` candidate), packages (`GET /admin/pricingplans`).

2. **Checkout screen**
   - Data/action: currently unclear due to missing checkout/payment-intent endpoint.

3. **Payment result screen**
   - Data/action: currently unclear due to missing verify-payment endpoint.

4. **Credits history screen**
   - Data: `GET /admin/transactions`, `GET /admin/payments`, `GET /admin/transactions/analytics`.

---
Generated as read-only endpoint mapping. No credentials/tokens included.
