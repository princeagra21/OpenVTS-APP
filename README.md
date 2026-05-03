# Open VTS Mobile (Flutter)

A production‑grade Flutter app for Open VTS. The project is organized by role‑based modules (`superadmin`, `admin`, `user`) with shared core services and UI utilities.

## Highlights
- Role‑based navigation and screens (Superadmin/Admin/User)
- API‑driven UI (Dio + repository layer)
- Consistent design system utilities (`AdaptiveUtils`, `AppUtils`)
- Local persistence (SharedPreferences + secure token storage)
- Shimmer loading states for data‑heavy views

## Project Structure
```
lib/
  core/                 # networking, repositories, models, storage, shared widgets
  modules/
    superadmin/         # superadmin screens & components
    admin/              # admin screens & components
    user/               # user screens & components
```

## Getting Started
### Prerequisites
- Flutter SDK (stable)
- Dart SDK (bundled with Flutter)

### Run
```bash
flutter pub get
flutter run -d <device> \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=<your_api_url>
```

## Environment
The app uses Dart defines (see `AppConfig.fromDartDefine()`):
- `APP_ENV`
- `API_BASE_URL`

## API Docs
Helpful references in the repo root:
- `FleetStack-API-Reference.md`
- `FleetStack-API-Reference-Missing.md`
- `FleetStack-Missing-APIs-Client-Report.md`

## Conventions
- UI text styles use `GoogleFonts.roboto`
- Layout sizing via `AdaptiveUtils` and `AppUtils`
- Data fetching via repository classes in `lib/core/repositories`

## Modules
See module documentation:
- `lib/modules/superadmin/README.md`
- `lib/modules/admin/README.md`
- `lib/modules/user/README.md`

---
© 2026 Open VTS. All rights reserved.
