# FleetStack API Reference

> **Version:** 1.0.0  
> **Base URL:** `https://<your-domain>:3001`  
> **Last Updated:** 2026-03-08  
> **Audience:** Mobile App Developers  

---

## Table of Contents

1. [Overview](#1-overview)
2. [Authentication](#2-authentication)
3. [Response Envelope](#3-response-envelope)
4. [Error Handling](#4-error-handling)
5. [Auth APIs (Public)](#5-auth-apis)
6. [Superadmin APIs](#6-superadmin-apis)
7. [Admin APIs](#7-admin-apis)
8. [User APIs](#8-user-apis)
9. [Health APIs (Public)](#9-health-apis)
10. [WebSocket (Real-time)](#10-websocket-real-time)
11. [Data Models](#11-data-models)
12. [Enumerations](#12-enumerations)
13. [Rate Limits & Constraints](#13-rate-limits--constraints)

---

## 1. Overview

FleetStack is a multi-tenant GPS fleet tracking platform. The API is organized around REST principles:

- Uses standard HTTP verbs (`GET`, `POST`, `PATCH`, `PUT`, `DELETE`)
- Returns JSON-encoded responses
- Uses JWT Bearer tokens for authentication
- File uploads use `multipart/form-data`
- Server-Sent Events (SSE) for streaming progress
- Socket.IO for real-time telemetry and notifications

### Role Hierarchy

```
SUPERADMIN (platform owner)
  └── ADMIN (fleet operator / customer)
        ├── USER (fleet manager)
        │     └── SUBUSER (restricted user)
        ├── TEAM (team member)
        └── DRIVER (vehicle driver)
```

### Base Headers (All Requests)

| Header | Value | Required |
|--------|-------|----------|
| `Content-Type` | `application/json` | Yes (except file uploads) |
| `Authorization` | `Bearer <jwt_token>` | Yes (protected endpoints) |

---

## 2. Authentication

### 2.1 Token Lifecycle

| Token | TTL | Purpose |
|-------|-----|---------|
| Access Token (JWT) | 24 hours | API authorization |
| Refresh Token | 7 days | Obtain new access token |

### 2.2 JWT Payload

```json
{
  "sub": 123,
  "username": "john_doe",
  "email": "john@example.com",
  "role": "ADMIN",
  "iat": 1709884800,
  "exp": 1709971200
}
```

### 2.3 Using Tokens

```
GET /admin/vehicles HTTP/1.1
Host: api.fleetstack.io
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
Content-Type: application/json
```

---

## 3. Response Envelope

All responses are automatically wrapped by the server:

### Success Response

```json
{
  "status": "success",
  "data": {
    "action": true,
    "message": "Vehicle created successfully",
    "data": { ... }
  },
  "timestamp": "2026-03-08T10:30:00.000Z"
}
```

### Error Response

```json
{
  "status": "error",
  "data": {
    "statusCode": 400,
    "message": "Validation failed",
    "error": "Bad Request"
  },
  "timestamp": "2026-03-08T10:30:00.000Z"
}
```

---

## 4. Error Handling

| HTTP Code | Meaning | When |
|-----------|---------|------|
| `200` | Success | Request completed |
| `201` | Created | Resource created |
| `400` | Bad Request | Validation errors, invalid input |
| `401` | Unauthorized | Missing/expired JWT token |
| `403` | Forbidden | Insufficient role permissions |
| `404` | Not Found | Resource doesn't exist |
| `409` | Conflict | Duplicate resource (e.g., duplicate IMEI) |
| `429` | Too Many Requests | Rate limit exceeded |
| `500` | Internal Server Error | Server failure |

---

## 5. Auth APIs

> **Base Path:** `/auth`  
> **Auth Required:** None (except push token & email test endpoints)

### 5.1 Check Superadmin Exists

Checks if the platform has been set up (first-run detection).

```
GET /auth/checksadmin
```

**Response:**
```json
{
  "action": true,
  "message": "Superadmin exists"
}
```

---

### 5.2 Create Superadmin (First-Time Setup)

Creates the first and only superadmin. Can only be called once.

```
POST /auth/createsuperadmin
```

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "admin@fleetstack.io",
  "mobilePrefix": "+1",
  "mobileNumber": "5551234567",
  "username": "superadmin",
  "password": "SecureP@ss123",
  "companyName": "FleetStack Inc.",
  "website": "https://fleetstack.io",
  "address": "123 Fleet Street",
  "country": "US",
  "state": "CA",
  "city": "San Francisco",
  "pincode": "94102"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `name` | string | Yes | — |
| `email` | string | Yes | Valid email |
| `mobilePrefix` | string | Yes | Country code |
| `mobileNumber` | string | Yes | — |
| `username` | string | Yes | — |
| `password` | string | Yes | Min 6 chars |
| `companyName` | string | Yes | — |
| `website` | string | No | Valid URL |
| `address` | string | Yes | — |
| `country` | string | Yes | ISO country code |
| `state` | string | Yes | State code |
| `city` | string | Yes | — |
| `pincode` | string | No | — |

**Response:**
```json
{
  "message": "Superadmin created successfully",
  "data": {
    "uid": 1,
    "name": "John Doe",
    "username": "superadmin",
    "email": "admin@fleetstack.io"
  }
}
```

---

### 5.3 Login

Authenticate a user of any role. Returns JWT + refresh token.

```
POST /auth/login
```

**Request Body:**
```json
{
  "identifier": "admin@fleetstack.io",
  "password": "SecureP@ss123"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `identifier` | string | Yes | Email **or** username |
| `password` | string | Yes | Account password |

**Response:**
```json
{
  "action": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
    "user": {
      "id": "123",
      "role": "ADMIN",
      "username": "john_admin",
      "email": "admin@fleetstack.io",
      "name": "John Admin",
      "profileUrl": "/uploads/users/123/avatar.jpg"
    },
    "settings": {
      "dateFormat": "DD/MM/YYYY",
      "languageCode": "en",
      "direction": "LTR",
      "theme": "LIGHT",
      "timezone": "+05:30",
      "timeFormat": "24H",
      "distanceUnit": "KM",
      "defaultLat": 28.6139,
      "defaultLon": 77.209,
      "mapZoom": 12
    }
  }
}
```

> **Note:** Failed login returns HTTP 200 with `"action": false` and a generic message to prevent user enumeration.

---

### 5.4 Google OAuth Login

Exchange Google authorization code for a FleetStack JWT. Login only — no account auto-creation.

```
GET /auth/google/client-id
```

**Response:**
```json
{
  "action": true,
  "message": "Google client ID fetched",
  "data": {
    "clientId": "123456789.apps.googleusercontent.com"
  }
}
```

```
POST /auth/google/login
```

**Request Body:**
```json
{
  "code": "4/0AX4XfWi..."
}
```

**Response:** Same as [5.3 Login](#53-login)

---

### 5.5 Forgot Password

Initiates a password reset email. Always returns success to prevent user enumeration.

```
POST /auth/forgot-password
```

**Request Body:**
```json
{
  "identifier": "admin@fleetstack.io"
}
```

**Response:**
```json
{
  "action": true,
  "message": "If an account exists with this identifier, a password reset email has been sent"
}
```

> **Rate Limit:** 3 requests per 15 minutes per identifier.

---

### 5.6 Reset Password

Complete a password reset using the token from the email link.

```
POST /auth/reset-password
```

**Request Body:**
```json
{
  "token": "a1b2c3d4e5f6...",
  "newPassword": "NewSecureP@ss456"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `token` | string | Yes | From reset email |
| `newPassword` | string | Yes | 6–35 characters |

> **Constraints:** Token expires in 15 min. Max 5 failed attempts per token. Single-use.

---

### 5.7 FCM Web Push Config

Get Firebase Cloud Messaging configuration for push notifications.

```
GET /auth/fcm-web-config
```

**Response:**
```json
{
  "action": true,
  "message": "FCM web config fetched",
  "data": {
    "webConfig": {
      "apiKey": "AIza...",
      "authDomain": "project.firebaseapp.com",
      "projectId": "my-project",
      "storageBucket": "my-project.appspot.com",
      "messagingSenderId": "123456789",
      "appId": "1:123456789:web:abc123"
    },
    "webVapidKey": "BNr3...",
    "configVersion": "sha256hash..."
  }
}
```

---

### 5.8 Push Token Management

> **Auth Required:** Yes (Bearer Token)

#### Register Push Token

```
POST /auth/push-token
```

**Request Body:**
```json
{
  "token": "fMr9K7...",
  "platform": "android",
  "deviceId": "device-uuid-123",
  "userAgent": "FleetStack-Android/1.0"
}
```

| Field | Type | Required | Default | Values |
|-------|------|----------|---------|--------|
| `token` | string | Yes | — | FCM token |
| `platform` | string | No | `"web"` | `web`, `android`, `ios` |
| `deviceId` | string | No | — | Unique device identifier |
| `userAgent` | string | No | — | Client user agent |

#### Remove Push Token

```
DELETE /auth/push-token
```

**Request Body:**
```json
{
  "token": "fMr9K7...",
  "deviceId": "device-uuid-123"
}
```

> If `token` provided → deactivate that token. If `deviceId` only → deactivate all for device. If empty → deactivate all for user.

#### List My Push Tokens

```
GET /auth/push-tokens/me
```

**Response:**
```json
{
  "action": true,
  "data": [
    {
      "id": 1,
      "platform": "android",
      "deviceId": "device-uuid-123",
      "lastSeenAt": "2026-03-08T10:00:00Z",
      "createdAt": "2026-03-01T08:00:00Z",
      "isActive": true,
      "tokenLast10": "...K7fMr9abc"
    }
  ]
}
```

#### Send Test Push

```
POST /auth/push-test
```

**Request Body:**
```json
{
  "title": "Test Notification",
  "body": "Push notifications are working! ✅"
}
```

**Response:**
```json
{
  "action": true,
  "message": "Test push sent",
  "data": {
    "sent": 1,
    "failed": 0,
    "deactivated": 0
  }
}
```

---

### 5.9 Email Test

> **Auth Required:** Yes (Bearer Token). User email must be verified.

```
POST /auth/email-test
```

**Request Body:**
```json
{
  "subject": "FleetStack Email Test",
  "body": "This is a test email from FleetStack."
}
```

**Response:**
```json
{
  "action": true,
  "message": "Test email sent",
  "data": {
    "messageId": "<abc123@smtp.example.com>",
    "resolvedVia": "admin_smtp"
  }
}
```

---

## 6. Superadmin APIs

> **Base Path:** `/superadmin`  
> **Auth Required:** Yes — Role: `SUPERADMIN`  
> **Header:** `Authorization: Bearer <superadmin_jwt>`

### 6.1 Admin Management

#### Create Admin

```
POST /superadmin/createadmin
```

**Request Body:**
```json
{
  "name": "Fleet Operator",
  "email": "operator@fleet.co",
  "mobilePrefix": "+91",
  "mobileNumber": "9876543210",
  "username": "fleet_operator",
  "password": "SecureP@ss123",
  "companyName": "Fleet Co",
  "address": "456 Track Avenue",
  "country": "IN",
  "state": "DL",
  "city": "New Delhi",
  "pincode": "110001",
  "credits": "1000"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `name` | string | Yes | — |
| `email` | string | No | Valid email |
| `mobilePrefix` | string | No | Country code |
| `mobileNumber` | string | No | — |
| `username` | string | Yes | Unique |
| `password` | string | Yes | Min 6 chars |
| `companyName` | string | Yes | — |
| `address` | string | Yes | — |
| `country` | string | Yes | ISO code (e.g., `"IN"`) |
| `state` | string | Yes | State code (e.g., `"DL"`) |
| `city` | string | Yes | — |
| `pincode` | string | No | — |
| `credits` | string | No | Initial credit balance |

**Response:**
```json
{
  "action": true,
  "message": "Admin created successfully",
  "data": {
    "uid": 10,
    "name": "Fleet Operator",
    "username": "fleet_operator",
    "email": "operator@fleet.co"
  }
}
```

---

#### List Admins

```
GET /superadmin/adminlist
```

**Response:**
```json
{
  "action": true,
  "message": "Admin list fetched",
  "data": [
    {
      "uid": 10,
      "Name": "Fleet Operator",
      "email": "operator@fleet.co",
      "username": "fleet_operator",
      "mobile_prefix": "+91",
      "mobile": "9876543210",
      "countrycode": "IN",
      "isemailvarified": true,
      "companyName": "Fleet Co",
      "fulladdress": "456 Track Avenue, New Delhi, DL, IN",
      "credits": 1000,
      "totalvehicles": 50,
      "status": true,
      "Lastlogin": "2026-03-08T09:00:00Z",
      "profileurl": "/uploads/users/10/avatar.jpg",
      "currency": "INR"
    }
  ]
}
```

---

#### Get Admin by ID

```
GET /superadmin/admin/:id
```

| Param | Type | Description |
|-------|------|-------------|
| `id` | number | Admin user ID |

---

#### Update Admin

```
POST /superadmin/updateadmin/:id
```

**Request Body:**
```json
{
  "name": "Updated Fleet Operator",
  "email": "updated@fleet.co",
  "mobilePrefix": "+91",
  "mobileNumber": "9876543211",
  "addressLine": "789 New Street",
  "countryCode": "IN",
  "stateCode": "MH",
  "cityName": "Mumbai",
  "pincode": "400001"
}
```

---

#### Update Admin Password

```
POST /superadmin/adminpasswordupdate
```

**Request Body:**
```json
{
  "adminid": "10",
  "newpassword": "NewSecureP@ss789",
  "confirmpassword": "NewSecureP@ss789"
}
```

---

#### Activate/Deactivate Admin

```
POST /superadmin/activateadmin/:id
```

**Request Body:**
```json
{
  "isActive": false
}
```

---

#### Impersonate Admin (Login As)

```
GET /superadmin/adminlogin/:id
```

**Response:** Full auth response with JWT token for the target admin.

---

#### Delete Admin

```
DELETE /superadmin/deleteadmin/:id
```

---

### 6.2 Credits & Billing

#### Assign/Deduct Credits

```
POST /superadmin/assigncredits/:id
```

**Request Body:**
```json
{
  "credits": "500",
  "activity": "ASSIGN"
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `credits` | string | Yes | Numeric amount |
| `activity` | string | Yes | `ASSIGN`, `DEDUCT` |

---

#### Get Credit Logs

```
GET /superadmin/creditlogs/:id
```

---

#### List Transactions

```
GET /superadmin/transactions
```

| Query Param | Type | Required | Description |
|-------------|------|----------|-------------|
| `adminId` | string | No | Filter by admin |
| `status` | string | No | Filter by status |
| `from` | string | No | ISO date start |
| `to` | string | No | ISO date end |
| `q` | string | No | Search query |
| `page` | string | No | Page number |
| `limit` | string | No | Items per page |

---

#### Transaction Analytics

```
GET /superadmin/transactions/analytics
```

| Query Param | Type | Required |
|-------------|------|----------|
| `adminId` | string | No |
| `from` | string | No |
| `to` | string | No |
| `month` | string | No |
| `year` | string | No |

---

#### Record Manual Transaction

```
POST /superadmin/transactions/manual
```

**Request Body:**
```json
{
  "adminId": 10,
  "amount": "500.00",
  "reference": "INV-2026-001",
  "paymentMode": "BANK_TRANSFER"
}
```

---

### 6.3 Configuration & Settings

#### Software Config

```
GET /superadmin/softwareconfig
```

```
PATCH /superadmin/softwareconfig
```

**Request Body:**
```json
{
  "geocodingPrecision": "THREE_DIGIT",
  "backupDays": 30,
  "allowDemoLogin": false,
  "allowSignup": true,
  "signupCredits": 100
}
```

| Field | Type | Values |
|-------|------|--------|
| `geocodingPrecision` | string | `TWO_DIGIT`, `THREE_DIGIT` |
| `backupDays` | number | Min 0 |
| `allowDemoLogin` | boolean | — |
| `allowSignup` | boolean | — |
| `signupCredits` | number | Max 2,000,000,000 |

---

#### SMTP Configuration

```
GET /superadmin/smtpsettings
```

```
PATCH /superadmin/smtpsettings
```

**Request Body:**
```json
{
  "senderName": "FleetStack Alerts",
  "host": "smtp.example.com",
  "port": 587,
  "email": "alerts@fleetstack.io",
  "type": "TLS",
  "username": "alerts@fleetstack.io",
  "password": "smtp-password",
  "replyTo": "support@fleetstack.io",
  "isActive": true
}
```

| Field | Type | Values |
|-------|------|--------|
| `type` | string | `NONE`, `SSL`, `TLS` |

---

#### Test SMTP

```
POST /superadmin/testsmtp
```

**Request Body:**
```json
{
  "email": "test@example.com"
}
```

---

#### Admin SMTP Config

```
GET /superadmin/smtpconfig/:adminId
PATCH /superadmin/smtpconfig/:adminId
```

---

#### Company Config

```
GET /superadmin/companyconfig/:adminId
PATCH /superadmin/companyconfig/:adminId
```

**Request Body:**
```json
{
  "name": "Fleet Co Updated",
  "websiteUrl": "https://fleet.co",
  "customDomain": "app.fleet.co",
  "socialLinks": {
    "facebook": "https://facebook.com/fleetco",
    "twitter": "https://twitter.com/fleetco"
  },
  "primaryColor": "#1E40AF"
}
```

---

#### Localization Settings

```
GET /superadmin/localization
PATCH /superadmin/localization
```

**Request Body:**
```json
{
  "language": "en",
  "layoutDirection": "LTR",
  "dateFormat": "DD/MM/YYYY",
  "use24Hour": true,
  "theme": "DARK",
  "timezoneOffset": "+05:30",
  "units": "KM",
  "defaultLat": 28.6139,
  "defaultLon": 77.209,
  "mapZoom": 12
}
```

---

#### White Label Settings

```
GET /superadmin/whitelabel
PATCH /superadmin/whitelabel
```

**Request Body (JSON or multipart):**
```json
{
  "customDomain": "app.fleet.co",
  "logoLightUrl": "https://cdn.fleet.co/logo-light.png",
  "logoDarkUrl": "https://cdn.fleet.co/logo-dark.png",
  "faviconUrl": "https://cdn.fleet.co/favicon.ico",
  "primaryColor": "#1E40AF"
}
```

---

### 6.4 Master Data Catalogs

#### Vehicle Types

```
GET    /superadmin/vehicletypes
POST   /superadmin/vehicletypes
PATCH  /superadmin/vehicletypes/:id
DELETE /superadmin/vehicletypes/:id
```

**Create/Update Body:**
```json
{
  "name": "Truck",
  "slug": "truck"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `name` | string | Yes | 2–60 chars |
| `slug` | string | Yes | Lowercase, hyphenated, 2–60 chars |

---

#### Device Types

```
GET    /superadmin/devicetypes
POST   /superadmin/devicetypes
PATCH  /superadmin/devicetypes/:id
DELETE /superadmin/devicetypes/:id
```

**Create/Update Body:**
```json
{
  "name": "GT06N",
  "port": 5023,
  "manufacturer": "Concox",
  "protocol": "GT06",
  "firmwareVersion": "3.0.1"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `name` | string | Yes | 2–80 chars |
| `port` | number | Yes | 1–65535 |
| `manufacturer` | string | No | 1–120 chars |
| `protocol` | string | No | 1–120 chars |
| `firmwareVersion` | string | No | 1–120 chars |

---

#### Command Types

```
GET    /superadmin/commandtypes
POST   /superadmin/commandtypes
PATCH  /superadmin/commandtypes/:id
DELETE /superadmin/commandtypes/:id
```

---

#### Custom Commands

```
GET    /superadmin/customcommands
POST   /superadmin/customcommands
PATCH  /superadmin/customcommands/:id
DELETE /superadmin/customcommands/:id
```

**Create/Update Body:**
```json
{
  "deviceTypeId": 1,
  "commandTypeId": 2,
  "command": "RELAY,1#",
  "isActive": true
}
```

| Query Param | Type | Description |
|-------------|------|-------------|
| `deviceTypeId` | string | Filter by device type |
| `commandTypeId` | string | Filter by command type |
| `activeOnly` | string | Only active commands |

---

#### System Variables

```
GET    /superadmin/systemvariables
POST   /superadmin/systemvariables
PATCH  /superadmin/systemvariables/:id
DELETE /superadmin/systemvariables/:id
```

**Create/Update Body:**
```json
{
  "name": "DEFAULT_SPEED_LIMIT",
  "initialValue": "80"
}
```

---

#### Document Types

```
GET    /superadmin/documenttypes
POST   /superadmin/documenttypes
PATCH  /superadmin/documenttypes/:id
DELETE /superadmin/documenttypes/:id
```

**Create/Update Body:**
```json
{
  "name": "Driver License",
  "docFor": "DRIVER"
}
```

| Field | Type | Values |
|-------|------|--------|
| `docFor` | string | `USER`, `DRIVER`, `VEHICLE` |

---

#### SIM Providers

```
GET    /superadmin/simproviders
POST   /superadmin/simproviders
PATCH  /superadmin/simproviders/:id
DELETE /superadmin/simproviders/:id
```

**Create/Update Body:**
```json
{
  "name": "Airtel IoT",
  "countryCode": "IN",
  "apnName": "airteliot.com",
  "apnUser": "",
  "apnPassword": ""
}
```

---

### 6.5 Email & Notification Templates

#### Email Templates

```
GET    /superadmin/emailtemplates
GET    /superadmin/emailtemplates/:id
PATCH  /superadmin/emailtemplates/:id
```

**Update Body:**
```json
{
  "emailSubject": "Your Vehicle {{vehicleName}} Alert",
  "message": "<p>Vehicle <b>{{vehicleName}}</b> triggered an alert at {{time}}.</p>"
}
```

---

#### App Notify Templates

```
GET    /superadmin/appnotifytemplates
GET    /superadmin/appnotifytemplates/:id
PATCH  /superadmin/appnotifytemplates/:id
```

**Update Body:**
```json
{
  "notifySubject": "Speed Alert: {{vehicleName}}",
  "message": "{{vehicleName}} exceeded speed limit at {{speed}} km/h"
}
```

---

#### WhatsApp Templates

```
GET    /superadmin/whatsapptemplates
GET    /superadmin/whatsapptemplates/:id
PATCH  /superadmin/whatsapptemplates/:id
GET    /superadmin/whatsapptemplates/meta
POST   /superadmin/whatsapptemplates/sync
```

| Query Param | Type | Description |
|-------------|------|-------------|
| `type` | string | Template type |
| `languageCode` | string | Language code |
| `isActive` | boolean | Active filter |

**Sync Body:**
```json
{
  "templateIds": [1, 2, 3],
  "dryRun": false
}
```

---

### 6.6 Third-Party Integrations

#### List Integrations

```
GET /superadmin/integrations
```

| Query Param | Type | Description |
|-------------|------|-------------|
| `scope` | string | `PLATFORM`, `ADMIN` |
| `adminId` | number | Required when scope=`ADMIN` |
| `category` | string | Integration category |
| `provider` | string | Provider name |

---

#### Upsert Integration

```
POST /superadmin/integrations
```

**Request Body:**
```json
{
  "scope": "PLATFORM",
  "category": "PUSH_NOTIFICATION",
  "provider": "FIREBASE",
  "name": "Firebase Cloud Messaging",
  "status": "ACTIVE",
  "isDefault": true,
  "priority": 1,
  "publicConfig": {
    "apiKey": "AIza...",
    "projectId": "my-project"
  },
  "secretJson": {
    "serviceAccountKey": "{ ... }"
  }
}
```

> `secretJson` is encrypted with AES-256-GCM before storage.

---

#### Update / Delete / Rotate Secret

```
PATCH  /superadmin/integrations/:id
DELETE /superadmin/integrations/:id
POST   /superadmin/integrations/:id/rotate-secret
```

---

#### Integration Tests

```
POST /superadmin/integrations/:id/test-fcm
POST /superadmin/integrations/:id/test-whatsapp
POST /superadmin/integrations/:id/test-openrouter
POST /superadmin/integrations/:id/validate-google-sso
POST /superadmin/integrations/:id/validate-geocoding
```

**Test FCM Body:**
```json
{
  "token": "fMr9K7...",
  "title": "Test Notification",
  "body": "FCM is configured correctly ✅"
}
```

**Test WhatsApp Body:**
```json
{
  "phoneNumber": "+919876543210",
  "mode": "template",
  "templateName": "hello_world",
  "languageCode": "en_US"
}
```

**Validate Geocoding Body:**
```json
{
  "lat": 28.6139,
  "lng": 77.209
}
```

---

### 6.7 Dashboard & Analytics

```
GET /superadmin/dashboard/totalcounts
GET /superadmin/dashboard/recentvehicles
GET /superadmin/dashboard/recentusers
GET /superadmin/dashboard/adoptiongraph
GET /superadmin/dashboard/activitylogs
```

**Total Counts Response:**
```json
{
  "action": true,
  "data": {
    "admins": 15,
    "vehicles": 500,
    "activeVehicles": 420,
    "users": 200,
    "licensesIssued": 600,
    "licensesUsed": 480
  }
}
```

**Activity Logs Query:**

| Query Param | Type | Description |
|-------------|------|-------------|
| `limit` | number | 5–50, default 20 |
| `cursorId` | number | Cursor for pagination |
| `actorId` | number | Filter by user |
| `from` | string | ISO date |
| `to` | string | ISO date |

---

### 6.8 Calendar Events

```
GET /superadmin/calendar/events
GET /superadmin/calendar/day
GET /superadmin/calendar/user/:uid
```

**Events Query:**

| Query Param | Type | Required | Description |
|-------------|------|----------|-------------|
| `from` | string | Yes | `YYYY-MM-DD` |
| `to` | string | Yes | `YYYY-MM-DD` (max 62 days) |
| `types` | string | No | Comma-separated: `USER_CREATED,VEHICLE_CREATED,VEHICLE_EXPIRY` |

---

### 6.9 Vehicle Lookup (by IMEI)

```
GET /superadmin/vehicles/by-imei/:imei/details
GET /superadmin/vehicles/by-imei/:imei/logs
GET /superadmin/vehicles/by-imei/:imei/trail
GET /superadmin/vehicles/by-imei/:imei/replay
GET /superadmin/vehicles/by-imei/:imei/history
GET /superadmin/vehicles/by-imei/:imei/sensors
GET /superadmin/vehicles/by-imei/:imei/events
```

**Trail Query:**

| Query Param | Type | Required | Description |
|-------------|------|----------|-------------|
| `hours` | string | No | Last N hours |
| `from` | string | No | ISO datetime |
| `to` | string | No | ISO datetime |
| `maxPoints` | string | No | Max trail points |

**Replay Query:**

| Query Param | Type | Required |
|-------------|------|----------|
| `from` | string | Yes |
| `to` | string | Yes |
| `maxPoints` | string | No |

**History Query:**

| Query Param | Type | Required | Description |
|-------------|------|----------|-------------|
| `from` | string | Yes | ISO datetime |
| `to` | string | Yes | ISO datetime |
| `stopMin` | string | No | Min stop duration (minutes) |
| `overspeedKph` | string | No | Speed threshold |
| `maxPoints` | string | No | Max data points |

---

### 6.10 Map & Telemetry

```
GET /superadmin/map-telemetry
GET /superadmin/telemetry
GET /superadmin/geofences
GET /superadmin/pois
GET /superadmin/routes
GET /superadmin/map-events
```

**Telemetry Query:**

| Query Param | Type | Description |
|-------------|------|-------------|
| `imeis` | string | Comma-separated IMEIs |

**Map Events Query:**

| Query Param | Type | Values |
|-------------|------|--------|
| `limit` | string | Max 100 |
| `beforeId` | string | Cursor |
| `from` | string | ISO datetime |
| `to` | string | ISO datetime |
| `source` | string | `SYSTEM`, `GEOFENCE`, `OVERSPEED`, `IGNITION`, `REMINDER`, `SENSOR`, `DRIVER`, `COMMAND` |
| `severity` | string | `INFO`, `WARNING`, `CRITICAL` |

---

### 6.11 Notifications

```
GET   /superadmin/notifications
PATCH /superadmin/notifications/read-all
PATCH /superadmin/notifications/:id/read
```

| Query Param | Type | Description |
|-------------|------|-------------|
| `limit` | string | Items per page |
| `beforeId` | string | Cursor |
| `unreadOnly` | string | `"true"` / `"false"` |

---

### 6.12 Device Commands

```
POST /superadmin/vehicles/by-imei/:imei/send-command
POST /superadmin/devices/:imei/send-command
GET  /superadmin/commands/status/:cmdId
```

**Send Command Body:**
```json
{
  "command": "RELAY,1#",
  "note": "Cut engine for vehicle ABC-123"
}
```

**Response:**
```json
{
  "action": true,
  "message": "Command sent",
  "data": {
    "cmdId": "cmd-uuid-123"
  }
}
```

---

### 6.13 License Management (FTKey)

```
GET  /superadmin/ftkey/status
POST /superadmin/ftkey/validate
POST /superadmin/ftkey/recheck
```

**Validate Body:**
```json
{
  "ftkey": "FTKEY-XXXX-XXXX-XXXX"
}
```

---

### 6.14 Support Tickets

```
GET    /superadmin/support/tickets
POST   /superadmin/support/tickets
GET    /superadmin/support/tickets/:id
POST   /superadmin/support/tickets/:id/messages
PATCH  /superadmin/support/tickets/:id/status
```

**Create Ticket Body:**
```json
{
  "title": "Server connectivity issue",
  "category": "SERVER",
  "priority": "HIGH",
  "message": "Backend service is intermittently dropping connections..."
}
```

**Reply Body:**
```json
{
  "message": "We are investigating the issue. Can you provide server logs?"
}
```

**Update Status Body:**
```json
{
  "status": "IN_PROGRESS"
}
```

---

### 6.15 Policies

```
POST  /superadmin/policy
PATCH /superadmin/policy
```

**Get Policy Body:**
```json
{
  "PolicyType": "PRIVACY_POLICY"
}
```

**Update Policy Body:**
```json
{
  "PolicyType": "PRIVACY_POLICY",
  "PolicyText": "<h1>Privacy Policy</h1><p>...</p>"
}
```

| Value | Description |
|-------|-------------|
| `PRIVACY_POLICY` | Privacy policy content |
| `SERVICE_TERMS` | Terms of service |
| `COOKIES` | Cookie policy |
| `REFUND` | Refund policy |

---

### 6.16 Server Management

```
GET  /superadmin/server/overview
POST /superadmin/server/actions
GET  /superadmin/server/jobs/:id
GET  /superadmin/server/jobs/:id/stream
```

**Server Action Body:**
```json
{
  "componentId": "frontend",
  "action": "restart"
}
```

| componentId | Allowed Actions |
|-------------|-----------------|
| `frontend` | `restart` |
| `backend` | `restart` |
| `listener` | `restart`, `start` |
| `nginx` | `restart`, `reload`, `start` |
| `redis` | `restart`, `start`, `stop` |
| `postgres` | `restart`, `start`, `stop` |

**SSE Stream:** `GET /superadmin/server/jobs/:id/stream`  
Content-Type: `text/event-stream`

---

### 6.17 Profile & Password

```
GET   /superadmin/profile
PATCH /superadmin/profile
PATCH /superadmin/updatepassword
```

**Update Password Body:**
```json
{
  "currentPassword": "OldP@ss123",
  "newPassword": "NewP@ss456"
}
```

---

### 6.18 Profile Verification

```
POST /superadmin/profile/verify/email/request
POST /superadmin/profile/verify/email/confirm
POST /superadmin/profile/verify/whatsapp/request
POST /superadmin/profile/verify/whatsapp/confirm
```

**Confirm OTP Body:**
```json
{
  "otp": "123456"
}
```

---

### 6.19 Email Subscription

```
GET  /superadmin/profile/email-subscription
POST /superadmin/profile/email-subscription/subscribe
```

---

### 6.20 Documents

```
POST   /superadmin/uploaddoc
PATCH  /superadmin/uploaddoc/:id
DELETE /superadmin/uploaddoc/:id
GET    /superadmin/documents/:adminId
POST   /superadmin/upload/:adminId
```

**Upload Document (multipart/form-data):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | binary | Yes | Document file |
| `title` | string | Yes | Max 255 chars |
| `fileName` | string | Yes | Max 255 chars |
| `docTypeId` | number | Yes | Document type ID |
| `description` | string | No | Max 1000 chars |
| `tags` | string | No | Max 2000 chars |
| `associateType` | string | Yes | `USER`, `DRIVER`, `VEHICLE` |
| `associateId` | number | Yes | Entity ID |
| `expiryAt` | string | No | ISO date |
| `isVisible` | boolean | No | — |
| `isVisibleDriver` | boolean | No | — |

---

### 6.21 Global Vehicles & Domains

```
GET /superadmin/vehicles
GET /superadmin/vehicles/:id
GET /superadmin/adminvehicles/:adminId
GET /superadmin/domainlist
```

---

### 6.22 Admin Settings

```
GET   /superadmin/settings/:adminId
PATCH /superadmin/settings/:adminId
```

---

### 6.23 Admin Activity Logs

```
GET /superadmin/admin/:id/activitylogs
```

| Query Param | Type | Description |
|-------------|------|-------------|
| `limit` | number | 5–50 |
| `cursorId` | number | Pagination cursor |
| `from` | string | ISO date |
| `to` | string | ISO date |
| `q` | string | Search |
| `actionPrefix` | string | Filter prefix |

---

### 6.24 OpenRouter AI Models

```
GET /superadmin/integrations/:id/openrouter/models
GET /superadmin/openrouter/models
POST /superadmin/integrations/:id/test-openrouter
```

---

### 6.25 Test Notifications

```
POST /superadmin/notifications/test-fcm-me
```

---

## 7. Admin APIs

> **Base Path:** `/admin`  
> **Auth Required:** Yes — Role: `ADMIN`  
> **Header:** `Authorization: Bearer <admin_jwt>`

### 7.1 Dashboard

#### Get Dashboard Summary

```
GET /admin/dashboard/summary
```

| Query Param | Type | Default | Description |
|-------------|------|---------|-------------|
| `months` | integer | 12 | Graph range (3–24) |
| `listLimit` | integer | 10 | List items (5–25) |
| `currency` | string | Auto | ISO 4217 code |

**Response:**
```json
{
  "action": true,
  "data": {
    "totalVehicles": 150,
    "totalUsers": 45,
    "lastMonthRevenue": { "amount": 25000, "currency": "INR" },
    "thisMonthRevenue": { "amount": 18500, "currency": "INR" },
    "pendingAmount": { "amount": 5200, "count": 12, "currency": "INR" },
    "expiryThisWeek": 5,
    "expiryThisMonth": 18,
    "expiryPreview": [
      {
        "id": 101,
        "name": "Truck-01",
        "plateNumber": "DL-01-AB-1234",
        "imei": "123456789012345",
        "secondaryExpiry": "2026-03-15T00:00:00Z",
        "primaryUser": { "uid": 20, "name": "Fleet Manager" },
        "plan": { "id": 1, "name": "Monthly", "price": 500, "currency": "INR" }
      }
    ],
    "deviceInstallsThisMonth": 8,
    "vehicleLiveStatus": {
      "total": 150,
      "running": 82,
      "stop": 35,
      "inactive": 20,
      "noData": 8,
      "noDevice": 5
    },
    "recentUsers": [],
    "recentVehicles": [],
    "recentPayments": [],
    "forecastRevenue": 45000,
    "availableCurrencies": ["INR", "USD"],
    "selectedCurrency": "INR",
    "topClients": [],
    "monthGraph": [
      { "month": "2026-01", "userCount": 3, "vehicleCount": 12 }
    ]
  }
}
```

---

### 7.2 User Management

#### List Users

```
GET /admin/users
GET /admin/shortusers
```

| Query Param | Type | Description |
|-------------|------|-------------|
| `search` | string | Filter by name/email/username |

---

#### Create User

```
POST /admin/users
```

**Request Body:**
```json
{
  "name": "Fleet Manager",
  "email": "manager@fleet.co",
  "mobilePrefix": "+91",
  "mobileNumber": "9876543210",
  "username": "fleet_manager",
  "password": "SecureP@ss123",
  "companyName": "Fleet Co",
  "address": "123 Fleet Street",
  "countryCode": "IN",
  "stateCode": "DL",
  "city": "New Delhi",
  "pincode": "110001"
}
```

---

#### Get / Update / Delete User

```
GET    /admin/users/:id
PATCH  /admin/users/:id
DELETE /admin/users/:id
```

---

#### Impersonate User

```
GET /admin/userlogin/:id
```

**Response:** JWT token for the target user.

---

#### Reset User Password

```
POST /admin/updateuserpassword/:id
```

**Request Body:**
```json
{
  "newPassword": "NewP@ss789"
}
```

---

### 7.3 Vehicle Management

#### List Vehicles

```
GET /admin/vehicles
```

---

#### Create Vehicle

```
POST /admin/vehicles
```

**Request Body:**
```json
{
  "name": "Truck-01",
  "vin": "1HGBH41JXMN109186",
  "plateNumber": "DL-01-AB-1234",
  "deviceId": 5,
  "vehicleTypeId": 1,
  "primaryUserId": 20,
  "planId": 3
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Max 120 chars |
| `vin` | string | No | Max 64 chars |
| `plateNumber` | string | No | Max 32 chars |
| `deviceId` | number | Yes | GPS device ID |
| `vehicleTypeId` | number | Yes | Vehicle type catalog ID |
| `primaryUserId` | number | Yes | Owner user ID |
| `planId` | number | Yes | Pricing plan ID |

---

#### Get / Update / Delete Vehicle

```
GET    /admin/vehicles/:id
PATCH  /admin/vehicles/:id
DELETE /admin/vehicles/:id
```

**Update Body:**
```json
{
  "name": "Truck-01 Updated",
  "plateNumber": "DL-01-AB-5678",
  "gmtOffset": "+05:30",
  "isActive": true,
  "attributes": { "color": "white", "model": "Tata Ace" }
}
```

---

#### Update Vehicle Config

```
PATCH /admin/vehicles/:id/config
```

**Request Body:**
```json
{
  "speedVariation": 5,
  "distanceVariation": 10,
  "odometer": 125000,
  "engineHours": 3500,
  "ignitionSource": "ACC"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `speedVariation` | number | Speed correction offset (km/h) |
| `distanceVariation` | number | Distance correction offset (meters) |
| `odometer` | number | Current odometer (km) |
| `engineHours` | number | Current engine hours |
| `ignitionSource` | string | `ACC` (accessory wire) or `MOTION` (accelerometer) |

---

### 7.4 Vehicle Sensors

```
GET    /admin/vehicles/:vehicleId/sensors
POST   /admin/vehicles/:vehicleId/sensors
PATCH  /admin/vehicles/:vehicleId/sensors/:sensorId
DELETE /admin/vehicles/:vehicleId/sensors/:sensorId
POST   /admin/vehicles/:vehicleId/sensors/run
GET    /admin/vehicles/:vehicleId/sensors/telemetry
```

**Create Sensor Body:**
```json
{
  "name": "Fuel Level",
  "unit": "L",
  "formula": "return payload.adc1 * 0.0625;",
  "dataType": "NUMBER",
  "isActive": true
}
```

**Run Sensor Body:**
```json
{
  "sensorId": 5,
  "telemetryData": {
    "adc1": 2048,
    "speed": 60,
    "latitude": 28.6139
  }
}
```

---

### 7.5 Device Management

```
GET    /admin/devices
POST   /admin/devices
PATCH  /admin/devices/:id
DELETE /admin/devices/:id
POST   /admin/quickdevice
GET    /admin/quickdevice
```

**Create Device Body:**
```json
{
  "imei": "123456789012345",
  "deviceTypeId": 1
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `imei` | string | Yes | 5–20 digits |
| `deviceTypeId` | number | Yes | Min 1 |

**Quick Device Body:**
```json
{
  "imei": "123456789012345",
  "deviceTypeId": 1,
  "simNumber": "8991234567890123456"
}
```

**Update Device Body:**
```json
{
  "simId": 10,
  "deviceTypeId": 2,
  "isActive": true,
  "status": "IN_USE"
}
```

---

### 7.6 SIM Card Management

```
GET    /admin/simcards
POST   /admin/simcards
GET    /admin/simcards/:id
PATCH  /admin/simcards/:id
DELETE /admin/simcards/:id
POST   /admin/deviceandsim
GET    /admin/quicksimcards
```

**Create SIM Body:**
```json
{
  "simNumber": "8991234567890123456",
  "imsi": "404110123456789",
  "providerId": "1",
  "iccid": "8991234567890123456F",
  "isActive": true,
  "status": "IN_STOCK"
}
```

**Create Device + SIM Together:**
```json
{
  "imei": "123456789012345",
  "deviceTypeId": 1,
  "simNumber": "8991234567890123456",
  "imsi": "404110123456789",
  "providerId": "1",
  "iccid": "8991234567890123456F"
}
```

---

### 7.7 Driver Management

```
POST   /admin/drivers
GET    /admin/drivers
GET    /admin/drivers/:id
GET    /admin/drivers/:id/users
PATCH  /admin/drivers/:id
DELETE /admin/drivers/:id
```

**Create Driver Body:**
```json
{
  "name": "Ramesh Kumar",
  "mobilePrefix": "+91",
  "mobile": "9876543210",
  "email": "ramesh@fleet.co",
  "primaryUserid": 20,
  "username": "ramesh_driver",
  "password": "DriverP@ss123",
  "countryCode": "IN",
  "stateCode": "DL",
  "city": "New Delhi",
  "address": "123 Driver Lane",
  "pincode": "110001"
}
```

---

### 7.8 Linking (Vehicle ↔ User ↔ Driver)

#### Vehicle-User Links

```
GET  /admin/linkvehicles/:userId        # Vehicles linked to user
POST /admin/linkvehicles/:userId        # Link vehicle → user
GET  /admin/unlinkvehicles/:userId      # Vehicles not linked to user
POST /admin/unlinkvehicles/:userId      # Unlink vehicle from user
```

**Link/Unlink Body:**
```json
{
  "vehicleId": 101
}
```

#### User-Vehicle Links (Reverse)

```
GET  /admin/linkusers/:vehicleId
POST /admin/linkusers/:vehicleId
GET  /admin/unlinkusers/:vehicleId
POST /admin/unlinkusers/:vehicleId
```

**Body:**
```json
{
  "userId": 20
}
```

#### Driver-User Links

```
GET  /admin/drivers/linkedusers/:driverId
GET  /admin/drivers/unlinkedusers/:driverId
POST /admin/drivers/linkedusers/:driverId
POST /admin/drivers/unlinkedusers/:driverId
```

```
GET  /admin/users/linkeddrivers/:userId
GET  /admin/users/unlinkeddrivers/:userId
POST /admin/users/linkeddrivers/:userId
POST /admin/users/unlinkeddrivers/:userId
```

---

### 7.9 Team Management

```
GET    /admin/teams
POST   /admin/teams
GET    /admin/teams/:id
PATCH  /admin/teams/:id
DELETE /admin/teams/:id
```

**Create Team Member Body:**
```json
{
  "name": "Support Agent",
  "email": "support@fleet.co",
  "mobilePrefix": "+91",
  "mobileNumber": "9876543210",
  "username": "support_agent",
  "password": "TeamP@ss123"
}
```

---

### 7.10 Bulk Operations

All bulk operations follow the same pattern: Create Job → Poll Status → Stream Progress → Download Failed CSV.

#### Vehicle Bulk Import

```
POST /admin/vehiclebulkjobs
GET  /admin/vehiclebulkjobs/:id
GET  /admin/vehiclebulkjobs/:id/failed.csv
GET  /admin/vehiclebulkjobs/:id/stream          (SSE)
```

**Request Body:**
```json
{
  "primaryUserId": "20",
  "planId": "3",
  "deviceTypeId": "1",
  "rows": [
    {
      "rowNumber": 1,
      "vehicleName": "Truck-01",
      "imei": "123456789012345",
      "simNumber": "8991234567890123456",
      "deviceType": "GT06N",
      "plateNumber": "DL-01-AB-1234",
      "vin": "1HGBH41JXMN109186"
    }
  ]
}
```

**Job Status Response:**
```json
{
  "action": true,
  "data": {
    "jobId": "bulk-uuid-123",
    "status": "processing",
    "total": 100,
    "processed": 45,
    "failed": 2,
    "results": []
  }
}
```

#### Inventory Bulk Import

```
POST /admin/inventorybulkjobs
GET  /admin/inventorybulkjobs/:id
GET  /admin/inventorybulkjobs/:id/failed.csv
GET  /admin/inventorybulkjobs/:id/stream
```

**Request Body:**
```json
{
  "target": "both",
  "deviceTypeId": "1",
  "providerId": "2",
  "rows": [
    {
      "rowNumber": 1,
      "imei": "123456789012345",
      "simNumber": "8991234567890123456",
      "imsi": "404110123456789",
      "iccid": "8991234567890123456F"
    }
  ]
}
```

| `target` Value | Description |
|----------------|-------------|
| `devices` | Import devices only |
| `simcards` | Import SIMs only |
| `both` | Import devices and SIMs |

#### Driver Bulk Import

```
POST /admin/driverbulkjobs
GET  /admin/driverbulkjobs/:id
GET  /admin/driverbulkjobs/:id/failed.csv
GET  /admin/driverbulkjobs/:id/stream
```

#### User Bulk Import

```
POST /admin/userbulkjobs
GET  /admin/userbulkjobs/:id
GET  /admin/userbulkjobs/:id/failed.csv
GET  /admin/userbulkjobs/:id/stream
```

---

### 7.11 Pricing Plans

```
GET   /admin/pricingplans
POST  /admin/pricingplans
PATCH /admin/pricingplans/:id
```

**Create/Update Body:**
```json
{
  "name": "Monthly Standard",
  "durationDays": 30,
  "price": 500.00,
  "currency": "INR"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `name` | string | Yes | 2–80 chars |
| `durationDays` | number | Yes | Min 1 |
| `price` | number | Yes | Min 0, decimal |
| `currency` | string | Yes | 3-letter ISO 4217 |

---

### 7.12 Transactions & Payments

```
GET  /admin/transactions
GET  /admin/transactions/analytics
GET  /admin/payments
POST /admin/payments/renew
```

**Renew Vehicles Body:**
```json
{
  "userId": 20,
  "vehicleIds": [101, 102, 103],
  "paymentMode": "CASH",
  "reference": "RCPT-2026-0045",
  "amountOverride": "1500.00"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | number | Yes | User making payment |
| `vehicleIds` | number[] | Yes | Vehicles to renew |
| `paymentMode` | string | No | `CASH`, `CREDIT_CARD`, `BANK_TRANSFER`, `WALLET` |
| `reference` | string | No | Receipt/reference number |
| `amountOverride` | string | No | Override calculated amount |

---

### 7.13 Map & Telemetry

```
GET /admin/map-telemetry
GET /admin/map-events
```

#### Vehicle by IMEI — Detailed APIs

```
GET /admin/vehicles/by-imei/:imei/details
GET /admin/vehicles/by-imei/:imei/logs
GET /admin/vehicles/by-imei/:imei/events
GET /admin/vehicles/by-imei/:imei/trail
GET /admin/vehicles/by-imei/:imei/replay
GET /admin/vehicles/by-imei/:imei/history
GET /admin/vehicles/by-imei/:imei/sensors
GET /admin/vehicles/by-imei/:imei/logs/export      → CSV
GET /admin/vehicles/by-imei/:imei/events/export     → CSV
```

**Trail Example:**
```
GET /admin/vehicles/by-imei/123456789012345/trail?hours=6&maxPoints=500
```

**Response:**
```json
{
  "action": true,
  "data": {
    "points": [
      { "lat": 28.6139, "lng": 77.209, "timestamp": "2026-03-08T04:00:00Z" },
      { "lat": 28.6150, "lng": 77.210, "timestamp": "2026-03-08T04:05:00Z" }
    ]
  }
}
```

**Replay Example:**
```
GET /admin/vehicles/by-imei/123456789012345/replay?from=2026-03-08T00:00:00Z&to=2026-03-08T12:00:00Z
```

**Response:**
```json
{
  "action": true,
  "data": [
    {
      "lat": 28.6139,
      "lng": 77.209,
      "speedKph": 45,
      "heading": 180,
      "timestamp": "2026-03-08T04:00:00Z"
    }
  ]
}
```

**CSV Export Headers:**
- `Content-Type: text/csv; charset=utf-8`
- `Content-Disposition: attachment; filename="..."`
- `X-Export-Truncated: true/false`
- `X-Export-Row-Cap: 50000`

---

### 7.14 Device Commands

```
POST /admin/vehicles/by-imei/:imei/send-command
GET  /admin/commands/status/:cmdId
```

**Send Command Body:**
```json
{
  "command": "RELAY,1#",
  "note": "Engine cut-off for vehicle Truck-01"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `command` | string | Yes | Max 500 chars |
| `note` | string | No | Max 500 chars |

**Response:**
```json
{
  "action": true,
  "message": "Command sent",
  "data": { "cmdId": "cmd-uuid-456" }
}
```

**Command Status Response:**
```json
{
  "data": {
    "cmdId": "cmd-uuid-456",
    "status": "DELIVERED",
    "sentAt": "2026-03-08T10:00:00Z",
    "deliveredAt": "2026-03-08T10:00:05Z"
  }
}
```

---

### 7.15 Notifications

```
GET   /admin/notifications
PATCH /admin/notifications/read-all
PATCH /admin/notifications/:id/read
```

---

### 7.16 Activity Logs

```
GET /admin/users/:id/activitylogs
GET /admin/logs/options
GET /admin/logs/activity
GET /admin/logs/events
GET /admin/logs/events/:id
GET /admin/logs/telemetry
GET /admin/logs/telemetry/:id
```

**Activity Logs Query:**

| Query Param | Type | Description |
|-------------|------|-------------|
| `limit` | integer | 5–50 |
| `cursorId` | integer | Cursor for pagination |
| `from` | string | ISO date |
| `to` | string | ISO date |
| `q` | string | Search text |
| `userId` | integer | Filter by user |
| `actionPrefix` | string | Action filter |
| `entity` | string | Entity type |

**Event Logs Query:**

| Query Param | Type | Values |
|-------------|------|--------|
| `limit` | integer | 1–200 |
| `source` | string | Event source filter |
| `severity` | string | `INFO`, `WARNING`, `CRITICAL` |
| `isRead` | boolean | — |
| `dedupe` | boolean | Deduplicate entries |

**Telemetry Logs Query:**

| Query Param | Type | Values |
|-------------|------|--------|
| `limit` | integer | 1–500 |
| `beforeId` | string | Cursor |
| `vehicleId` | integer | Filter by vehicle |
| `imei` | string | Filter by IMEI |
| `packetType` | string | `LOCATION`, `HISTORY`, `EVENT`, `UNKNOWN` |

---

### 7.17 Company & White Label

```
GET   /admin/companydetails/:id
PATCH /admin/companydetails/:id
PATCH /admin/companydetails
GET   /admin/config
PATCH /admin/config
GET   /admin/whitelabel
PATCH /admin/whitelabel
GET   /admin/localization
PATCH /admin/localization
```

---

### 7.18 SMTP Configuration

```
GET   /admin/smtpconfig
POST  /admin/smtpconfig
PATCH /admin/smtpconfig
POST  /admin/testsmtp
```

---

### 7.19 Profile & Verification

```
GET   /admin/profile
PATCH /admin/profile
POST  /admin/updatepassword
PATCH /admin/updatepassword
POST  /admin/profile/verify/email/request
POST  /admin/profile/verify/email/confirm
POST  /admin/profile/verify/whatsapp/request
POST  /admin/profile/verify/whatsapp/confirm
GET   /admin/profile/email-subscription
POST  /admin/profile/email-subscription/subscribe
```

---

### 7.20 Calendar Events

```
GET /admin/calendar/events
GET /admin/calendar/day
GET /admin/calendar/user/:uid
```

---

### 7.21 Documents

```
POST   /admin/upload
POST   /admin/uploaddoc
PATCH  /admin/uploaddoc/:id
DELETE /admin/uploaddoc/:id
GET    /admin/documents/:userId
GET    /admin/documents/vehicle/:vehicleId
GET    /admin/documents/driver/:driverId
```

---

### 7.22 Support Tickets

#### Admin → User Tickets

```
GET    /admin/tickets
POST   /admin/tickets
GET    /admin/tickets/:id
POST   /admin/tickets/:id/messages
PATCH  /admin/tickets/:id/status
```

#### Admin → Superadmin Tickets

```
GET    /admin/mytickets
POST   /admin/mytickets
GET    /admin/mytickets/:id
POST   /admin/mytickets/:id/messages
PATCH  /admin/mytickets/:id/status
```

**Create Ticket Body:**
```json
{
  "fromUserId": 20,
  "title": "Vehicle GPS not updating",
  "category": "INSTALLATION",
  "priority": "HIGH",
  "message": "Vehicle Truck-01 has not sent GPS data for 24 hours..."
}
```

---

### 7.23 Custom Commands & System Variables

```
GET /admin/customcommands
GET /admin/systemvariables
```

---

## 8. User APIs

> **Base Path:** `/user`  
> **Auth Required:** Yes — Role: `ADMIN`, `USER` (some endpoints `USER` only)  
> **Header:** `Authorization: Bearer <user_jwt>`

### 8.1 Vehicles

#### List Vehicles

```
GET /user/vehicles
```

**Response:**
```json
{
  "action": true,
  "message": "Vehicles fetched successfully",
  "vehicles": [
    {
      "id": 101,
      "name": "Truck-01",
      "vin": "1HGBH41JXMN109186",
      "plateNumber": "DL-01-AB-1234",
      "isActive": true,
      "createdAt": "2026-01-15T08:00:00Z",
      "imei": "123456789012345",
      "simNumber": "8991234567890123456",
      "vehicleType": "Truck",
      "device": {
        "imei": "123456789012345",
        "deviceTypeId": 1,
        "type": { "id": 1, "name": "GT06N", "protocol": "GT06" },
        "sim": { "simNumber": "8991234567890123456" }
      }
    }
  ]
}
```

---

#### Get Vehicle by ID

```
GET /user/vehicles/:id
```

**Response:**
```json
{
  "action": true,
  "vehicle": {
    "id": 101,
    "name": "Truck-01",
    "vin": "1HGBH41JXMN109186",
    "plateNumber": "DL-01-AB-1234",
    "isActive": true,
    "imei": "123456789012345",
    "vehicleType": 1,
    "vehicleMeta": { "color": "white", "model": "Tata Ace" },
    "gmtOffset": "+05:30",
    "device": {
      "id": 5,
      "imei": "123456789012345",
      "speedVariation": 5,
      "distanceVariation": 10,
      "odometer": 125000,
      "engineHours": 3500,
      "ignitionSource": "ACC"
    },
    "plan": {
      "id": 3,
      "name": "Monthly Standard",
      "price": 500,
      "currency": "INR"
    }
  }
}
```

---

#### Update Vehicle

```
PATCH /user/vehicles/:id
```

**Request Body:**
```json
{
  "name": "Truck-01 Updated",
  "plateNumber": "DL-01-CD-5678",
  "gmtOffset": "+05:30",
  "vehicleMeta": { "color": "blue" }
}
```

---

#### Update Vehicle Config

```
PATCH /user/vehicles/:id/config
```

**Request Body:**
```json
{
  "speedVariation": 5,
  "distanceVariation": 10,
  "odometer": 130000,
  "engineHours": 3600,
  "ignitionSource": "ACC"
}
```

---

#### Vehicle Telemetry / Documents

```
GET    /user/vehicles/:id/telemetry
GET    /user/vehicles/:id/documents
POST   /user/vehicles/:id/documents        (multipart/form-data)
PATCH  /user/vehicles/:id/documents/:docId  (multipart/form-data)
DELETE /user/vehicles/:id/documents/:docId
```

**Document Upload (multipart):**

| Field | Type | Required |
|-------|------|----------|
| `file` | binary | Yes (max 5MB) |
| `docTypeId` | number | Yes |
| `title` | string | No |
| `description` | string | No |
| `tags` | string | No |
| `expiryAt` | string | No |

> **Allowed MIME:** PDF, JPEG, PNG, WebP, DOCX, DOC

---

### 8.2 Vehicle Sensors

```
GET    /user/vehicles/:vehicleId/sensors
POST   /user/vehicles/:vehicleId/sensors
PATCH  /user/vehicles/:vehicleId/sensors/:sensorId
DELETE /user/vehicles/:vehicleId/sensors/:sensorId
POST   /user/vehicles/:vehicleId/sensors/run
GET    /user/vehicles/:vehicleId/sensors/telemetry
GET    /user/vehicles/:vehicleId/sensors/:sensorId/history
```

**Create Sensor Body:**
```json
{
  "name": "Fuel Level",
  "unit": "L",
  "icon": "fuel",
  "code": "return payload.adc1 * 0.0625;",
  "isActive": true
}
```

**Run Sensor (Test) Body:**
```json
{
  "code": "return payload.adc1 * 0.0625;",
  "payload": {
    "adc1": 2048,
    "speed": 60,
    "latitude": 28.6139
  }
}
```

**Response:**
```json
{
  "action": true,
  "message": "Run OK",
  "data": {
    "result": 128,
    "type": "number",
    "ms": 2
  }
}
```

**Sensor History Query:**

| Query Param | Type | Default | Description |
|-------------|------|---------|-------------|
| `from` | string | — | ISO datetime |
| `to` | string | — | ISO datetime |
| `maxPoints` | number | 250 | 50–600 |

**Sensor History Response:**
```json
{
  "action": true,
  "data": {
    "supported": true,
    "sensor": { "id": 5, "name": "Fuel Level", "unit": "L" },
    "range": { "from": "2026-03-07T00:00:00Z", "to": "2026-03-08T00:00:00Z" },
    "sampling": {
      "maxPoints": 250,
      "bucketSec": 345,
      "returnedPoints": 248,
      "errorCount": 0
    },
    "points": [
      { "t": "2026-03-07T00:05:45Z", "v": 65.5 },
      { "t": "2026-03-07T00:11:30Z", "v": 64.8 }
    ],
    "stats": {
      "min": 42.3,
      "max": 72.1,
      "avg": 58.9,
      "first": 65.5,
      "last": 48.2
    }
  }
}
```

---

### 8.3 Sub Users

> **Role:** `USER` only

```
GET    /user/subusers
POST   /user/subusers
GET    /user/subusers/:id
PATCH  /user/subusers/:id
DELETE /user/subusers/:id
GET    /user/subusers/:id/vehicles
POST   /user/subusers/:id/vehicles/assign
POST   /user/subusers/:id/vehicles/unassign
```

**Create Sub User Body:**
```json
{
  "name": "Office Staff",
  "username": "office_staff",
  "email": "staff@fleet.co",
  "mobilePrefix": "+91",
  "mobileNumber": "9876543210",
  "password": "StaffP@ss123",
  "isActive": true
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `name` | string | Yes | 2+ chars |
| `username` | string | No | 3+ chars |
| `email` | string | No | Valid email |
| `mobilePrefix` | string | No | — |
| `mobileNumber` | string | No | 7–15 digits |
| `password` | string | No | 6+ chars |
| `isActive` | boolean | No | Default: true |

**Assign Vehicles Body:**
```json
{
  "vehicleIds": [101, 102, 103]
}
```

---

### 8.4 Drivers

```
POST   /user/drivers
GET    /user/drivers
GET    /user/drivers/:id
PATCH  /user/drivers/:id
DELETE /user/drivers/:id
POST   /user/drivers/:id/assign-vehicle
POST   /user/drivers/:id/unassign-vehicle
GET    /user/drivers/:id/logs
GET    /user/drivers/:id/documents
POST   /user/drivers/:id/documents
PATCH  /user/drivers/:id/documents/:docId
DELETE /user/drivers/:id/documents/:docId
```

**Create Driver Body:**
```json
{
  "name": "Ramesh Kumar",
  "mobilePrefix": "+91",
  "mobile": "9876543210",
  "email": "ramesh@fleet.co",
  "username": "ramesh_driver",
  "password": "DriverP@ss123",
  "countryCode": "IN",
  "stateCode": "DL",
  "city": "New Delhi",
  "address": "123 Driver Lane"
}
```

**Assign Driver to Vehicle:**
```json
{
  "vehicleId": 101
}
```

---

### 8.5 Geofences

```
GET    /user/geofences
GET    /user/geofences/:id
POST   /user/geofences
PATCH  /user/geofences/:id
DELETE /user/geofences/:id
```

**Create Geofence Body (Circle):**
```json
{
  "name": "Warehouse Zone",
  "description": "50m radius around main warehouse",
  "type": "CIRCLE",
  "color": "#FF5722",
  "isActive": true,
  "geodata": {
    "kind": "CIRCLE",
    "center": { "lat": 28.6139, "lon": 77.209 },
    "radiusM": 50
  }
}
```

**Create Geofence Body (Polygon):**
```json
{
  "name": "City Boundary",
  "type": "POLYGON",
  "color": "#4CAF50",
  "geodata": {
    "kind": "POLYGON",
    "geometry": {
      "type": "Polygon",
      "coordinates": [
        [
          [77.20, 28.61],
          [77.22, 28.61],
          [77.22, 28.63],
          [77.20, 28.63],
          [77.20, 28.61]
        ]
      ]
    }
  }
}
```

---

### 8.6 Routes

```
GET    /user/routes
GET    /user/routes/:id
POST   /user/routes
PATCH  /user/routes/:id
DELETE /user/routes/:id
```

**Create Route Body:**
```json
{
  "name": "Delivery Route A",
  "color": "#2196F3",
  "toleranceMeters": 100,
  "geodata": {
    "kind": "LINE",
    "geometry": {
      "type": "LineString",
      "coordinates": [
        [77.209, 28.6139],
        [77.215, 28.618],
        [77.220, 28.625]
      ]
    },
    "toleranceM": 100
  }
}
```

---

### 8.7 Points of Interest (POIs)

```
GET    /user/pois
GET    /user/pois/:id
POST   /user/pois
PATCH  /user/pois/:id
DELETE /user/pois/:id
```

**Create POI Body:**
```json
{
  "name": "Main Warehouse",
  "description": "Central distribution warehouse",
  "category": "warehouse",
  "color": "#FF9800",
  "iconSlug": "warehouse",
  "toleranceMeters": 25,
  "coordinates": {
    "lat": 28.6139,
    "lon": 77.209
  }
}
```

---

### 8.8 Share Track Links

```
POST   /user/sharetracklinks
GET    /user/sharetracklinks
GET    /user/sharetracklinks/:id
PATCH  /user/sharetracklinks/:id
DELETE /user/sharetracklinks/:id
```

**Create Share Link Body:**
```json
{
  "vehicleIds": [101, 102],
  "expiryAt": "2026-03-15T23:59:59Z",
  "isGeofence": true,
  "isHistory": false
}
```

**Response:**
```json
{
  "action": true,
  "message": "Link created",
  "data": {
    "id": 5,
    "uniqueCode": "abc123xyz",
    "expiryAt": "2026-03-15T23:59:59Z",
    "isActive": true,
    "isGeofence": true,
    "isHistory": false,
    "vehicles": [
      { "id": 101, "name": "Truck-01", "plateNumber": "DL-01-AB-1234" },
      { "id": 102, "name": "Van-02", "plateNumber": "DL-02-CD-5678" }
    ],
    "vehiclesCount": 2,
    "finalUrl": "https://app.fleetstack.io/track/abc123xyz",
    "createdAt": "2026-03-08T10:00:00Z"
  }
}
```

---

### 8.9 Map & Telemetry

```
GET /user/map-telemetry
GET /user/map-events
```

#### Vehicle by IMEI

```
GET /user/vehicles/by-imei/:imei/details
GET /user/vehicles/by-imei/:imei/logs
GET /user/vehicles/by-imei/:imei/events
GET /user/vehicles/by-imei/:imei/trail
GET /user/vehicles/by-imei/:imei/replay
GET /user/vehicles/by-imei/:imei/history
GET /user/vehicles/by-imei/:imei/sensors
```

> Same query parameters and response shapes as [Admin Vehicle by IMEI APIs](#713-map--telemetry).

---

### 8.10 Notifications

> **Role:** `USER` only

```
GET   /user/notifications
PATCH /user/notifications/read-all
PATCH /user/notifications/:id/read
GET   /user/notifications/vehicle
PATCH /user/notifications/vehicle/read-all
PATCH /user/notifications/vehicle/:id/read
```

---

### 8.11 Notification Settings

```
GET /user/notification-settings
PUT /user/notification-settings
GET /user/notifications/preferences
PUT /user/notifications/preferences
```

**Update Settings Body:**
```json
{
  "settings": [
    {
      "eventType": "OVERSPEED",
      "notifyEmail": true,
      "notifyWhatsapp": false,
      "notifyWebPush": true,
      "notifyMobilePush": true,
      "notifyTelegram": false,
      "notifySms": false
    },
    {
      "eventType": "GEOFENCE",
      "notifyEmail": true,
      "notifyWhatsapp": true,
      "notifyWebPush": true,
      "notifyMobilePush": true,
      "notifyTelegram": false,
      "notifySms": false
    }
  ]
}
```

| Event Type | Description |
|------------|-------------|
| `IGNITION` | Ignition on/off alerts |
| `GEOFENCE` | Geofence entry/exit |
| `REMINDER` | Maintenance reminders |
| `OVERSPEED` | Speed limit violations |

---

### 8.12 Device Commands

```
GET  /user/customcommands
GET  /user/systemvariables
POST /user/commands/send-bulk
GET  /user/commands/status/:cmdId
```

**Bulk Send Command Body:**
```json
{
  "mode": "SELECTED",
  "vehicleIds": [101, 102],
  "command": "RELAY,1#",
  "note": "Engine cut-off for selected vehicles"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `mode` | string | Yes | `ALL` or `SELECTED` |
| `vehicleIds` | number[] | Conditional | Required when mode=`SELECTED` |
| `command` | string | No | Max 500 chars |
| `items` | array | No | Per-vehicle commands |
| `note` | string | No | Max 500 chars |

---

### 8.13 Dashboards (Custom Widget Layouts)

```
GET    /user/dashboards
GET    /user/dashboards/:id
POST   /user/dashboards
PUT    /user/dashboards/:id
DELETE /user/dashboards/:id
```

**Create Dashboard Body:**
```json
{
  "name": "My Fleet Overview"
}
```

**Update Dashboard Body:**
```json
{
  "name": "My Fleet Overview v2",
  "config": {
    "widgets": [
      { "id": "w1", "type": "fleet-status" },
      { "id": "w2", "type": "recent-alerts" }
    ],
    "layouts": {
      "lg": [
        { "i": "w1", "x": 0, "y": 0, "w": 6, "h": 4 },
        { "i": "w2", "x": 6, "y": 0, "w": 6, "h": 4 }
      ]
    }
  },
  "version": 2
}
```

> **Optimistic Locking:** Always send the current `version` number. Server rejects stale updates.

---

### 8.14 Dashboard Widgets

```
GET /user/dashboard/fleet-status
GET /user/dashboard/usage-last-7-days
GET /user/dashboard/weekly-comparison
GET /user/dashboard/recent-alerts
GET /user/dashboard/recent-alerts/:id
PATCH /user/dashboard/recent-alerts/:id/read
GET /user/dashboard/top-performing-assets
GET /user/dashboard/day-night-comparison
```

**Fleet Status Response:**
```json
{
  "action": true,
  "data": {
    "totalVehicles": 50,
    "withDevice": 48,
    "noDevice": 2,
    "buckets": {
      "running": 25,
      "idle": 8,
      "stopped": 10,
      "inactive": 3,
      "noData": 2,
      "connected": 33,
      "total": 48
    },
    "percentages": {
      "running": 52.1,
      "idle": 16.7,
      "stopped": 20.8,
      "inactive": 6.3,
      "noData": 4.2
    },
    "updatedAt": "2026-03-08T10:30:00Z"
  }
}
```

---

### 8.15 Landmark Bulk Import

```
POST /user/landmarkbulkjobs
GET  /user/landmarkbulkjobs/:id
GET  /user/landmarkbulkjobs/:id/failed.csv
GET  /user/landmarkbulkjobs/:id/stream
```

---

### 8.16 Support Tickets

```
GET  /user/tickets
POST /user/tickets
GET  /user/tickets/:id
POST /user/tickets/:id
```

**Create Ticket Body:**
```json
{
  "title": "Vehicle GPS not updating",
  "category": "INSTALLATION",
  "priority": "HIGH",
  "message": "Vehicle Truck-01 has not sent any data for the past 24 hours."
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `title` | string | Yes | Max 120 chars |
| `category` | string | Yes | `SERVER`, `NOTIFICATIONS`, `MAPS`, `BILLING`, `INSTALLATION`, `OTHER` |
| `priority` | string | No | `LOW`, `MEDIUM`, `HIGH` (default: `MEDIUM`) |
| `message` | string | Yes | Max 5000 chars |

**Reply Body:**
```json
{
  "message": "I have power cycled the device. Waiting for reconnection."
}
```

---

### 8.17 Transactions

```
GET /user/transactions
```

| Query Param | Type | Description |
|-------------|------|-------------|
| `status` | string | Filter by status |
| `from` | string | ISO datetime |
| `to` | string | ISO datetime |
| `q` | string | Search |
| `page` | string | Page number |
| `limit` | string | Items per page |

---

### 8.18 Profile & Settings

```
GET   /user/profile
PATCH /user/profile
POST  /user/upload                                    (multipart, profile image)
PATCH /user/updatepassword
PATCH /user/companydetails
GET   /user/localization
PATCH /user/localization
POST  /user/profile/verify/email/request
POST  /user/profile/verify/email/confirm
POST  /user/profile/verify/whatsapp/request
POST  /user/profile/verify/whatsapp/confirm
GET   /user/profile/email-subscription
POST  /user/profile/email-subscription/subscribe
POST  /user/notifications/test-fcm-me
```

---

## 9. Health APIs

> **Base Path:** `/health`  
> **Auth Required:** None

```
GET /health
GET /health/databases
GET /health/primary-db
GET /health/logs-db
GET /health/address-db
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-03-08T10:30:00Z",
  "service": "FleetStack Backend"
}
```

**Databases Response:**
```json
{
  "status": "ok",
  "databases": {
    "primary": { "status": "ok", "responseTime": 12 },
    "logs": { "status": "ok", "responseTime": 8 },
    "address": { "status": "ok", "responseTime": 5 }
  }
}
```

---

## 10. WebSocket (Real-time)

FleetStack uses **Socket.IO** for real-time communication.

### 10.1 Telemetry Gateway

**Namespace:** `/telemetry`  
**Auth:** JWT token sent on connection

**Connection:**
```javascript
const socket = io('wss://api.fleetstack.io/telemetry', {
  auth: { token: 'Bearer eyJhbGciOiJI...' }
});
```

**Events Received:**

| Event | Payload | Description |
|-------|---------|-------------|
| `telemetry_update` | `{ imei, lat, lng, speed, heading, timestamp, ... }` | Live vehicle position update |
| `vehicle_status` | `{ imei, status: "running"/"idle"/"stopped" }` | Vehicle status change |

---

### 10.2 Notification Gateway

**Namespace:** `/notifications`  
**Auth:** JWT token sent on connection

**Connection:**
```javascript
const socket = io('wss://api.fleetstack.io/notifications', {
  auth: { token: 'Bearer eyJhbGciOiJI...' }
});
```

**Events Received:**

| Event | Payload | Description |
|-------|---------|-------------|
| `notification` | `{ id, title, message, category, timestamp }` | New notification |
| `alert` | `{ vehicleId, type, severity, message, coordinates }` | Vehicle alert |

---

## 11. Data Models

### User

```typescript
{
  uid: number;
  name: string;
  email: string | null;
  username: string;
  mobilePrefix: string | null;
  mobileNumber: string | null;
  isEmailVerified: boolean;
  isMobileVerified: boolean;
  loginType: "SUPERADMIN" | "ADMIN" | "USER" | "SUBUSER" | "TEAM" | "DRIVER";
  parentUserId: number | null;
  isActive: boolean;
  profileUrl: string | null;
  credits: number;
  createdAt: string;  // ISO 8601
  updatedAt: string;
}
```

### Vehicle

```typescript
{
  id: number;
  name: string;
  vin: string | null;
  plateNumber: string | null;
  imei: string | null;
  deviceId: number | null;
  vehicleTypeId: number | null;
  primaryUserId: number | null;
  planId: number | null;
  addedByUserId: number;
  secondaryExpiry: string | null;  // ISO 8601
  gmtOffset: string | null;       // e.g. "+05:30"
  isActive: boolean;
  attributes: object | null;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
}
```

### Device

```typescript
{
  id: number;
  imei: string;
  deviceTypeId: number;
  simId: number | null;
  adminUserId: number;
  status: "IN_STOCK" | "IN_USE" | "IN_SCRAP";
  isActive: boolean;
  speedVariation: number | null;
  distanceVariation: number | null;
  odometer: number | null;
  engineHours: number | null;
  ignitionSource: "ACC" | "MOTION" | null;
  createdAt: string;
  updatedAt: string;
}
```

### SIM Card

```typescript
{
  id: number;
  simNumber: string | null;
  imsi: string | null;
  iccid: string | null;
  providerId: string | null;
  adminUserId: number;
  status: "IN_STOCK" | "IN_USE" | "IN_SCRAP";
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}
```

### Driver

```typescript
{
  id: number;
  name: string;
  email: string | null;
  mobileCode: string;
  mobile: string;
  username: string;
  isActive: boolean;
  isVerified: boolean;
  primaryUserId: number | null;
  createdByUserId: number;
  createdAt: string;
  updatedAt: string;
}
```

### Geofence

```typescript
{
  id: number;
  name: string;
  description: string | null;
  type: "POLYGON" | "CIRCLE" | "LINE";
  color: string | null;
  radius: number | null;
  toleranceMeters: number | null;
  isActive: boolean;
  userId: number;
  geodata: {
    kind: "CIRCLE" | "POLYGON" | "LINE";
    center?: { lat: number; lon: number };
    radiusM?: number;
    geometry?: GeoJSON;
    toleranceM?: number;
  } | null;
  createdAt: string;
  updatedAt: string;
}
```

### PricingPlan

```typescript
{
  id: number;
  name: string;
  price: number;
  currency: string;          // ISO 4217 (e.g., "INR", "USD")
  durationDays: number;
  adminUserId: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}
```

### Transaction

```typescript
{
  id: number;
  fromUserId: number;
  toUserId: number;
  amount: number;            // Decimal
  currency: string;
  status: "PENDING" | "SUCCESS" | "FAILED";
  reference: string | null;
  paymentMode: "CASH" | "CREDIT_CARD" | "BANK_TRANSFER" | "WALLET";
  createdAt: string;
  updatedAt: string;
}
```

### Ticket

```typescript
{
  id: number;
  ticketNo: string;
  title: string;
  status: "OPEN" | "IN_PROGRESS" | "CLOSED";
  category: "SERVER" | "NOTIFICATIONS" | "MAPS" | "BILLING" | "INSTALLATION" | "OTHER";
  priority: "LOW" | "MEDIUM" | "HIGH";
  fromUserId: number;
  toUserId: number | null;
  messages: TicketMessage[];
  createdAt: string;
  updatedAt: string;
  closedAt: string | null;
}
```

### Telemetry (Live)

```typescript
{
  imei: string;
  latitude: number;
  longitude: number;
  speed: number;             // km/h
  heading: number;           // 0-360 degrees
  altitude: number;
  accuracy: number;
  ignition: boolean;
  ac: boolean;
  door: boolean;
  satellites: number;
  batteryVoltage: number;
  signalStrength: number;
  serverTime: string;        // ISO 8601
  deviceTime: string;        // ISO 8601
  address: string | null;
}
```

---

## 12. Enumerations

### User Roles

| Value | Description |
|-------|-------------|
| `SUPERADMIN` | Platform owner (single instance) |
| `ADMIN` | Fleet operator / customer |
| `USER` | Fleet manager under an admin |
| `SUBUSER` | Restricted user under a user |
| `TEAM` | Team member under an admin |
| `DRIVER` | Driver linked to vehicles |

### Inventory Status

| Value | Description |
|-------|-------------|
| `IN_STOCK` | Available in inventory |
| `IN_USE` | Assigned to a vehicle |
| `IN_SCRAP` | Decommissioned |

### Transaction Status

| Value |
|-------|
| `PENDING` |
| `SUCCESS` |
| `FAILED` |

### Payment Mode

| Value |
|-------|
| `CASH` |
| `CREDIT_CARD` |
| `BANK_TRANSFER` |
| `WALLET` |

### Ticket Category

| Value |
|-------|
| `SERVER` |
| `NOTIFICATIONS` |
| `MAPS` |
| `BILLING` |
| `INSTALLATION` |
| `OTHER` |

### Ticket Priority

| Value |
|-------|
| `LOW` |
| `MEDIUM` |
| `HIGH` |

### Ticket Status

| Value |
|-------|
| `OPEN` |
| `IN_PROGRESS` |
| `CLOSED` |

### Geofence Type

| Value |
|-------|
| `POLYGON` |
| `CIRCLE` |
| `LINE` |

### Notification Event Types

| Value | Description |
|-------|-------------|
| `IGNITION` | Ignition on/off |
| `GEOFENCE` | Geofence entry/exit |
| `REMINDER` | Maintenance reminder |
| `OVERSPEED` | Speed limit exceeded |

### Map Event Source

| Value |
|-------|
| `SYSTEM` |
| `GEOFENCE` |
| `OVERSPEED` |
| `IGNITION` |
| `REMINDER` |
| `SENSOR` |
| `DRIVER` |
| `COMMAND` |

### Event Severity

| Value |
|-------|
| `INFO` |
| `WARNING` |
| `CRITICAL` |

### Theme

| Value |
|-------|
| `LIGHT` |
| `DARK` |
| `SYSTEM` |

### Layout Direction

| Value |
|-------|
| `LTR` |
| `RTL` |

### Distance Unit

| Value |
|-------|
| `KM` |
| `MILES` |

### Time Format

| Value |
|-------|
| `24H` |
| `12H` |

### SMTP Security Type

| Value |
|-------|
| `NONE` |
| `SSL` |
| `TLS` |

### Document Target

| Value |
|-------|
| `USER` |
| `DRIVER` |
| `VEHICLE` |

### Policy Type

| Value |
|-------|
| `PRIVACY_POLICY` |
| `SERVICE_TERMS` |
| `COOKIES` |
| `REFUND` |

### Ignition Source

| Value | Description |
|-------|-------------|
| `ACC` | Accessory wire (hardware ignition) |
| `MOTION` | Accelerometer-based detection |

### Geocoding Precision

| Value |
|-------|
| `TWO_DIGIT` |
| `THREE_DIGIT` |

---

## 13. Rate Limits & Constraints

| Endpoint | Limit |
|----------|-------|
| `POST /auth/forgot-password` | 3 per 15 min per identifier |
| `POST /auth/reset-password` | 5 attempts per token |
| File uploads | 5MB max per file, 5 files max |
| CSV exports | 50,000 rows max |
| Calendar events | 62-day range max |
| Bulk operations | Progress via SSE stream |

### Validation Rules

| Type | Rule |
|------|------|
| **Passwords** | 6–72 characters |
| **IMEI** | 5–20 digits |
| **Email** | RFC-compliant format |
| **Coordinates** | Lat: -90 to +90, Lon: -180 to +180 |
| **Dates** | ISO 8601 format |
| **Images** | PNG, JPEG, JPG, WebP |
| **Documents** | PDF, JPEG, PNG, WebP, DOCX, DOC |
| **Currency** | ISO 4217 (3 letters) |
| **Country** | ISO 3166-1 alpha-2 |

---

> **Document generated for FleetStack Mobile App Integration.**  
> **Confidential.** Do not distribute outside authorized development teams.
