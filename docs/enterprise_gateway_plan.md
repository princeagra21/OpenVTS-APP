# OpenVTS Mobile Enterprise Gateway Plan

## Current architecture score

**Current score:** 7.2 / 10

The codebase is past the raw legacy stage because direct `setState(` is 0, the architecture guard passes, feature API source methods no longer expose `Future<Object?>`, the map plus several admin/superadmin gateways are migrated, the offline/cache foundation exists, and the production security/config/logging gate is now in place. The final validation score is capped because remaining presentation files continue to use legacy facade imports, legacy error presentation, presentation cancellation handles, raw maps, legacy repository transport, and Flutter analyzer/tests could not run in this environment.

## Enterprise target score

**Target score:** 9.2 / 10

The target is reached when presentation has no repository transport dependency, API/business state is held by Riverpod controllers/notifiers, feature data sources expose typed DTO/envelope contracts, repositories map DTOs to domain models, errors are AppError/UI-effect based, cancellation is owned by controller/data lifecycles, production safety is enforced by guard/tests, and the allowlist is small enough for strict review.

## Current Enterprise Gateway Metrics

| Metric | Current value |
|---|---:|
| Direct `setState(` in `lib/features` + `lib/shared` | 0 |
| `updateLocalUiState(...)` calls in `lib/features` + `lib/shared` | 970 |
| `updateLocalUiState` presentation files | 172 |
| Migration allowlist entries | 43 |
| Active allowlisted warning files | 37 |
| Legacy facade import files in presentation | 33 |
| `Future<Object?>` methods in feature data sources | 0 |
| Feature data source files with `Future<Object?>` | 0 |
| `LegacyErrorPresenter` files in presentation | 32 |
| `LegacyErrorPresenter` occurrences in presentation | 155 |
| `AppCancellationHandle` files in presentation | 35 |
| `AppCancellationHandle` occurrences in presentation | 110 |
| `LegacyApiTransport` repository files | 32 |
| `LegacyApiTransport` occurrences in repositories | 32 |
| Offline cache Drift dependency present | 1 |
| Offline cache foundation files present | 8 |
| Vehicle local cache source files | 1 |
| Pending Drift generated parts | 1 |
| Production config validation in bootstrap | 1 |
| Production network logs rejected by validator | 1 |
| Production crash backend required by validator | 1 |
| Diagnostic interceptors gated by config | 1 |
| Production Noop observability blocked | 1 |
| Token redactor private-key rule present | 1 |
| Architecture guard warnings | 118 |

## Ordered migration gates

### Gate 1 — Continue error/effect cleanup

**Goal:** Remove `LegacyErrorPresenter` and `AppCancellationHandle` from the remaining highest-risk presentation files.

**Definition of Done:**
- Target files use `ErrorPresenter`, `UiEffect`, typed controller state, or Riverpod effects.
- No target file imports Dio/CancelToken or `AppCancellationHandle`.
- Guard passes and `legacy_error_presenter_presentation_files` / `app_cancellation_handle_presentation_files` decrease.

**Commands:**
```bash
dart format .
python3 tools/architecture_guard.py > architecture_guard_current_output.txt
flutter analyze --fatal-infos
flutter test
```

### Gate 2 — Remove remaining legacy facade imports

**Goal:** Replace `legacy_repository_facade_providers.dart` imports with feature-owned DI/use-case/controller providers.

**Definition of Done:**
- Target presentation files do not import the facade.
- Screens do not read repository implementation providers for API/business state.
- Allowlist entries are removed only when no other guarded violation remains.

**Commands:**
```bash
dart format .
python3 tools/architecture_guard.py > architecture_guard_current_output.txt
flutter analyze --fatal-infos
flutter test
```

### Gate 3 — Replace legacy transport repositories

**Current progress:** The first Legacy API Transport cluster has been migrated. The guard now reports `legacy_api_transport_repository_files: 32` and `migrated_repository_legacy_api_transport_files: 0`. The next pass should migrate the remaining repository clusters without weakening the global compatibility layer prematurely.

**Goal:** Move repositories from `LegacyApiTransport` to typed Retrofit services and mapper-based domain outputs.

**Definition of Done:**
- Repository implementation uses typed data source/service.
- DTO parsing is in data models/mappers.
- Domain/use cases return typed result models.

**Commands:**
```bash
dart format .
dart run build_runner build --delete-conflicting-outputs
python3 tools/architecture_guard.py > architecture_guard_current_output.txt
flutter analyze --fatal-infos
flutter test
```

### Gate 3B — Offline/cache expansion

**Current progress:** The offline/cache foundation has been added. Drift tables exist for vehicle lists, history points, and cache metadata. Vehicle list now has a safe read-only cache source and repository fallback. Vehicle detail and history range cache are intentionally not fully migrated in this slice.

**Goal:** Expand from vehicle-list fallback to vehicle details and history date-range caching without storing credentials or cross-tenant data.

**Definition of Done:**
- Vehicle detail cache uses the same tenant/user/environment scope.
- History range cache writes and queries by vehicle/date range.
- Logout clears tenant/user cache safely.
- Guard keeps credential columns out of local cache tables.

**Commands:**
```bash
dart format .
dart run build_runner build --delete-conflicting-outputs
python3 tools/architecture_guard.py > architecture_guard_current_output.txt
flutter analyze --fatal-infos
flutter test
```

### Gate 3C — Production security enforcement

**Current progress:** Bootstrap validation, production URL/logging/observability checks, redacted logging, deep-link hardening, and logout provider cleanup are now implemented and guard-protected.

**Goal:** Keep production safety non-negotiable while finishing migrations.

**Definition of Done:**
- Production cannot boot with localhost/emulator/private/dev/staging URLs.
- Production network logging and debug diagnostics remain disabled.
- Network logs and diagnostics pass through `TokenRedactor`.
- Production observability never returns Noop.
- Logout clears tokens/cache and invalidates socket/session providers.

**Commands:**
```bash
dart format .
python3 tools/architecture_guard.py > architecture_guard_current_output.txt
flutter analyze --fatal-infos
flutter test
```

### Gate 4 — Reduce raw presentation maps

**Goal:** Replace `Map<String, dynamic>` in migrated presentation paths with typed view models/entities.

**Definition of Done:**
- Migrated presentation files do not expose raw backend maps.
- Mapping occurs in data mappers or controller-level view models.
- Guard warnings decrease.

**Commands:**
```bash
dart format .
python3 tools/architecture_guard.py > architecture_guard_current_output.txt
flutter analyze --fatal-infos
flutter test
```

### Gate 5 — Final hardening

**Goal:** Convert warning-only categories into failures once their migration surface is small.

**Definition of Done:**
- Allowlist is reviewed file-by-file.
- Critical presentation boundary violations fail immediately.
- Analyzer/tests/build_runner pass locally.

**Commands:**
```bash
dart format .
dart run build_runner build --delete-conflicting-outputs
python3 tools/architecture_guard.py > architecture_guard_current_output.txt
flutter analyze --fatal-infos
flutter test
```
