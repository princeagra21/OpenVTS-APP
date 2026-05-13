# OpenVTS Mobile Architecture Status — Final Enterprise Validation

## Current score

**Architecture score:** 7.2 / 10  
**Enterprise target score:** 9.2 / 10

This status reflects the final gateway validation pass. The codebase still passes the architecture guard, direct `setState(` remains at 0, feature data-source `Future<Object?>` remains at 0, and the production bootstrap/config/logging/observability path is guard-protected. The score is lower than the previous optimistic gateway estimate because final validation still shows active allowlisted legacy presentation and transport debt, and Flutter analyzer/tests could not run in this environment.

## Current measured state

| Metric | Current value | Meaning |
|---|---:|---|
| Direct `setState(` count in `lib/features` + `lib/shared` | 0 | No direct widget `setState` calls remain in feature/shared code. |
| Centralized local UI update calls in `lib/features` + `lib/shared` | 970 | Remaining local UI-only updates are visible through `updateLocalUiState(...)`. |
| Centralized local UI update files in presentation | 172 | Files still using the local UI-state helper. |
| Migration allowlist entries | 43 | Files still temporarily tolerated by the architecture guard. |
| Active allowlisted warning files | 37 | Allowlisted files that still actively emit legacy warnings. |
| Legacy facade import files in presentation | 33 | Presentation files still importing `legacy_repository_facade_providers.dart`. |
| `Future<Object?>` methods in feature data sources | 0 | Non-generated feature source services expose typed contracts. |
| Feature data source files with `Future<Object?>` | 0 | No non-generated feature data-source file still exposes `Future<Object?>`. |
| `LegacyErrorPresenter` files in presentation | 32 | Remaining files still using the legacy error facade. |
| `LegacyErrorPresenter` occurrences in presentation | 155 | Total remaining legacy error presenter references. |
| `AppCancellationHandle` files in presentation | 35 | Remaining files still using presentation cancellation handles. |
| `AppCancellationHandle` occurrences in presentation | 110 | Total remaining presentation cancellation handle references. |
| `LegacyApiTransport` repository files | 32 | Repository implementations still using the legacy transport bridge. |
| `LegacyApiTransport` occurrences in repositories | 32 | Total legacy transport references. |
| Offline cache Drift dependency present | 1 | `drift`, `sqlite3_flutter_libs`, and `drift_dev` are declared for the cache foundation. |
| Offline cache foundation files present | 8 | Database, tables, providers, policies, keys, and vehicle local source are present. |
| Vehicle local cache source files | 1 | Vehicle list has a read-only local source for stale fallback. |
| Pending Drift generated parts | 1 | `app_database.g.dart` is intentionally pending local `build_runner`; it was not manually created. |
| Production config validation in bootstrap | 1 | `AppConfigValidator` runs before app initialization. |
| Production network logs rejected by validator | 1 | Production cannot boot with network logs enabled. |
| Production crash backend required by validator | 1 | Production must enable at least one crash backend. |
| Diagnostic interceptors gated by config | 1 | Diagnostic Dio interceptors are gated by `enablePerformanceDiagnostics`. |
| Production Noop observability blocked | 1 | Production provider path cannot return `NoopObservabilityService`. |
| Token redactor private-key rule present | 1 | PEM/private-key-like values are redacted. |
| Production security gate files present | 6 | Bootstrap, validator, Dio, observability, and redactor files are present. |
| Architecture guard warnings | 118 | Current non-failing migration warnings printed by the guard. |
| Architecture guard result | Passing | Current violations are either blocked, warning-only, or still allowlisted. |

## What this slice changed

- Added bootstrap-level production config validation before app/container initialization.
- Strengthened `AppConfigValidator` to reject production localhost/emulator/private/dev/staging URLs, missing socket/API URLs, enabled network logs, enabled debug diagnostics, disabled observability, and disabled crash reporting.
- Gated `SafeDioLoggingInterceptor` behind `enableNetworkLogs` and gated diagnostic Dio interceptors behind `enablePerformanceDiagnostics`.
- Strengthened token redaction for bearer tokens, JSON/map secrets, query-string secrets, private key blocks, and sensitive personal/address fields where applicable.
- Hardened deep-link validation against untrusted hosts, embedded credentials, traversal/encoded path payloads, and sensitive token query parameters.
- Made production observability provider return `ProductionObservabilityService` for production, never `NoopObservabilityService`.
- Added logout cleanup hook to invalidate socket/access-token providers after successful logout, while existing repository logout still clears secure tokens and Drift cache.
- Strengthened `tools/architecture_guard.py` with production safety checks and metrics.
- Added/updated tests for config validation, redaction/log metadata, deep-link safety, and logout cleanup behavior.

## Exact remaining enterprise blockers

1. **Legacy presentation facade dependency:** 33 presentation files still import `legacy_repository_facade_providers.dart`.
2. **Legacy UI error side effects:** 32 presentation files still use `LegacyErrorPresenter`.
3. **Manual cancellation lifecycle:** 35 presentation files still use `AppCancellationHandle`.
4. **Legacy repository transport:** 32 repository files still depend on `LegacyApiTransport`.
5. **Allowlist reliance:** 43 files remain in `tools/migration_allowlist.txt`; 37 still emit active allowlisted warnings.
6. **Warning volume:** 118 architecture guard warnings remain and must be reduced through measured gates.
7. **Generated code regeneration pending:** local `build_runner` must regenerate `*.g.dart`, including `app_database.g.dart`, before analyzer/test validation.
8. **Offline cache adoption is foundational only:** vehicle list fallback is wired, but vehicle detail and history range cache are table-ready rather than fully migrated.

## Commands for current verification

```bash
dart format .
dart run build_runner build --delete-conflicting-outputs
python3 tools/architecture_guard.py > architecture_guard_current_output.txt
flutter analyze --fatal-infos
flutter test
```

In this environment, `python3 tools/architecture_guard.py` is the only command that can be executed because Flutter/Dart are not installed.


## Latest updateLocalUiState Precision Pass

- `updateLocalUiState` grep references in `lib/features` + `lib/shared`: 970
- Presentation files still using `updateLocalUiState`: 172
- Audit-classified probable business/API usages: 466
- Direct `setState(` in `lib/features` + `lib/shared`: 0
- Non-generated `Future<Object?>` in feature sources: 0

See `UPDATE_LOCAL_UI_STATE_FILE_LEVEL_FIX_REPORT.md` for the file-level migration summary.
