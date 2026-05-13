# OpenVTS Flutter Application Architecture & Implementation Rules

> **Product:** OpenVTS Flutter Mobile Application  
> **Purpose:** A GitHub Copilot development contract for consistent architecture, state management, API integration, real-time telemetry, map performance, security, and production readiness.  
> **Architecture target:** Feature-first Clean Architecture with Riverpod-driven state, typed API boundaries, strict UI/data separation, and real-time GPS performance discipline.

---

## 0. How GitHub Copilot must use this document

This document is not a general Flutter article. It is the implementation rulebook for this codebase.

When Copilot creates or edits code, it must:

1. Respect the current OpenVTS folder structure.
2. Keep presentation, domain, data, infrastructure, and shared UI boundaries clean.
3. Never add direct API/data dependencies to presentation.
4. Use Riverpod providers/notifiers for state and dependency injection.
5. Use typed Retrofit services and DTO/request models.
6. Use `Result<T, AppError>` or `AsyncValue<T>` at the correct boundary.
7. Keep real-time telemetry out of widgets.
8. Keep map performance as an architecture concern.
9. Preserve production security gates and log redaction.
10. Update tests/architecture checks when changing patterns.

---

## 1. Current codebase reality from uploaded review

### 1.1 Project scale

The uploaded `flutter-app` project contains:

| Area | Observed state |
|---|---:|
| Dart files under `lib/` | 1,234 |
| Total Dart lines under `lib/` | ~201k |
| Major feature modules | admin, superadmin, user, auth, map, vehicles, support, settings, documents, localization, admin_tools, reference_data |
| Current state library | Riverpod 2 + generator |
| Navigation | GoRouter |
| Network | Dio + Retrofit |
| Models | Freezed/json_serializable mix |
| Realtime | Socket.IO client |
| Maps | flutter_map + latlong2 |
| Cache/storage | secure storage, shared preferences, Hive, Drift foundation |
| Observability | Sentry/Firebase Crashlytics style foundation |

### 1.2 Current strengths

The current app already has:

- `main.dart` separated from `bootstrap.dart` and `app.dart`.
- App-wide `ProviderScope`.
- `AppConfigValidator` during bootstrap.
- central `AppRouter` and route guard logic.
- secure token storage foundation.
- Dio/Retrofit/generator dependencies.
- OpenVTS theme tokens and shared UI components.
- map telemetry buffer/deduplicator/throttling foundation.
- Drift database foundation.
- production observability and redaction foundations.
- `setState(` removed from feature/shared code and replaced by `updateLocalUiState` helper.

### 1.3 Current blockers discovered in this uploaded codebase

The architecture guard currently fails on:

```text
Presentation imports data: 9 files
Raw Retrofit @Body() Map: 1 method
```

Exact current presentation-to-data imports:

```text
lib/features/admin_tools/presentation/api_config/api_config_controller.dart
lib/features/documents/presentation/controllers/document_form_controller.dart
lib/features/documents/presentation/screens/document_form_screen.dart
lib/features/documents/presentation/widgets/document_form_view.dart
lib/features/localization/presentation/controllers/localization_controller.dart
lib/features/localization/presentation/screens/localization_screen.dart
lib/features/support/presentation/ticket_details/ticket_details_controller.dart
lib/features/support/presentation/ticket_details/ticket_details_screen.dart
lib/features/user/presentation/screens/vehicles/vehicle_details_screen.dart
```

Exact current raw Retrofit body issue:

```text
lib/features/support/data/sources/support_new_ticket_api_service.dart
  Future<ApiResponse<void>> createAdminMyTicket(@Body() Map<String, dynamic> body);
```

Other migration debt still visible:

| Finding | Count |
|---|---:|
| `updateLocalUiState` refs | 973 |
| `LegacyErrorPresenter` refs | 156 |
| `AppCancellationHandle` refs | 131 |
| `LegacyApiTransport` refs | 44 |
| `Map<String, dynamic>` refs in presentation/shared areas | high enough to require migration discipline |
| Direct repository/provider usage from presentation | must keep being reduced |

This means new work must be stricter than old code. Do not copy legacy patterns.

---

## 2. Architecture north star

OpenVTS Mobile is not a simple CRUD app. It is an enterprise GPS/fleet platform with:

- live tracking,
- high-frequency telemetry,
- role-based modules,
- maps,
- history/replay,
- commands,
- alerts,
- offline/cache needs,
- admin/superadmin workflows,
- secure authentication,
- production diagnostics.

The architecture must optimize for:

1. **Change safety:** features can evolve without breaking others.
2. **Performance:** telemetry and maps do not create jank.
3. **Consistency:** every feature follows the same implementation shape.
4. **Security:** tokens, logs, cache, routes, and deep links are protected.
5. **Testability:** use cases, mappers, providers, and repositories are testable.
6. **Migration discipline:** legacy bridges shrink over time.

---

## 3. Canonical folder structure

The current codebase already uses this broad shape. Continue it.

```text
lib/
├── main.dart
├── bootstrap.dart
├── app.dart
├── core/
│   ├── api/
│   ├── application/
│   ├── auth/
│   ├── config/
│   ├── database/
│   ├── debug/
│   ├── diagnostics/
│   ├── di/
│   ├── error/
│   ├── network/
│   ├── notifications/
│   ├── observability/
│   ├── providers/
│   ├── router/
│   ├── security/
│   ├── services/
│   ├── session/
│   ├── socket/
│   ├── state/
│   ├── storage/
│   ├── telemetry/
│   ├── theme/
│   └── utils/
├── shared/
│   ├── models/
│   ├── presentation/
│   └── widgets/
└── features/
    ├── admin/
    ├── admin_tools/
    ├── auth/
    ├── documents/
    ├── localization/
    ├── map/
    ├── reference_data/
    ├── settings/
    ├── shell/
    ├── superadmin/
    ├── support/
    ├── user/
    └── vehicles/
```

### 3.1 Feature module contract

For any feature with real data/business logic, use this structure:

```text
features/<feature>/
├── application/                 # app-level orchestration if needed
├── data/
│   ├── models/                  # DTOs, request DTOs, response DTOs
│   ├── sources/                 # Retrofit APIs, local sources
│   ├── mappers/                 # DTO <-> domain mapping
│   └── repositories/            # implementations only
├── di/                          # provider wiring when feature uses DI split
├── domain/
│   ├── entities/                # business objects
│   ├── repositories/            # abstract interfaces/contracts
│   ├── use_cases/               # business/application actions
│   └── value_objects/           # IMEI, PlateNumber, etc.
└── presentation/
    ├── controllers/             # UI controllers if still used during migration
    ├── providers/               # Riverpod providers/notifiers
    ├── screens/
    ├── states/
    └── widgets/
```

### 3.2 Do not force layers for UI-only features

A tiny UI-only feature does not need fake data/domain layers. Add layers when there is:

- API access,
- local storage,
- business rules,
- mapping,
- role logic,
- reusable use case,
- external dependency.

---

## 4. Import boundary rules

### 4.1 Allowed dependency direction

```text
Presentation -> Domain -> Data
```

More explicitly:

```text
Widget/Screen
  -> Presentation provider/notifier/controller
    -> UseCase
      -> Domain repository interface
        -> Data repository implementation
          -> Data source / Retrofit / Local storage / Socket
```

### 4.2 Presentation may import

```text
features/<feature>/domain/entities/*
features/<feature>/domain/value_objects/*
features/<feature>/presentation/*
shared/widgets/*
shared/models/* only if pure presentation-safe
core/theme/*
core/router/route_names.dart
core/error/app_error.dart only for display-level mapping
core/state/update_local_ui_state.dart only for UI-only state
```

### 4.3 Presentation must not import

```text
features/*/data/*
core/api/*
Dio
Retrofit service classes
ApiClient
repository implementation classes
secure storage
Hive boxes
Drift database
Socket.IO raw service
LegacyApiTransport
```

### 4.4 Domain may import

```text
dart:* pure libraries
core/utils/result.dart
core/error/app_error.dart if infrastructure-neutral
other pure domain models/value objects
```

### 4.5 Domain must not import

```text
package:flutter
package:dio
package:retrofit
package:hive
package:drift
package:flutter_secure_storage
package:socket_io_client
features/*/data/*
features/*/presentation/*
core/api/*
```

### 4.6 Data may import

```text
Dio
Retrofit
DTOs
mappers
local storage services
socket service
core/api envelopes
core/error mapping
domain repository interfaces
domain entities for mapper output
```

---

## 5. Mandatory provider and dependency injection pattern

Use Riverpod as dependency injection.

### 5.1 Provider chain

```text
Config provider
  -> Dio provider
    -> Retrofit API service provider
      -> local source provider
      -> repository implementation provider
        -> use case provider
          -> notifier/provider
            -> screen/widget
```

### 5.2 Correct pattern

```dart
@riverpod
VehicleApiService vehicleApiService(VehicleApiServiceRef ref) {
  return VehicleApiService(ref.watch(dioProvider));
}

@riverpod
VehicleRepository vehicleRepository(VehicleRepositoryRef ref) {
  return VehicleRepositoryImpl(
    api: ref.watch(vehicleApiServiceProvider),
    localSource: ref.watch(vehicleLocalSourceProvider),
    mapper: const VehicleMapper(),
  );
}

@riverpod
GetVehiclesUseCase getVehiclesUseCase(GetVehiclesUseCaseRef ref) {
  return GetVehiclesUseCase(ref.watch(vehicleRepositoryProvider));
}

@riverpod
class VehicleListNotifier extends _$VehicleListNotifier {
  @override
  FutureOr<VehicleListState> build() async {
    final useCase = ref.watch(getVehiclesUseCaseProvider);
    final result = await useCase(page: 1, limit: 20);
    return result.fold(
      (data) => VehicleListState.loaded(data),
      (error) => VehicleListState.error(error),
    );
  }
}
```

### 5.3 Wrong pattern

```dart
class VehicleScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(vehicleRepositoryImplProvider); // wrong if impl/data
    final data = repo.getVehicles(); // wrong: API/data work from widget
    ...
  }
}
```

---

## 6. State management rules

### 6.1 State ownership

| State type | Owner |
|---|---|
| API loading/error/data | Riverpod Notifier/AsyncNotifier |
| Form draft values | Text controllers/local form state or form notifier depending complexity |
| Form submission | Riverpod Notifier/AsyncNotifier |
| Backend errors | repository/use case -> notifier -> UI error state |
| Current user/session | auth/session provider |
| Theme/locale/units | dedicated controller/provider |
| Live socket data | stream/provider pipeline with buffer/throttle |
| Map marker state | map telemetry provider/notifier |
| Temporary dropdown/animation/search field open state | local state allowed |

### 6.2 `updateLocalUiState` rule

The project removed direct `setState(` and uses `updateLocalUiState`.

Allowed usage:

- selected tab,
- dropdown open/close,
- password visibility,
- local animation toggle,
- map visual toggle,
- local search query text,
- temporary bottom sheet state,
- selected UI-only filter before applying.

Forbidden usage:

- loading,
- saving,
- submitting,
- deleting,
- API result,
- backend error,
- repository result,
- selected backend entity,
- socket-derived business data,
- permission state,
- auth/session state.

If a value survives route changes, comes from backend, affects business workflow, or should be testable, it does not belong in `updateLocalUiState`.

### 6.3 Async state pattern

Use `AsyncValue<T>` for simple read flows.

Use custom state classes for complex flows:

```dart
class VehicleListState {
  const VehicleListState({
    required this.items,
    required this.isLoading,
    required this.isRefreshing,
    required this.hasMore,
    required this.page,
    this.error,
  });

  final List<Vehicle> items;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasMore;
  final int page;
  final AppError? error;
}
```

### 6.4 Provider watch rules

Use `select()` for large state objects:

```dart
final isLoading = ref.watch(vehicleListProvider.select((s) => s.isLoading));
```

Avoid:

```dart
final state = ref.watch(vehicleListProvider); // if whole screen rebuilds for tiny change
```

---

## 7. API architecture rules

### 7.1 Retrofit services

Use generated abstract Retrofit services.

Correct:

```dart
part 'vehicle_api_service.g.dart';

@RestApi()
abstract class VehicleApiService {
  factory VehicleApiService(Dio dio) = _VehicleApiService;

  @GET('/admin/vehicles')
  Future<ApiResponse<VehicleListResponseDto>> getVehicles({
    @Query('page') required int page,
    @Query('limit') required int limit,
    @Query('search') String? search,
  });

  @POST('/admin/vehicles')
  Future<ApiResponse<VehicleDto>> createVehicle(
    @Body() CreateVehicleRequestDto body,
  );
}
```

Wrong:

```dart
@RestApi()
class VehicleApiService {
  VehicleApiService(this.dio);
  final Dio dio;

  Future<Object?> getVehicles() => dio.get('/admin/vehicles');
}
```

### 7.2 No raw request maps in Retrofit

Do not use:

```dart
@Body() Map<String, dynamic> body
```

Use:

```dart
@Body() CreateSupportTicketRequest body
```

Every request body must have a typed request DTO in `data/models` or `data/requests`.

### 7.3 DTO rules

DTOs represent API shape, not product meaning.

Rules:

- DTOs live in `data/models`.
- DTOs can use Freezed/json_serializable.
- DTOs can contain nullable fields matching backend reality.
- DTOs must not leak into presentation.
- DTOs map to domain entities through mappers.

### 7.4 Repository rules

Repositories:

- call API/local data sources,
- catch infrastructure errors,
- map DTOs to domain,
- return typed domain results,
- apply cache policy,
- do not show UI messages,
- do not know about widgets.

### 7.5 Use case rules

Use cases:

- express app-level actions,
- contain business rules,
- coordinate repositories if needed,
- remain pure enough to test,
- return `Result<T, AppError>` or typed output.

### 7.6 Widget API rules

Widgets/screens must not:

- parse raw JSON,
- call Dio,
- call Retrofit services,
- instantiate repositories,
- import `data/repositories`,
- catch Dio exceptions,
- convert API maps into UI objects.

---

## 8. Error handling rules

### 8.1 Error flow

```text
Dio/Storage/Socket error
  -> data layer catches it
    -> ErrorMapper converts to AppError
      -> repository returns Result.failure(AppError)
        -> notifier converts to UI state
          -> widget renders FSErrorView/OpenVTS feedback
```

### 8.2 Never show raw error data

Do not show:

- stack trace,
- Dio exception string,
- raw backend JSON,
- SQL/Prisma error,
- token/auth implementation detail.

### 8.3 LegacyErrorPresenter migration

`LegacyErrorPresenter` still exists in old screens. New code must not use it.

Target pattern:

```dart
state = state.copyWith(error: appError, isLoading: false);
```

Then UI renders:

```dart
FSErrorView(
  title: 'Could not load vehicles',
  message: ErrorPresenter.userMessage(error),
  onRetry: () => ref.read(vehicleListNotifierProvider.notifier).reload(),
)
```

Use feedback only for transient actions, not primary screen errors.

---

## 9. Authentication and session rules

### 9.1 Token rules

- Store access token and refresh token only in secure storage.
- Keep in-memory token cache only as an optimization.
- Never log tokens.
- Never place tokens in URLs.
- Never expose tokens to widgets.
- Clear all sensitive data on logout.
- Invalidate socket/session providers on logout.

### 9.2 Session restore

Flow:

```text
App start
  -> bootstrap config validation
  -> read token
  -> verify expiration
  -> extract role safely
  -> route to role home or onboarding/login
```

### 9.3 Session expiration

Current app has `SessionExpiredBus`. Use it carefully.

Rules:

- One session-expired notice at a time.
- Clear token storage.
- Disconnect socket.
- Clear user-specific cache.
- Navigate to login/onboarding.
- Do not leave user on protected route.

---

## 10. Navigation and routing rules

### 10.1 Router ownership

`core/router` owns:

- route paths,
- route names,
- role guards,
- initial location resolution,
- redirects.

Feature modules own screens and route groups where already established.

### 10.2 Route guard rule

Frontend route guards are UX. Backend remains security authority.

### 10.3 Role routing

Role home routes must be centralized. Do not duplicate role redirect logic inside screens.

### 10.4 Deep links and notification routes

Before navigation:

- validate route,
- validate role permission,
- validate payload,
- reject token-bearing query strings,
- reject unknown external hosts.

---

## 11. Real-time telemetry architecture

GPS mobile apps fail when raw socket data directly rebuilds UI.

### 11.1 Required pipeline

```text
Socket.IO raw event
  -> parser
    -> validator
      -> deduplicator
        -> freshness/stale packet filter
          -> telemetry buffer
            -> throttled marker state
              -> UI-ready map marker projection
                -> marker layer
```

The uploaded code already contains:

```text
lib/core/telemetry/telemetry_buffer.dart
lib/core/telemetry/telemetry_deduplicator.dart
lib/core/telemetry/telemetry_throttler.dart
lib/core/telemetry/telemetry_backpressure_policy.dart
lib/features/map/presentation/providers/map_telemetry_provider.dart
```

Do not bypass these.

### 11.2 Socket rules

- One socket connection per authenticated app session.
- Do not create socket connections inside screens.
- Do not subscribe repeatedly on every route push.
- Reconnect and resubscribe explicitly.
- Track connection state separately from telemetry data.
- Redact sensitive payloads from logs.

### 11.3 Backpressure rules

If telemetry arrives faster than UI can render:

1. Keep latest point per vehicle.
2. Drop intermediate UI frames.
3. Preserve important events/alerts separately.
4. Do not block UI thread.
5. Record diagnostics when packets are dropped.

### 11.4 Freshness rules

Live map should not show stale packets as live.

- Live marker state uses freshness policy.
- History/replay stores historical points separately.
- Stale data must be visually indicated.

---

## 12. Map architecture and performance rules

### 12.1 Map layer ownership

```text
TileLayer                            stable, rarely rebuilds
GeofenceLayer / POILayer             user toggles / data changes
RoutePolylineLayer                   history/replay data
LiveVehicleMarkerLayer               throttled marker state
SelectedVehicleOverlayLayer          selected vehicle only
MapControlsLayer                     UI-only toggles
BottomPanel/Sheet                    selected object details
```

### 12.2 Rebuild rules

- Do not rebuild `FlutterMap` for every telemetry packet.
- Do not rebuild `TileLayer` for marker changes.
- Marker layer can rebuild on throttled marker state.
- Selected vehicle panel should watch only selected vehicle data.
- Use `RepaintBoundary` around map/heavy layers.
- Use `ref.watch(provider.select(...))` for small rebuild scopes.

### 12.3 Marker rules

- Use UI-ready `MapVehiclePoint`/marker projection.
- Widget must not parse raw socket data.
- Marker animation belongs to marker layer.
- Marker color logic should be centralized.
- Vehicle icon asset resolution should be centralized.

### 12.4 Fleet size strategy

| Vehicle count | Strategy |
|---:|---|
| 1-100 | normal markers OK |
| 100-1000 | throttling + viewport filtering + optional clustering |
| 1000+ | viewport filtering, clustering, server-side search/filter, batched updates |

### 12.5 History/replay rules

- Fetch route/history in chunks or paginated ranges.
- Do not store massive raw history directly in widget state.
- Use compute/isolate for heavy simplification if needed.
- Preserve important points: start, end, stop, ignition transition, alerts, sharp turns.
- Render stoppage markers lazily for long routes.
- Keep replay animation state separate from route data.

---

## 13. Offline, cache, and local storage rules

### 13.1 Storage ownership

| Storage | Use |
|---|---|
| Secure storage | tokens, sensitive session info |
| SharedPreferences | theme, low-risk app preferences |
| Hive | simple app settings/cache where already used |
| Drift/SQLite | query-heavy cache, history ranges, telemetry/cache tables |
| Memory | live marker state, session-only UI state |

### 13.2 Cache rules

- Cache keys include user/admin/tenant/role where needed.
- Clear user-specific cache on logout.
- Never cache tokens in plain storage.
- Mark stale data clearly.
- Use stale-while-revalidate for safe list/detail data.
- Do not pretend cached GPS data is live.

### 13.3 Offline UX rules

- Show offline banner/indicator.
- Disable network-only actions.
- Allow read-only cached views where safe.
- Queue mutations only if intentionally implemented and tested.
- Show last synced time.

---

## 14. Security rules

### 14.1 Network security

- Production must use HTTPS.
- Production must not use localhost/private dev API URLs.
- Production network logs must be disabled.
- Certificate pinning can be enabled for enterprise deployments.
- Base URL and socket URL are config-driven, not hardcoded.

### 14.2 Logging redaction

Never log:

- access token,
- refresh token,
- password,
- OTP,
- private key,
- authorization header,
- full personal data,
- private addresses unless protected and necessary.

All logs must pass through redaction before external observability.

### 14.3 Deep link safety

Reject:

- unknown hosts,
- embedded credentials,
- traversal paths,
- encoded traversal,
- token query params,
- unexpected routes.

---

## 15. Push notification architecture

Notification flow:

```text
FCM received
  -> local notification service
    -> notification router
      -> validate route and permission
        -> navigate or show safe fallback
```

Rules:

- Register FCM token after login.
- Unregister on logout where possible.
- Handle foreground/background/terminated states.
- Validate deep link target.
- Do not navigate to unauthorized route.
- Notification payload must not contain secrets.

Notification types:

```text
alert
geofence
overspeed
support reply
payment/renewal
command response
system notice
```

---

## 16. Role and permission architecture

Roles:

```text
SUPERADMIN
ADMIN
USER
SUBUSER
TEAM
DRIVER
```

Permission rules:

- Define permissions centrally.
- UI uses permission provider/widget to hide/disable actions.
- Backend enforces permissions.
- Do not spread string permission checks across screens.
- Permission state comes from auth/session/domain, not local UI state.

Example permissions:

```text
viewVehicles
createVehicles
editVehicles
deleteVehicles
viewDrivers
createDrivers
manageUsers
manageAdmins
viewPayments
viewReports
sendCommands
viewServerConfig
```

---

## 17. Forms and validation architecture

### 17.1 Form ownership

Simple form:

- local `TextEditingController`,
- local validators,
- notifier for submission.

Complex form:

- form state notifier,
- typed draft state,
- typed request mapper,
- field-level validation.

### 17.2 Submission flow

```text
User taps submit
  -> validate local fields
    -> build typed request DTO/domain input
      -> notifier calls use case
        -> use case calls repository
          -> repository maps response
            -> notifier updates success/error state
              -> UI shows feedback or navigates
```

### 17.3 Form rules

- Prevent double submit.
- Use typed request models.
- Do not build `Map<String, dynamic>` in screens.
- Do not call repository from form widget.
- Keep file upload progress in notifier state.
- Clear field errors when field changes if appropriate.

---

## 18. Generated code rules

### 18.1 Generated files are disposable

Never manually maintain business logic inside:

```text
*.g.dart
*.freezed.dart
*.mocks.dart
```

Generated files must be regenerated by:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 18.2 No custom parsing in generated files

Helpers like these must not be manually added to generated files:

```text
_extractList
_extractMap
_jsonMap
```

Move parsing to:

```text
data/mappers/
data/models/
core/api/
```

---

## 19. Large file policy

A large file is not automatically wrong. A mixed-responsibility file is wrong.

Split a file when it mixes:

- UI + API calls,
- UI + raw JSON parsing,
- UI + repository logic,
- screen + reusable widgets,
- screen + token/storage access,
- map rendering + socket parsing,
- form UI + backend request mapping,
- unrelated widgets,
- hard-to-test logic.

Do not split only because a file has 500+ lines if it is cohesive and readable.

---

## 20. Migration policy for the current codebase

### Phase 1 — Stop new violations immediately

No new:

- presentation-to-data imports,
- raw `@Body() Map`,
- direct Dio in presentation,
- direct repository implementation in presentation,
- `LegacyErrorPresenter`,
- `LegacyApiTransport`,
- business/API state in `updateLocalUiState`,
- raw JSON parsing in widgets.

### Phase 2 — Fix active architecture guard failures

Fix these first:

```text
1. admin_tools presentation -> data import
2. documents presentation -> data imports
3. localization presentation -> data imports
4. support ticket details presentation -> data imports
5. user vehicle details presentation -> data import
6. support_new_ticket_api_service raw @Body() Map
```

Target fix:

- move repository contracts to domain,
- expose provider/use case in `di` or `presentation/providers`,
- presentation imports domain/provider only,
- create typed request DTO for support ticket body.

### Phase 3 — Reduce legacy facades

Shrink:

```text
legacy_repository_facade_providers.dart imports
LegacyErrorPresenter usage
AppCancellationHandle usage
LegacyApiTransport usage
```

One feature at a time.

### Phase 4 — Strengthen typed state and DTOs

- Replace `Map<String, dynamic>` in presentation with typed view models.
- Replace raw dynamic response handling with DTO/mappers.
- Add tests for mappers.

### Phase 5 — Production validation

Before release candidate:

```bash
dart format .
dart run build_runner build --delete-conflicting-outputs
python3 tools/architecture_guard.py
flutter analyze --fatal-infos
flutter test
```

---

## 21. Architecture guard requirements

The guard should fail on:

```text
lib/features/**/presentation/**/*.dart imports /data/
lib/features/**/presentation/**/*.dart imports core/api
lib/features/**/presentation/**/*.dart imports package:dio
lib/features/**/domain/**/*.dart imports package:flutter
lib/features/**/domain/**/*.dart imports package:dio
lib/features/**/domain/**/*.dart imports /data/
lib/features/**/domain/**/*.dart imports /presentation/
raw @Body() Map in Retrofit service
Future<Object?> in non-generated feature data sources
Dio calls inside screens/widgets
ApiClient calls inside screens/widgets
LegacyApiTransport in new repositories
LegacyErrorPresenter in new presentation files
```

Warnings may temporarily remain for allowlisted legacy files, but new files must be clean.

---

## 22. Testing rules

### 22.1 Test pyramid

| Test type | Required focus |
|---|---|
| Unit tests | value objects, mappers, validators, use cases |
| Repository tests | API success/error, mapping, cache fallback |
| Notifier tests | loading/success/error transitions |
| Widget tests | UI states with provider overrides |
| Integration tests | login, route guard, critical flows |
| Golden tests | design system components where stable |

### 22.2 Required test areas

- auth login success/failure,
- session restore,
- token expiry,
- route guard by role,
- vehicle list mapper,
- support ticket creation,
- command send result,
- socket deduplication,
- telemetry buffering,
- map marker projection,
- history route simplification,
- cache stale fallback,
- config validator.

---

## 23. Performance budget

| Area | Target |
|---|---|
| Cold start | under 3 seconds on mid-range Android |
| Auth restore to first role screen | under 2 seconds |
| Normal screen first render | under 1 second after route push |
| Vehicle list page size | 20-50 depending on payload |
| UI frame time | 16ms target |
| Heavy map frame time | 32ms acceptable during intense operations |
| Live map batch update | 250ms-1000ms |
| Dashboard metric refresh | 1s-5s depending on metric |
| Memory during live map | stable over long sessions |

Performance is not polish. In this app, performance is architecture.

---

## 24. Feature implementation template

When adding or migrating a feature, use this checklist.

### 24.1 Files to create/update

```text
features/<feature>/domain/entities/<entity>.dart
features/<feature>/domain/repositories/<feature>_repository.dart
features/<feature>/domain/use_cases/<action>_use_case.dart
features/<feature>/data/models/<entity>_dto.dart
features/<feature>/data/models/<action>_request.dart
features/<feature>/data/sources/<feature>_api_service.dart
features/<feature>/data/mappers/<feature>_mapper.dart
features/<feature>/data/repositories/<feature>_repository_impl.dart
features/<feature>/di/<feature>_providers.dart
features/<feature>/presentation/providers/<feature>_notifier.dart
features/<feature>/presentation/states/<feature>_state.dart
features/<feature>/presentation/screens/<feature>_screen.dart
features/<feature>/presentation/widgets/*
```

### 24.2 Mandatory checks

- Presentation imports no data files.
- Domain imports no Flutter/Dio/data/presentation.
- Retrofit body is typed.
- Mapper is testable.
- Repository maps all errors to `AppError`.
- Notifier owns loading/error/success.
- Widget only renders state and dispatches intents.
- UI uses OpenVTS shared components.
- Tests cover mapper and notifier for critical flows.

---

## 25. Copilot instruction block for architecture work

Use this block when asking Copilot to implement or refactor code:

```text
You are working on the OpenVTS Flutter mobile app.
Follow docs/OpenVTS_Flutter_Architecture_Implementation_Rules.md exactly.

Architecture target:
- Feature-first Clean Architecture.
- Riverpod for state management and dependency injection.
- GoRouter for navigation.
- Dio + Retrofit for typed APIs.
- DTOs/request models in data layer only.
- Domain entities and repository contracts in domain layer.
- Notifiers/providers own loading, error, and backend state.
- Widgets render state and dispatch intents only.

Non-negotiable rules:
- No presentation import from features/*/data/*.
- No direct Dio/Retrofit/API calls in widgets/screens.
- No raw @Body() Map; create typed request DTOs.
- No business/API state in updateLocalUiState.
- No new LegacyErrorPresenter, LegacyApiTransport, or legacy facade usage.
- No raw JSON parsing inside presentation.
- Keep socket/telemetry pipeline outside widgets.
- Keep map tile layer independent from marker updates.
- Preserve config validation, token redaction, and production logging guards.

Before finishing:
- Run or update tools/architecture_guard.py expectations.
- Ensure flutter analyze would pass.
- Add/update tests for mapper, repository, notifier, or widget where relevant.
```

---

## 26. Enterprise readiness checklist

The app becomes production-candidate only when:

### Architecture

- [ ] Architecture guard passes without active failures.
- [ ] Presentation imports no data layer.
- [ ] Domain is pure Dart.
- [ ] API services are generated Retrofit abstractions.
- [ ] Request bodies are typed DTOs.
- [ ] DTOs do not leak into presentation.
- [ ] Repository implementations live in data.
- [ ] Repository interfaces live in domain.
- [ ] Use cases own business flow.
- [ ] Widgets contain no business logic.

### State

- [ ] API loading/error/data state is not local UI state.
- [ ] `updateLocalUiState` is UI-only.
- [ ] Forms prevent double submit.
- [ ] Notifiers expose predictable states.
- [ ] Provider rebuild scopes are controlled.

### Realtime/map

- [ ] One socket session per auth session.
- [ ] Telemetry goes through parser/deduplicator/buffer.
- [ ] Map tile layer does not rebuild on each packet.
- [ ] Selected vehicle state is scoped.
- [ ] History route processing is not in widgets.

### Security

- [ ] Tokens only in secure storage.
- [ ] Logs are redacted.
- [ ] Production logs are disabled.
- [ ] Production config validation passes.
- [ ] Deep links are validated.
- [ ] Logout clears sensitive state and cache.

### Quality

- [ ] `dart format .` passes.
- [ ] build runner output is current.
- [ ] `flutter analyze --fatal-infos` passes.
- [ ] tests pass.
- [ ] critical flows have tests.
- [ ] UI follows the OpenVTS mobile design guidelines.
