# Final Enterprise Architecture Rating — OpenVTS Flutter

**Validation date:** 2026-05-12  
**Validated package:** `openvts_production_security_config_logging_gate.zip`  
**Validation mode:** final gateway audit; no large refactors performed.

## 1. Final score

**Final architecture score: 7.2 / 10**

This is a real improvement from the prompt23 baseline, but it is **not yet an enterprise production-candidate**. The codebase has strong gateway foundations now: direct `setState` is still zero, non-generated feature API services no longer expose `Future<Object?>`, the architecture guard passes, map telemetry has a safer buffer/projection boundary, production config/logging checks exist, and the offline/cache foundation has started.

The score is capped because the final static checks still show active legacy presentation-boundary and data-transport debt. `flutter analyze` and `flutter test --coverage` also could not be executed in this environment because Dart/Flutter are not installed.

## 2. Enterprise readiness verdict

**Verdict: Enterprise beta-ready**

It is not production-ready and not production-candidate yet because the project still has:

- `43` migration allowlist entries.
- `33` files importing `legacy_repository_facade_providers.dart`.
- `32` files referencing `LegacyErrorPresenter`.
- `39` files referencing `AppCancellationHandle` across `lib/features`.
- `36` files referencing `LegacyApiTransport` across `lib/features`.
- `17` files with direct presentation/shared `ref.read/watch(...RepositoryProvider...)` matches.
- `65` files with `Map<String, dynamic>` in presentation/shared areas.
- Flutter analyzer and test results unavailable in this environment.

## 3. What improved from the prompt23 baseline

| Area | Prompt23 / early gateway baseline | Final validation state |
|---|---:|---:|
| Direct `setState(` in `lib/features` + `lib/shared` | 0 | 0 |
| Non-generated feature data-source `Future<Object?>` methods | ~116 | 0 |
| Architecture guard warnings | ~203 | 118 |
| Migration allowlist entries | ~97 | 43 |
| Legacy facade import files in presentation | ~84-87 | 33 |
| `LegacyErrorPresenter` presentation files | ~77 | 32 |
| `AppCancellationHandle` presentation files | ~85 | 35 guard metric / 39 full `lib/features` static files |
| `LegacyApiTransport` repository files | ~49 | 32 guard metric / 36 full `lib/features` static files |
| Map telemetry architecture | broad rebuild risk | buffer/throttle/projection gate added |
| Offline/cache | Hive present only | Drift foundation + vehicle-list cache slice |
| Production security/logging | partial | bootstrap validation + redaction + production observability checks |

## 4. Command validation outputs

### `dart format .`

```text
$ dart format .
bash: line 1: dart: command not found
EXIT_CODE=127
```
### `dart run build_runner build --delete-conflicting-outputs`

```text
$ dart run build_runner build --delete-conflicting-outputs
bash: line 1: dart: command not found
EXIT_CODE=127
```
### `python3 tools/architecture_guard.py > architecture_guard_current_output.txt`

```text
$ python3 tools/architecture_guard.py > architecture_guard_current_output.txt
EXIT_CODE=0
```
### `flutter analyze --fatal-infos`

```text
$ flutter analyze --fatal-infos
bash: line 1: flutter: command not found
EXIT_CODE=127
```
### `flutter test --coverage`

```text
$ flutter test --coverage
bash: line 1: flutter: command not found
EXIT_CODE=127
```

## 5. Static check outputs

### `rg "setState\\(" lib/features lib/shared`

```text
$ rg "setState\\(" lib/features lib/shared
EXIT_CODE=1
```
### `rg "Future<Object\\?>" lib/features --glob '!*.g.dart'`

```text
$ rg "Future<Object\\?>" lib/features --glob "!*.g.dart"
EXIT_CODE=1
```
### `rg "legacy_repository_facade_providers\\.dart" lib`

```text
$ rg "legacy_repository_facade_providers\\.dart" lib
lib/features/admin/presentation/screens/home/home_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/admin/presentation/screens/dashboard/dashboard_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/admin/presentation/components/admin/application_setting/application_setting.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/admin/presentation/screens/more/more_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/admin/presentation/screens/plans/edit_plan_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/admin/presentation/screens/sims/sim_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/admin/presentation/screens/sims/add_sim_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/profile/profile_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/vehicle/widget/add_new_vehicle.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/transactions/record_manual_payment_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/user/presentation/screens/admin/screens/add_share_track.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/transactions/payments_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/user/presentation/screens/drivers/edit_driver_profile_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/user/presentation/screens/notification/vehicle_toggle_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/user/presentation/screens/profile/widget/update_password_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/user/presentation/screens/profile/widget/edit_admin_profile_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/user/presentation/screens/profile/widget/profile_verification_box.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/credit_history/admin_credit_history_tab.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/credit_history/credit_history_tab.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/vehicles_tab/vehicles_tab.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/calender/calender_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/credit_history/add_deduct_credit_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/application_setting/application_setting.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/payments_tab/admin_payments_tab.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/policy_edit/policy_edit.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/activity_tab/admin_activity_tab.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/payments_tab/add_admin_payment_record_screen.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/ssl/ssl.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/documents_tab/documents_tab.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/documents_tab/widget/file_card.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
lib/features/superadmin/presentation/components/admin/profile_tab/widget/delete_account_box.dart:import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
EXIT_CODE=0
```
### `rg "repository_bridge_providers\\.dart" lib`

```text
$ rg "repository_bridge_providers\\.dart" lib
EXIT_CODE=1
```
### `rg "LegacyErrorPresenter" lib/features`

```text
$ rg "LegacyErrorPresenter" lib/features
lib/features/documents/presentation/controllers/document_form_controller.dart:              LegacyErrorPresenter.isApiFailure(err) &&
lib/features/documents/presentation/controllers/document_form_controller.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403)
lib/features/documents/presentation/controllers/document_form_controller.dart:      if (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/documents/presentation/controllers/document_form_controller.dart:          (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403)) {
lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart:              (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart:              (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart:              (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/superadmin/presentation/components/admin/vehicles_tab/vehicles_tab.dart:              (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/admin/vehicles_tab/vehicles_tab.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/superadmin/presentation/components/transactions/record_manual_payment_screen.dart:      if (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/transactions/record_manual_payment_screen.dart:          (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403)) {
lib/features/superadmin/presentation/components/vehicle/widget/add_new_vehicle.dart:              (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/vehicle/widget/add_new_vehicle.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/superadmin/presentation/components/admin/payments_tab/admin_payments_tab.dart:          final msg = LegacyErrorPresenter.isApiFailure(err)
lib/features/superadmin/presentation/components/admin/payments_tab/admin_payments_tab.dart:              ? (LegacyErrorPresenter.message(err).isNotEmpty
lib/features/superadmin/presentation/components/admin/payments_tab/admin_payments_tab.dart:                    ? LegacyErrorPresenter.message(err)
lib/features/superadmin/presentation/components/transactions/payments_screen.dart:              (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/transactions/payments_screen.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/superadmin/presentation/components/transactions/payments_screen.dart:              (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/transactions/payments_screen.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/superadmin/presentation/components/admin/ssl/ssl.dart:              (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/admin/ssl/ssl.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/superadmin/presentation/components/admin/payments_tab/add_admin_payment_record_screen.dart:      if (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/admin/payments_tab/add_admin_payment_record_screen.dart:          (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403)) {
lib/features/superadmin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart:              (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/superadmin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart:                (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart:                    (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/superadmin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart:              (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/admin/presentation/components/admin/application_setting/application_setting.dart:          final msg = (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/admin/presentation/components/admin/application_setting/application_setting.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/admin/presentation/components/admin/application_setting/application_setting.dart:          final msg = (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/admin/presentation/components/admin/application_setting/application_setting.dart:                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/admin/presentation/screens/home/home_screen.dart:          if (LegacyErrorPresenter.isApiFailure(error) &&
lib/features/admin/presentation/screens/home/home_screen.dart:              (LegacyErrorPresenter.statusCode(error) == 401 || LegacyErrorPresenter.statusCode(error) == 403)) {
lib/features/admin/presentation/screens/dashboard/dashboard_screen.dart:            final status = LegacyErrorPresenter.isApiFailure(error) ? LegacyErrorPresenter.statusCode(error) : null;
lib/features/admin/presentation/screens/dashboard/dashboard_screen.dart:            final status = LegacyErrorPresenter.isApiFailure(error) ? LegacyErrorPresenter.statusCode(error) : null;
lib/features/superadmin/presentation/components/profile/profile_screen.dart:                (LegacyErrorPresenter.isApiFailure(err) &&
lib/features/superadmin/presentation/components/profile/profile_screen.dart:                    (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
lib/features/superadmin/presentation/components/admin/documents_tab/documents_tab.dart:              (LegacyErrorPresenter.isApiFailure(err) &&
... truncated in report; full command output saved at validation_outputs/static_check_5.txt (112 lines).
```
### `rg "AppCancellationHandle" lib/features`

```text
$ rg "AppCancellationHandle" lib/features
lib/features/map/application/open_vts_map_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/map/application/open_vts_map_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/map/application/open_vts_map_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/map/application/open_vts_map_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/map/application/open_vts_map_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/map/application/open_vts_map_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/map/application/open_vts_map_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/map/application/open_vts_map_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/map/application/open_vts_map_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/map/application/open_vts_map_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/map/application/open_vts_map_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/map/application/open_vts_map_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/admin_tools/application/server_status/server_status_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/user/di/user_profile_access_providers.dart:  Future<dynamic> getMyProfile({AppCancellationHandle? cancelToken}) {
lib/features/user/application/vehicle_details/vehicle_details_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/user/application/vehicle_details/vehicle_details_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/user/application/vehicle_details/vehicle_details_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/user/application/vehicle_details/vehicle_details_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/user/application/vehicle_details/vehicle_details_repository.dart:    AppCancellationHandle? cancelToken,
lib/features/documents/presentation/controllers/document_form_controller.dart:  AppCancellationHandle? _loadToken;
lib/features/documents/presentation/controllers/document_form_controller.dart:  AppCancellationHandle? _submitToken;
lib/features/documents/presentation/controllers/document_form_controller.dart:    final token = AppCancellationHandle();
lib/features/documents/presentation/controllers/document_form_controller.dart:    final token = AppCancellationHandle();
lib/features/settings/presentation/controllers/settings_profile_loader.dart:    AppCancellationHandle cancelToken,
lib/features/settings/presentation/controllers/settings_content_controller.dart:        AppCancellationHandle(),
lib/features/user/presentation/screens/notification/vehicle_toggle_screen.dart:  AppCancellationHandle? _loadToken;
lib/features/user/presentation/screens/notification/vehicle_toggle_screen.dart:  AppCancellationHandle? _saveToken;
lib/features/user/presentation/screens/notification/vehicle_toggle_screen.dart:    final token = AppCancellationHandle();
lib/features/user/presentation/screens/notification/vehicle_toggle_screen.dart:    final token = AppCancellationHandle();
lib/features/user/presentation/screens/drivers/edit_driver_profile_screen.dart:  AppCancellationHandle? _token;
lib/features/user/presentation/screens/drivers/edit_driver_profile_screen.dart:    final token = AppCancellationHandle();
lib/features/user/presentation/screens/admin/screens/add_share_track.dart:  AppCancellationHandle? _loadToken;
lib/features/user/presentation/screens/admin/screens/add_share_track.dart:  AppCancellationHandle? _saveToken;
lib/features/user/presentation/screens/admin/screens/add_share_track.dart:    final token = AppCancellationHandle();
lib/features/user/presentation/screens/admin/screens/add_share_track.dart:    final token = AppCancellationHandle();
lib/features/superadmin/presentation/components/vehicle/widget/add_new_vehicle.dart:  AppCancellationHandle? _pricingPlansCancellationHandle;
lib/features/superadmin/presentation/components/vehicle/widget/add_new_vehicle.dart:  AppCancellationHandle? _pricingPlansCapabilityCancellationHandle;
lib/features/superadmin/presentation/components/vehicle/widget/add_new_vehicle.dart:    final token = AppCancellationHandle();
lib/features/superadmin/presentation/components/vehicle/widget/add_new_vehicle.dart:    final token = AppCancellationHandle();
lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart:  AppCancellationHandle? _loadToken;
lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart:  AppCancellationHandle? _saveToken;
lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart:  AppCancellationHandle? _uploadToken;
lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart:    final token = AppCancellationHandle();
lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart:    final token = AppCancellationHandle();
... truncated in report; full command output saved at validation_outputs/static_check_6.txt (128 lines).
```
### `rg "LegacyApiTransport" lib/features`

```text
$ rg "LegacyApiTransport" lib/features
lib/features/settings/data/repositories/white_label_repository.dart:  final LegacyApiTransport api;
lib/features/admin_tools/application/server_status/server_status_repository.dart:  final LegacyApiTransport api;
lib/features/settings/data/repositories/app_preferences_repository.dart:  final LegacyApiTransport api;
lib/features/admin_tools/data/repositories/api_config_repository.dart:  final LegacyApiTransport api;
lib/features/superadmin/data/sources/superadmin_typed_api_transport.dart:/// LegacyApiTransport. It keeps older repository method signatures stable while
lib/features/auth/data/repositories/push_token_repository.dart:  final LegacyApiTransport api;
lib/features/auth/data/repositories/auth_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/sources/user_typed_api_transport.dart:/// LegacyApiTransport. It keeps older repository method signatures stable while
lib/features/admin/data/sources/admin_typed_api_transport.dart:/// LegacyApiTransport. It keeps older repository method signatures stable while
lib/features/admin/data/repositories/role_notifications_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_vehicle_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_vehicles_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_teams_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/repositories/user_transactions_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_support_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/repositories/user_support_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_simcards_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/repositories/user_subusers_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/repositories/user_share_track_links_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_pricing_plans_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/repositories/user_routes_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_drivers_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_payments_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_app_preferences_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/repositories/user_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_devices_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_dashboard_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_notification_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/repositories/user_localization_repository.dart:  final LegacyApiTransport api;
lib/features/admin/data/repositories/admin_localization_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/repositories/user_policy_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/repositories/user_landmarks_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/repositories/user_notification_preferences_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/repositories/user_home_repository.dart:  final LegacyApiTransport api;
lib/features/user/data/repositories/user_map_repository.dart:  final LegacyApiTransport api;
EXIT_CODE=0
```
### `rg "ref\\.(read|watch)\\([^)]*RepositoryProvider" lib/features/*/presentation lib/shared || true`

```text
$ rg "ref\\.(read|watch)\\([^)]*RepositoryProvider" lib/features/*/presentation lib/shared || true
lib/features/map/presentation/controllers/map_vehicle_details_controller.dart:    repository: ref.read(openVtsMapRepositoryProvider),
lib/features/shell/presentation/controllers/role_notifications_controller.dart:    final repository = _ref.read(shellRoleNotificationsRepositoryProvider(normalizedPath));
lib/features/shell/presentation/controllers/role_notifications_controller.dart:    final repository = _ref.read(shellRoleNotificationsRepositoryProvider(normalizedPath));
lib/features/shell/presentation/controllers/role_notifications_controller.dart:    final repository = _ref.read(shellRoleNotificationsRepositoryProvider(normalizedPath));
lib/features/superadmin/presentation/components/vehicle/VehicleDetailsScreen.dart:      _repo ??= ref.read(superadminVehicleRepositoryProvider);
lib/features/admin/presentation/controllers/admin_device_list_controller.dart:    final result = await _ref.read(adminDeviceRepositoryProvider).updateDeviceStatus(id, nextValue);
lib/features/superadmin/presentation/components/transactions/payments_screen.dart:  late final _repo = ref.read(superadminRepositoryProvider);
lib/features/user/presentation/screens/drivers/add_driver_screen.dart:    _commonRepo ??= ref.read(referenceDataRepositoryProvider);
lib/features/user/presentation/screens/route/add_landmark_screen.dart:    final repo = ref.read(userLandmarkRepositoryProvider);
lib/features/user/presentation/screens/notification/vehicle_toggle_screen.dart:  late final _repo = ref.read(userNotificationPreferencesRepositoryProvider);
lib/features/user/presentation/screens/profile/widget/edit_admin_profile_screen.dart:    _commonRepo ??= ref.read(referenceDataRepositoryProvider);
lib/features/superadmin/presentation/components/admin/role/role.dart:  late final _repo = ref.read(superadminSettingsRepositoryProvider);
lib/features/superadmin/presentation/components/admin/activity_tab/admin_activity_tab.dart:      final res = await ref.read(superadminRepositoryProvider)
lib/features/superadmin/presentation/components/admin/documents_tab/widget/file_card.dart:    final repo = ref.read(superadminRepositoryProvider);
lib/features/user/presentation/screens/sub_users/add_sub_user_screen.dart:    _commonRepo ??= ref.read(referenceDataRepositoryProvider);
lib/features/admin/presentation/screens/drivers/driver_details_screen.dart:              repository: ref.read(adminDriverRepositoryProvider),
lib/features/superadmin/presentation/components/admin/credit_history/add_deduct_credit_screen.dart:      final res = await ref.read(superadminRepositoryProvider)
lib/features/admin/presentation/screens/home/home_screen.dart:    _repo ??= ref.read(roleNotificationsRepositoryProvider(AppRoutePaths.adminNotifications));
lib/features/superadmin/presentation/components/admin/payments_tab/admin_payments_tab.dart:      final res = await ref.read(superadminRepositoryProvider)
EXIT_CODE=0
```
### `rg "Map<String, dynamic>" lib/features/*/presentation lib/shared || true`

```text
$ rg "Map<String, dynamic>" lib/features/*/presentation lib/shared || true
lib/shared/models/admin_profile.dart:  final Map<String, dynamic> raw;
lib/shared/models/admin_profile.dart:  Map<String, dynamic> get data {
lib/shared/models/admin_profile.dart:      final l1 = Map<String, dynamic>.from(level1.cast());
lib/shared/models/admin_profile.dart:        return Map<String, dynamic>.from(level2.cast());
lib/shared/models/admin_profile.dart:      final map = addr is Map<String, dynamic>
lib/shared/models/admin_profile.dart:          : Map<String, dynamic>.from(addr.cast());
lib/features/documents/presentation/widgets/file_card.dart:  final Map<String, dynamic>? document;
lib/features/documents/presentation/widgets/file_card.dart:  Map<String, dynamic> _legacyMap() {
lib/features/documents/presentation/widgets/file_card.dart:    Map<String, dynamic> doc,
lib/features/admin_tools/presentation/api_config/api_config_models.dart:  factory ApiConfigModel.fromMap(Map<String, dynamic> map) {
lib/features/admin_tools/presentation/api_config/api_config_models.dart:  Map<String, dynamic> toMap() {
lib/features/admin_tools/presentation/api_config/api_config_models.dart:  static Object? _pickRaw(Map<String, dynamic> map, List<String> keys) {
lib/features/admin_tools/presentation/api_config/api_config_models.dart:  static String _pickString(Map<String, dynamic> map, List<String> keys) {
lib/features/admin_tools/presentation/api_config/api_config_models.dart:  static bool? _pickBool(Map<String, dynamic> map, List<String> keys) {
lib/features/admin_tools/presentation/api_config/api_config_models.dart:  static int? _pickInt(Map<String, dynamic> map, List<String> keys) {
lib/features/user/presentation/controllers/user_sub_user_detail_controller.dart:    this.vehicles = const <Map<String, dynamic>>[],
lib/features/user/presentation/controllers/user_sub_user_detail_controller.dart:    this.allVehicles = const <Map<String, dynamic>>[],
lib/features/user/presentation/controllers/user_sub_user_detail_controller.dart:  final List<Map<String, dynamic>> vehicles;
lib/features/user/presentation/controllers/user_sub_user_detail_controller.dart:  final List<Map<String, dynamic>> allVehicles;
lib/features/user/presentation/controllers/user_sub_user_detail_controller.dart:    List<Map<String, dynamic>>? vehicles,
lib/features/user/presentation/controllers/user_sub_user_detail_controller.dart:    List<Map<String, dynamic>>? allVehicles,
lib/features/map/presentation/open_vts_map/widgets/vehicle_details_bottom_panel.dart:String _rawValue(Map<String, dynamic> raw, Object? key) {
lib/features/documents/presentation/screens/document_form_screen.dart:  final Map<String, dynamic> document;
lib/features/documents/presentation/screens/document_form_screen.dart:  final Map<String, dynamic> document;
lib/features/user/presentation/controllers/user_sub_user_form_controller.dart:  final List<Map<String, dynamic>> vehicles;
lib/features/user/presentation/controllers/user_sub_user_form_controller.dart:  final List<Map<String, dynamic>> allVehicles;
lib/features/user/presentation/controllers/user_sub_user_form_controller.dart:    List<Map<String, dynamic>>? vehicles,
lib/features/user/presentation/controllers/user_sub_user_form_controller.dart:    List<Map<String, dynamic>>? allVehicles,
lib/features/map/presentation/open_vts_map/open_vts_map_vehicle_helpers.dart:  String _rawText(Map<String, dynamic> raw, List<String> keys) {
lib/features/documents/presentation/controllers/document_form_controller.dart:  Map<String, dynamic> get document => input.initialDocument ?? const {};
lib/features/superadmin/presentation/screens/notifications/superadmin_notifications_screen.dart:    final next = Map<String, dynamic>.from(item.raw);
lib/features/vehicles/presentation/widgets/vehicle_documents_tab.dart:  late List<Map<String, dynamic>> _files;
lib/features/vehicles/presentation/widgets/vehicle_documents_tab.dart:  List<Map<String, dynamic>> _resolvedFiles(List<VehicleDocumentItem>? docs) {
lib/features/vehicles/presentation/widgets/vehicle_documents_tab.dart:    final mapped = <Map<String, dynamic>>[];
lib/features/settings/presentation/controllers/settings_profile_loader.dart:        ? Map<String, dynamic>.from((company['socialLinks'] as Map).cast())
lib/features/settings/presentation/controllers/settings_profile_loader.dart:  Map<String, dynamic> _toDynamicMap(Object? value) {
lib/features/settings/presentation/controllers/settings_profile_loader.dart:    if (value is Map<String, dynamic>) return value;
lib/features/settings/presentation/controllers/settings_profile_loader.dart:    final sources = <Map<String, dynamic>>[raw];
lib/features/settings/presentation/controllers/settings_profile_loader.dart:      final level1Map = Map<String, dynamic>.from(level1.cast());
lib/features/settings/presentation/controllers/settings_profile_loader.dart:        sources.add(Map<String, dynamic>.from(level2.cast()));
lib/features/settings/presentation/controllers/settings_profile_loader.dart:    final sources = <Map<String, dynamic>>[raw];
lib/features/settings/presentation/controllers/settings_profile_loader.dart:      final level1Map = Map<String, dynamic>.from(level1.cast());
lib/features/settings/presentation/controllers/settings_profile_loader.dart:        sources.add(Map<String, dynamic>.from(level2.cast()));
lib/features/settings/presentation/controllers/settings_profile_loader.dart:  Map<String, dynamic> _companyMap(AdminProfile profile) {
... truncated in report; full command output saved at validation_outputs/static_check_9.txt (228 lines).
```

## 6. Current guard summary

```text
Architecture guard passed.
Architecture guard metrics:
 - allowlist_category_appcancellationhandle: 35
 - allowlist_category_legacy_repository_facade_import: 33
 - allowlist_category_legacyerrorpresenter: 32
 - centralized_local_ui_state_updates: 178
 - migration_allowlist_active_warning_files: 37
 - migration_allowlist_files: 43
 - pending_drift_generated_parts: 1
Enterprise Gateway Metrics:
 - app_cancellation_handle_occurrences_in_presentation: 110
 - app_cancellation_handle_presentation_files: 35
 - diagnostic_interceptors_gated_by_config: 1
 - direct_setstate_calls_in_features_and_shared: 0
 - error_effect_migrated_app_cancellation_handle_files: 0
 - error_effect_migrated_legacy_error_presenter_files: 0
 - future_object_methods_in_feature_data_sources: 0
 - future_object_source_files: 0
 - legacy_api_transport_occurrences_in_repositories: 32
 - legacy_api_transport_repository_files: 32
 - legacy_error_presenter_occurrences_in_presentation: 155
 - legacy_error_presenter_presentation_files: 32
 - legacy_repository_facade_import_files_in_presentation: 33
 - legacy_repository_facade_import_occurrences_in_presentation: 33
 - map_presentation_app_cancellation_handle_files: 0
 - map_presentation_legacy_error_presenter_files: 0
 - map_presentation_legacy_facade_import_files: 0
 - map_presentation_raw_socket_subscription_refs: 0
 - migrated_repository_legacy_api_transport_files: 0
 - migration_allowlist_entries: 43
 - offline_cache_drift_dependency_present: 1
 - offline_cache_foundation_files_present: 8
 - offline_cache_vehicle_local_source_files: 1
 - production_config_validation_in_bootstrap: 1
 - production_crash_backend_required_by_validator: 1
 - production_network_logs_rejected_by_validator: 1
 - production_noop_observability_blocked: 1
 - production_security_gate_files_present: 6
 - token_redactor_private_key_rule_present: 1
 - update_local_ui_state_calls_in_features_and_shared: 1038
 - update_local_ui_state_calls_in_presentation: 1037
 - update_local_ui_state_presentation_files: 177
Architecture guard warnings: 118
 - Direct repository implementation type still appears in presentation: lib/features/admin_tools/presentation/api_config/api_config_controller.dart: ApiConfigRepository
 - Direct repository implementation type still appears in presentation: lib/features/localization/presentation/controllers/localization_controller.dart: LocalizationRepository
 - Direct repository implementation type still appears in presentation: lib/features/localization/presentation/screens/localization_screen.dart: LocalizationRepository
 - Direct repository implementation type still appears in presentation: lib/features/admin/presentation/screens/dashboard/dashboard_screen.dart: AdminDashboardRepository
 - Direct repository implementation type still appears in presentation: lib/features/admin/presentation/screens/home/home_screen.dart: RoleNotificationsRepository
 - Direct repository implementation type still appears in presentation: lib/features/superadmin/presentation/components/profile/profile_screen.dart: AuthRepository
 - Direct repository implementation type still appears in presentation: lib/features/superadmin/presentation/components/transactions/record_manual_payment_screen.dart: SuperadminRepository
 - Direct repository implementation type still appears in presentation: lib/features/superadmin/presentation/components/vehicle/widget/add_new_vehicle.dart: SuperadminRepository
 - Direct repository implementation type still appears in presentation: lib/features/superadmin/presentation/components/admin/calender/calender_screen.dart: SuperadminRepository
 - Direct repository implementation type still appears in presentation: lib/features/superadmin/presentation/components/admin/credit_history/admin_credit_history_tab.dart: SuperadminRepository
 - Direct repository implementation type still appears in presentation: lib/features/superadmin/presentation/components/admin/credit_history/credit_history_tab.dart: SuperadminRepository
 - Direct repository implementation type still appears in presentation: lib/features/superadmin/presentation/components/admin/documents_tab/documents_tab.dart: SuperadminRepository
 - Direct repository implementation type still appears in presentation: lib/features/superadmin/presentation/components/admin/payments_tab/add_admin_payment_record_screen.dart: SuperadminRepository
 - Direct repository implementation type still appears in presentation: lib/features/superadmin/presentation/components/admin/vehicles_tab/vehicles_tab.dart: SuperadminRepository
 - Direct repository implementation type still appears in presentation: lib/features/superadmin/presentation/components/admin/profile_tab/widget/delete_account_box.dart: SuperadminRepository
 - Direct repository implementation type still appears in presentation: lib/features/user/presentation/screens/vehicles/vehicle_details_screen.dart: UserVehiclesRepository
 - Direct repository implementation type still appears in presentation: lib/features/user/presentation/screens/profile/widget/profile_verification_box.dart: UserProfileRepository
 - Map<String, dynamic> still used in presentation: lib/features/admin_tools/presentation/api_config/api_config_models.dart
 - Map<String, dynamic> still used in presentation: lib/features/documents/presentation/controllers/document_form_controller.dart
 - Map<String, dynamic> still used in presentation: lib/features/documents/presentation/screens/document_form_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/documents/presentation/widgets/file_card.dart
 - Map<String, dynamic> still used in presentation: lib/features/settings/presentation/controllers/settings_profile_loader.dart
 - Map<String, dynamic> still used in presentation: lib/features/settings/presentation/widgets/settings_profile_company.dart
 - Map<String, dynamic> still used in presentation: lib/features/support/presentation/ticket_details/ticket_details_controller.dart
 - Map<String, dynamic> still used in presentation: lib/features/vehicles/presentation/widgets/vehicle_documents_tab.dart
 - Map<String, dynamic> still used in presentation: lib/features/map/presentation/open_vts_map/open_vts_map_vehicle_helpers.dart
 - Map<String, dynamic> still used in presentation: lib/features/map/presentation/open_vts_map/widgets/vehicle_details_bottom_panel.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/router/admin_routes.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/controllers/admin_account_command_controller.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/account/user.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/analytics/analytics_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/logs/logs_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/logs/log_details_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/more/more_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/notifications/admin_notifications_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/payments/collect_payment_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/plans/edit_plan_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/renewals/extend_license_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/renewals/renewal_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/renewals/renew_device_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/renewals/send_reminder_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/renewals/suspend_access_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/transactions/transaction_details_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/account/widget/admin_user_activity_tab.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/account/widget/admin_user_documents_tab.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/account/widget/admin_user_profile_tab.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/account/widget/edit_company_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/screens/account/widget/documents/file_card.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/components/admin/edit_admin_profile_screen.dart
 - Map<String, dynamic> still used in presentation: lib/features/admin/presentation/components/calender/calender_screen.dart
```

## 7. Exact remaining blocker files

### 7.1 Migration allowlist files — 43

- `lib/features/admin/presentation/components/admin/application_setting/application_setting.dart`
- `lib/features/admin/presentation/screens/dashboard/dashboard_screen.dart`
- `lib/features/admin/presentation/screens/home/home_screen.dart`
- `lib/features/admin/presentation/screens/more/more_screen.dart`
- `lib/features/admin/presentation/screens/plans/edit_plan_screen.dart`
- `lib/features/admin/presentation/screens/sims/add_sim_screen.dart`
- `lib/features/admin/presentation/screens/sims/sim_screen.dart`
- `lib/features/documents/presentation/controllers/document_form_controller.dart`
- `lib/features/settings/presentation/controllers/settings_action_handler.dart`
- `lib/features/settings/presentation/controllers/settings_content_controller.dart`
- `lib/features/settings/presentation/controllers/settings_profile_loader.dart`
- `lib/features/settings/presentation/widgets/settings_content.dart`
- `lib/features/superadmin/presentation/components/admin/activity_tab/admin_activity_tab.dart`
- `lib/features/superadmin/presentation/components/admin/application_setting/application_setting.dart`
- `lib/features/superadmin/presentation/components/admin/calender/calender_screen.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/add_deduct_credit_screen.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/admin_credit_history_tab.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/credit_history_tab.dart`
- `lib/features/superadmin/presentation/components/admin/documents_tab/documents_tab.dart`
- `lib/features/superadmin/presentation/components/admin/documents_tab/widget/file_card.dart`
- `lib/features/superadmin/presentation/components/admin/payments_tab/add_admin_payment_record_screen.dart`
- `lib/features/superadmin/presentation/components/admin/payments_tab/admin_payments_tab.dart`
- `lib/features/superadmin/presentation/components/admin/policy_edit/policy_edit.dart`
- `lib/features/superadmin/presentation/components/admin/profile_tab/widget/delete_account_box.dart`
- `lib/features/superadmin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart`
- `lib/features/superadmin/presentation/components/admin/ssl/ssl.dart`
- `lib/features/superadmin/presentation/components/admin/vehicles_tab/vehicles_tab.dart`
- `lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart`
- `lib/features/superadmin/presentation/components/profile/profile_screen.dart`
- `lib/features/superadmin/presentation/components/transactions/payments_screen.dart`
- `lib/features/superadmin/presentation/components/transactions/record_manual_payment_screen.dart`
- `lib/features/superadmin/presentation/components/vehicle/widget/add_new_vehicle.dart`
- `lib/features/support/presentation/controllers/support_controller.dart`
- `lib/features/support/presentation/ticket_details/ticket_details_controller.dart`
- `lib/features/support/presentation/ticket_details/ticket_details_state.dart`
- `lib/features/user/presentation/screens/admin/screens/add_share_track.dart`
- `lib/features/user/presentation/screens/drivers/edit_driver_profile_screen.dart`
- `lib/features/user/presentation/screens/notification/vehicle_toggle_screen.dart`
- `lib/features/user/presentation/screens/profile/profile_screen.dart`
- `lib/features/user/presentation/screens/profile/widget/edit_admin_profile_screen.dart`
- `lib/features/user/presentation/screens/profile/widget/profile_verification_box.dart`
- `lib/features/user/presentation/screens/profile/widget/update_password_screen.dart`
- `lib/features/user/presentation/screens/vehicles/vehicle_details/controller.dart`

### 7.2 Files still importing `legacy_repository_facade_providers.dart` — 33

- `lib/features/admin/presentation/screens/home/home_screen.dart`
- `lib/features/admin/presentation/screens/dashboard/dashboard_screen.dart`
- `lib/features/admin/presentation/components/admin/application_setting/application_setting.dart`
- `lib/features/admin/presentation/screens/more/more_screen.dart`
- `lib/features/admin/presentation/screens/plans/edit_plan_screen.dart`
- `lib/features/admin/presentation/screens/sims/sim_screen.dart`
- `lib/features/admin/presentation/screens/sims/add_sim_screen.dart`
- `lib/features/superadmin/presentation/components/profile/profile_screen.dart`
- `lib/features/superadmin/presentation/components/vehicle/widget/add_new_vehicle.dart`
- `lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart`
- `lib/features/superadmin/presentation/components/transactions/record_manual_payment_screen.dart`
- `lib/features/user/presentation/screens/admin/screens/add_share_track.dart`
- `lib/features/superadmin/presentation/components/transactions/payments_screen.dart`
- `lib/features/user/presentation/screens/drivers/edit_driver_profile_screen.dart`
- `lib/features/user/presentation/screens/notification/vehicle_toggle_screen.dart`
- `lib/features/user/presentation/screens/profile/widget/update_password_screen.dart`
- `lib/features/user/presentation/screens/profile/widget/edit_admin_profile_screen.dart`
- `lib/features/user/presentation/screens/profile/widget/profile_verification_box.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/admin_credit_history_tab.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/credit_history_tab.dart`
- `lib/features/superadmin/presentation/components/admin/vehicles_tab/vehicles_tab.dart`
- `lib/features/superadmin/presentation/components/admin/calender/calender_screen.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/add_deduct_credit_screen.dart`
- `lib/features/superadmin/presentation/components/admin/application_setting/application_setting.dart`
- `lib/features/superadmin/presentation/components/admin/payments_tab/admin_payments_tab.dart`
- `lib/features/superadmin/presentation/components/admin/policy_edit/policy_edit.dart`
- `lib/features/superadmin/presentation/components/admin/activity_tab/admin_activity_tab.dart`
- `lib/features/superadmin/presentation/components/admin/payments_tab/add_admin_payment_record_screen.dart`
- `lib/features/superadmin/presentation/components/admin/ssl/ssl.dart`
- `lib/features/superadmin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart`
- `lib/features/superadmin/presentation/components/admin/documents_tab/documents_tab.dart`
- `lib/features/superadmin/presentation/components/admin/documents_tab/widget/file_card.dart`
- `lib/features/superadmin/presentation/components/admin/profile_tab/widget/delete_account_box.dart`

### 7.3 Files still referencing `LegacyErrorPresenter` — 32

- `lib/features/documents/presentation/controllers/document_form_controller.dart`
- `lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart`
- `lib/features/superadmin/presentation/components/admin/vehicles_tab/vehicles_tab.dart`
- `lib/features/superadmin/presentation/components/transactions/record_manual_payment_screen.dart`
- `lib/features/superadmin/presentation/components/vehicle/widget/add_new_vehicle.dart`
- `lib/features/superadmin/presentation/components/admin/payments_tab/admin_payments_tab.dart`
- `lib/features/superadmin/presentation/components/transactions/payments_screen.dart`
- `lib/features/superadmin/presentation/components/admin/ssl/ssl.dart`
- `lib/features/superadmin/presentation/components/admin/payments_tab/add_admin_payment_record_screen.dart`
- `lib/features/superadmin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart`
- `lib/features/admin/presentation/components/admin/application_setting/application_setting.dart`
- `lib/features/admin/presentation/screens/home/home_screen.dart`
- `lib/features/admin/presentation/screens/dashboard/dashboard_screen.dart`
- `lib/features/superadmin/presentation/components/profile/profile_screen.dart`
- `lib/features/superadmin/presentation/components/admin/documents_tab/documents_tab.dart`
- `lib/features/admin/presentation/screens/sims/add_sim_screen.dart`
- `lib/features/admin/presentation/screens/sims/sim_screen.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/admin_credit_history_tab.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/credit_history_tab.dart`
- `lib/features/superadmin/presentation/components/admin/calender/calender_screen.dart`
- `lib/features/superadmin/presentation/components/admin/activity_tab/admin_activity_tab.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/add_deduct_credit_screen.dart`
- `lib/features/admin/presentation/screens/plans/edit_plan_screen.dart`
- `lib/features/superadmin/presentation/components/admin/profile_tab/widget/delete_account_box.dart`
- `lib/features/superadmin/presentation/components/admin/application_setting/application_setting.dart`
- `lib/features/superadmin/presentation/components/admin/policy_edit/policy_edit.dart`
- `lib/features/user/presentation/screens/admin/screens/add_share_track.dart`
- `lib/features/user/presentation/screens/profile/widget/update_password_screen.dart`
- `lib/features/user/presentation/screens/profile/widget/edit_admin_profile_screen.dart`
- `lib/features/user/presentation/screens/drivers/edit_driver_profile_screen.dart`
- `lib/features/user/presentation/screens/profile/widget/profile_verification_box.dart`
- `lib/features/user/presentation/screens/notification/vehicle_toggle_screen.dart`

### 7.4 Files still referencing `AppCancellationHandle` — 39

- `lib/features/map/application/open_vts_map_repository.dart`
- `lib/features/admin_tools/application/server_status/server_status_repository.dart`
- `lib/features/user/di/user_profile_access_providers.dart`
- `lib/features/user/application/vehicle_details/vehicle_details_repository.dart`
- `lib/features/documents/presentation/controllers/document_form_controller.dart`
- `lib/features/settings/presentation/controllers/settings_profile_loader.dart`
- `lib/features/settings/presentation/controllers/settings_content_controller.dart`
- `lib/features/user/presentation/screens/notification/vehicle_toggle_screen.dart`
- `lib/features/user/presentation/screens/drivers/edit_driver_profile_screen.dart`
- `lib/features/user/presentation/screens/admin/screens/add_share_track.dart`
- `lib/features/superadmin/presentation/components/vehicle/widget/add_new_vehicle.dart`
- `lib/features/superadmin/presentation/components/branding/branding_settings_screen.dart`
- `lib/features/superadmin/presentation/components/transactions/record_manual_payment_screen.dart`
- `lib/features/superadmin/presentation/components/transactions/payments_screen.dart`
- `lib/features/superadmin/presentation/components/admin/vehicles_tab/vehicles_tab.dart`
- `lib/features/superadmin/presentation/components/profile/profile_screen.dart`
- `lib/features/user/presentation/screens/profile/widget/update_password_screen.dart`
- `lib/features/admin/presentation/components/admin/application_setting/application_setting.dart`
- `lib/features/superadmin/presentation/components/admin/ssl/ssl.dart`
- `lib/features/user/presentation/screens/profile/widget/profile_verification_box.dart`
- `lib/features/superadmin/presentation/components/admin/payments_tab/admin_payments_tab.dart`
- `lib/features/user/presentation/screens/profile/widget/edit_admin_profile_screen.dart`
- `lib/features/superadmin/presentation/components/admin/payments_tab/add_admin_payment_record_screen.dart`
- `lib/features/admin/presentation/screens/dashboard/dashboard_screen.dart`
- `lib/features/superadmin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart`
- `lib/features/user/presentation/screens/profile/profile_screen.dart`
- `lib/features/superadmin/presentation/components/admin/calender/calender_screen.dart`
- `lib/features/admin/presentation/screens/home/home_screen.dart`
- `lib/features/admin/presentation/screens/sims/sim_screen.dart`
- `lib/features/admin/presentation/screens/sims/add_sim_screen.dart`
- `lib/features/superadmin/presentation/components/admin/policy_edit/policy_edit.dart`
- `lib/features/superadmin/presentation/components/admin/application_setting/application_setting.dart`
- `lib/features/superadmin/presentation/components/admin/activity_tab/admin_activity_tab.dart`
- `lib/features/admin/presentation/screens/plans/edit_plan_screen.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/credit_history_tab.dart`
- `lib/features/superadmin/presentation/components/admin/profile_tab/widget/delete_account_box.dart`
- `lib/features/superadmin/presentation/components/admin/documents_tab/documents_tab.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/add_deduct_credit_screen.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/admin_credit_history_tab.dart`

### 7.5 Files still referencing `LegacyApiTransport` under `lib/features` — 36

- `lib/features/settings/data/repositories/white_label_repository.dart`
- `lib/features/admin_tools/application/server_status/server_status_repository.dart`
- `lib/features/settings/data/repositories/app_preferences_repository.dart`
- `lib/features/admin_tools/data/repositories/api_config_repository.dart`
- `lib/features/superadmin/data/sources/superadmin_typed_api_transport.dart`
- `lib/features/auth/data/repositories/push_token_repository.dart`
- `lib/features/auth/data/repositories/auth_repository.dart`
- `lib/features/user/data/sources/user_typed_api_transport.dart`
- `lib/features/admin/data/sources/admin_typed_api_transport.dart`
- `lib/features/admin/data/repositories/role_notifications_repository.dart`
- `lib/features/admin/data/repositories/admin_vehicle_repository.dart`
- `lib/features/admin/data/repositories/admin_vehicles_repository.dart`
- `lib/features/admin/data/repositories/admin_teams_repository.dart`
- `lib/features/user/data/repositories/user_transactions_repository.dart`
- `lib/features/admin/data/repositories/admin_support_repository.dart`
- `lib/features/user/data/repositories/user_support_repository.dart`
- `lib/features/admin/data/repositories/admin_simcards_repository.dart`
- `lib/features/user/data/repositories/user_subusers_repository.dart`
- `lib/features/admin/data/repositories/admin_repository.dart`
- `lib/features/user/data/repositories/user_share_track_links_repository.dart`
- `lib/features/admin/data/repositories/admin_pricing_plans_repository.dart`
- `lib/features/user/data/repositories/user_routes_repository.dart`
- `lib/features/admin/data/repositories/admin_drivers_repository.dart`
- `lib/features/admin/data/repositories/admin_payments_repository.dart`
- `lib/features/admin/data/repositories/admin_app_preferences_repository.dart`
- `lib/features/user/data/repositories/user_repository.dart`
- `lib/features/admin/data/repositories/admin_devices_repository.dart`
- `lib/features/admin/data/repositories/admin_dashboard_repository.dart`
- `lib/features/admin/data/repositories/admin_notification_repository.dart`
- `lib/features/user/data/repositories/user_localization_repository.dart`
- `lib/features/admin/data/repositories/admin_localization_repository.dart`
- `lib/features/user/data/repositories/user_policy_repository.dart`
- `lib/features/user/data/repositories/user_landmarks_repository.dart`
- `lib/features/user/data/repositories/user_notification_preferences_repository.dart`
- `lib/features/user/data/repositories/user_home_repository.dart`
- `lib/features/user/data/repositories/user_map_repository.dart`

### 7.6 Presentation/shared files still directly matching repository-provider reads — 17

- `lib/features/map/presentation/controllers/map_vehicle_details_controller.dart`
- `lib/features/shell/presentation/controllers/role_notifications_controller.dart`
- `lib/features/superadmin/presentation/components/vehicle/VehicleDetailsScreen.dart`
- `lib/features/admin/presentation/controllers/admin_device_list_controller.dart`
- `lib/features/superadmin/presentation/components/transactions/payments_screen.dart`
- `lib/features/user/presentation/screens/drivers/add_driver_screen.dart`
- `lib/features/user/presentation/screens/route/add_landmark_screen.dart`
- `lib/features/user/presentation/screens/notification/vehicle_toggle_screen.dart`
- `lib/features/user/presentation/screens/profile/widget/edit_admin_profile_screen.dart`
- `lib/features/superadmin/presentation/components/admin/role/role.dart`
- `lib/features/superadmin/presentation/components/admin/activity_tab/admin_activity_tab.dart`
- `lib/features/superadmin/presentation/components/admin/documents_tab/widget/file_card.dart`
- `lib/features/user/presentation/screens/sub_users/add_sub_user_screen.dart`
- `lib/features/admin/presentation/screens/drivers/driver_details_screen.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/add_deduct_credit_screen.dart`
- `lib/features/admin/presentation/screens/home/home_screen.dart`
- `lib/features/superadmin/presentation/components/admin/payments_tab/admin_payments_tab.dart`

### 7.7 Presentation/shared files still using `Map<String, dynamic>` — 65

- `lib/shared/models/admin_profile.dart`
- `lib/features/documents/presentation/widgets/file_card.dart`
- `lib/features/admin_tools/presentation/api_config/api_config_models.dart`
- `lib/features/user/presentation/controllers/user_sub_user_detail_controller.dart`
- `lib/features/map/presentation/open_vts_map/widgets/vehicle_details_bottom_panel.dart`
- `lib/features/documents/presentation/screens/document_form_screen.dart`
- `lib/features/user/presentation/controllers/user_sub_user_form_controller.dart`
- `lib/features/map/presentation/open_vts_map/open_vts_map_vehicle_helpers.dart`
- `lib/features/documents/presentation/controllers/document_form_controller.dart`
- `lib/features/superadmin/presentation/screens/notifications/superadmin_notifications_screen.dart`
- `lib/features/vehicles/presentation/widgets/vehicle_documents_tab.dart`
- `lib/features/settings/presentation/controllers/settings_profile_loader.dart`
- `lib/features/superadmin/presentation/screens/more/more_screen.dart`
- `lib/features/settings/presentation/widgets/settings_profile_company.dart`
- `lib/features/support/presentation/ticket_details/ticket_details_controller.dart`
- `lib/features/superadmin/presentation/screens/home/home_screen.dart`
- `lib/features/user/presentation/widgets/home/card/vehicle_status_box.dart`
- `lib/features/superadmin/presentation/components/card/vehicle_status_box.dart`
- `lib/features/superadmin/presentation/components/vehicle/widget/vehicle_config_tab.dart`
- `lib/features/superadmin/presentation/components/card/recent_activity_box.dart`
- `lib/features/user/presentation/widgets/home/card/all_activities_screen.dart`
- `lib/features/user/presentation/screens/admin/admin.dart`
- `lib/features/superadmin/presentation/components/card/all_activities_screen.dart`
- `lib/features/user/presentation/screens/admin/screens/share_track_link.dart`
- `lib/features/user/presentation/screens/vehicles/vehicle_details/widgets/documents_tab.dart`
- `lib/features/superadmin/presentation/components/admin/vehicles_tab/vehicles_tab.dart`
- `lib/features/admin/presentation/controllers/admin_account_command_controller.dart`
- `lib/features/user/presentation/screens/vehicles/vehicle_details/controller.dart`
- `lib/features/user/presentation/screens/route/add_landmark_screen.dart`
- `lib/features/user/presentation/screens/sub_users/sub_user_details_screen.dart`
- `lib/features/superadmin/presentation/components/admin/calender/calender_screen.dart`
- `lib/features/user/presentation/screens/profile/widget/profile_company_box.dart`
- `lib/features/superadmin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart`
- `lib/features/superadmin/presentation/components/admin/activity_tab/admin_activity_tab.dart`
- `lib/features/superadmin/presentation/components/admin/credit_history/admin_credit_history_tab.dart`
- `lib/features/superadmin/presentation/components/admin/documents_tab/documents_tab.dart`
- `lib/features/superadmin/presentation/components/admin/documents_tab/widget/file_card.dart`
- `lib/features/superadmin/presentation/components/admin/profile_tab/profile_tab_helpers.dart`
- `lib/features/superadmin/presentation/components/admin/profile_tab/widget/company_box.dart`
- `lib/features/superadmin/presentation/components/admin/role_tab.dart`
- `lib/features/superadmin/presentation/components/admin/payment_gateway_setting/payment_gateway_details.dart`
- `lib/features/admin/presentation/router/admin_routes.dart`
- `lib/features/admin/presentation/screens/logs/log_details_screen.dart`
- `lib/features/admin/presentation/screens/notifications/admin_notifications_screen.dart`
- `lib/features/admin/presentation/screens/analytics/analytics_screen.dart`
- `lib/features/admin/presentation/screens/logs/logs_screen.dart`
- `lib/features/admin/presentation/components/card/vehicle_status_box.dart`
- `lib/features/admin/presentation/components/card/all_activities_screen.dart`
- `lib/features/admin/presentation/screens/more/more_screen.dart`
- `lib/features/admin/presentation/screens/account/widget/edit_company_screen.dart`
- `lib/features/admin/presentation/screens/account/widget/admin_user_documents_tab.dart`
- `lib/features/admin/presentation/components/calender/calender_screen.dart`
- `lib/features/admin/presentation/screens/account/widget/admin_user_activity_tab.dart`
- `lib/features/admin/presentation/screens/account/widget/admin_user_profile_tab.dart`
- `lib/features/admin/presentation/screens/account/user.dart`
- `lib/features/admin/presentation/screens/account/widget/documents/file_card.dart`
- `lib/features/admin/presentation/components/admin/edit_admin_profile_screen.dart`
- `lib/features/admin/presentation/screens/transactions/transaction_details_screen.dart`
- `lib/features/admin/presentation/screens/payments/collect_payment_screen.dart`
- `lib/features/admin/presentation/screens/plans/edit_plan_screen.dart`
- `lib/features/admin/presentation/screens/renewals/suspend_access_screen.dart`
- `lib/features/admin/presentation/screens/renewals/extend_license_screen.dart`
- `lib/features/admin/presentation/screens/renewals/renewal_screen.dart`
- `lib/features/admin/presentation/screens/renewals/send_reminder_screen.dart`
- `lib/features/admin/presentation/screens/renewals/renew_device_screen.dart`

## 8. Production-candidate acceptance review

| Acceptance criterion | Result | Evidence |
|---|---|---|
| Architecture guard passes without hiding active serious presentation-boundary violations | Partial | Guard passes, but 118 warnings and 43 allowlist entries remain. |
| Migration allowlist is zero or only documented low-risk legacy files | Fail | 43 allowlist entries remain; several are high-risk presentation files. |
| Direct `setState` remains zero in features/shared | Pass | `rg "setState\(" lib/features lib/shared` returned no matches. |
| No non-generated API source returns `Future<Object?>` | Pass | `rg "Future<Object\?>" lib/features --glob '!*.g.dart'` returned no matches. |
| No presentation file imports legacy facade providers | Fail | 33 files still import the legacy facade. |
| No presentation screen directly calls repository implementation providers for API/business state | Fail | 17 files still match direct repository-provider reads. |
| No target/gateway file uses `LegacyErrorPresenter` or `AppCancellationHandle` | Partial | Prior gateway target files were cleaned, but non-target legacy files still use them. |
| `flutter analyze --fatal-infos` passes | Not verified | Flutter is not installed in this environment. |
| `flutter test --coverage` passes | Not verified | Flutter is not installed in this environment. |
| Production logging/config/security tests exist | Pass structurally | Security/redaction/config/deep-link tests exist, but could not be executed here. |
| Map telemetry provider and marker layer follow buffer/throttle/projection model | Pass structurally | Guard metrics show map legacy imports/raw socket refs at 0. |

## 9. Remaining blockers

1. **Presentation legacy facade imports** must be eliminated from the remaining 33 files.
2. **Legacy error and cancellation patterns** must be replaced with controller-owned request lifecycle and typed `UiEffect` in the remaining files.
3. **Legacy transport repositories** must continue migration from `LegacyApiTransport` to typed Retrofit services and domain repositories.
4. **Raw `Map<String, dynamic>` usage in presentation/shared** must be replaced with typed view models/entities, especially in documents, settings, admin renewals, admin account widgets, and superadmin screens.
5. **Flutter validation must run locally**: `dart format`, `build_runner`, `flutter analyze --fatal-infos`, and `flutter test --coverage` are required before a production-candidate claim.
6. **Pending generated code**: `app_database.g.dart` and other generated files must be created by `build_runner`, not manually.

## 10. Recommended next 5 production tasks

1. **Zero the legacy facade imports**: migrate the 33 remaining files to feature-owned DI/controllers and remove matching allowlist entries only when the guard stays green.
2. **Finish UI effects/cancellation cleanup**: replace all remaining `LegacyErrorPresenter` and `AppCancellationHandle` uses with `UiEffect`, `ErrorPresenter`, Riverpod `autoDispose`, and controller request-sequence guards.
3. **Continue LegacyApiTransport removal**: migrate the remaining repository clusters to typed Retrofit services; then convert the guard from metric-only to hard failure for all repository transport usage.
4. **Typed presentation model pass**: replace `Map<String, dynamic>` in presentation/shared with view-state classes and mappers, prioritizing files that still also have legacy facade/error/cancellation debt.
5. **Run real Flutter CI locally**: run `dart format .`, `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze --fatal-infos`, and `flutter test --coverage`; fix every analyzer/test failure before calling the app production-candidate.

## 11. Final decision

**Current status: Enterprise beta-ready.**

The codebase is materially stronger than prompt23 and has real gateway protections. However, it must not be marketed internally as enterprise production-candidate until the remaining allowlist/legacy presentation boundary files are closed and the full Flutter analyzer/test suite passes in a real Flutter environment.
