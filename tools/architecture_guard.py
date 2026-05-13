#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'lib'
failures: list[str] = []
warnings: list[str] = []
metrics: dict[str, int] = {}
enterprise_gateway_metrics: dict[str, int] = {}
ALLOWLIST = ROOT / 'tools/migration_allowlist.txt'
allowlisted: set[str] = set()
allowlist_metadata: dict[str, dict[str, str]] = {}
allowlisted_warning_categories: dict[str, set[str]] = {}


def _commit_allowlist_block(block: dict[str, str], line_number: int) -> None:
    if not block:
        return
    path_part = block.get('path', '').strip()
    if not path_part.startswith('lib/') and not path_part.startswith('test/') and not path_part.startswith('tools/'):
        failures.append(f'Invalid migration allowlist path near line {line_number}: {path_part or block}')
        return
    required = ['reason', 'owner_feature', 'target_fix_prompt', 'risk', 'remove_when']
    missing = [key for key in required if not block.get(key)]
    if missing:
        failures.append(f'Migration allowlist entry missing metadata {missing} near line {line_number}: {path_part}')
        return
    allowlisted.add(path_part)
    allowlist_metadata[path_part] = dict(block)


if ALLOWLIST.exists():
    pending: dict[str, str] = {}
    pending_line = 0
    for line_number, raw in enumerate(ALLOWLIST.read_text(encoding='utf-8').splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith('#'):
            if pending:
                _commit_allowlist_block(pending, pending_line)
                pending = {}
                pending_line = 0
            continue

        # Backward-compatible parser for the old one-line pipe format.
        if '|' in line and not line.startswith('path:'):
            if pending:
                _commit_allowlist_block(pending, pending_line)
                pending = {}
                pending_line = 0
            parts = [part.strip() for part in line.split('|')]
            path_part = parts[0]
            metadata: dict[str, str] = {'path': path_part}
            for part in parts[1:]:
                if '=' in part:
                    key, value = part.split('=', 1)
                    metadata[key.strip()] = value.strip()
            if 'owner' in metadata and 'owner_feature' not in metadata:
                metadata['owner_feature'] = metadata['owner']
            if 'target_phase' in metadata and 'target_fix_prompt' not in metadata:
                metadata['target_fix_prompt'] = metadata['target_phase']
            metadata.setdefault('risk', 'medium')
            metadata.setdefault('remove_when', 'violation no longer exists')
            _commit_allowlist_block(metadata, line_number)
            continue

        if ':' not in line:
            failures.append(f'Invalid migration allowlist metadata line {line_number}: {line}')
            continue
        key, value = line.split(':', 1)
        key = key.strip()
        value = value.strip()
        if key == 'path':
            if pending:
                _commit_allowlist_block(pending, pending_line)
            pending = {'path': value}
            pending_line = line_number
        else:
            if not pending:
                failures.append(f'Migration allowlist metadata before path at line {line_number}: {line}')
                continue
            pending[key] = value
    if pending:
        _commit_allowlist_block(pending, pending_line)


def rel_path(path: Path) -> str:
    return str(path.relative_to(ROOT)).replace('\\', '/')


def is_allowlisted(path_or_rel) -> bool:
    rel = path_or_rel if isinstance(path_or_rel, str) else rel_path(path_or_rel)
    return rel in allowlisted


def add_allowlisted_warning(path_or_rel, category: str) -> None:
    rel = path_or_rel if isinstance(path_or_rel, str) else rel_path(path_or_rel)
    allowlisted_warning_categories.setdefault(rel, set()).add(category)


def allowlist_category_metric(path_or_rel, category: str) -> None:
    safe = re.sub(r'[^a-zA-Z0-9_]+', '_', category.lower()).strip('_')
    if safe:
        bump(f'allowlist_category_{safe}')


MIGRATED_FILES = {
    'lib/features/admin/presentation/controllers/add_user_controller.dart',
    'lib/features/admin/presentation/controllers/add_vehicle_controller.dart',
    'lib/features/admin/presentation/controllers/add_driver_controller.dart',
    'lib/features/admin/presentation/controllers/add_device_controller.dart',
    'lib/features/admin/presentation/controllers/add_team_controller.dart',
    'lib/features/user/presentation/controllers/add_vehicle_controller.dart',
    'lib/features/admin/presentation/screens/account/add_user_screen.dart',
    'lib/features/admin/presentation/screens/vehicles/add_vehicle_screen.dart',
    'lib/features/admin/presentation/screens/drivers/add_driver_screen.dart',
    'lib/features/admin/presentation/screens/devices/add_device_screen.dart',
    'lib/features/admin/presentation/screens/teams/add_team_screen.dart',
    'lib/features/user/presentation/screens/vehicles/add_vehicle_screen.dart',
    'lib/features/support/presentation/new_ticket/new_ticket_screen.dart',

    'lib/features/support/presentation/new_ticket/new_ticket_controller.dart',
    'lib/features/support/presentation/new_ticket/new_ticket_state.dart',
    'lib/features/support/presentation/new_ticket/new_ticket_validators.dart',
    'lib/features/support/presentation/new_ticket/widgets/ticket_admin_selector.dart',
    'lib/features/support/presentation/new_ticket/widgets/ticket_user_selector.dart',
    'lib/features/support/di/support_new_ticket_controller_provider.dart',
    'lib/features/support/domain/entities/support_assignee_option.dart',
    'lib/features/support/domain/repositories/support_new_ticket_repository.dart',
    'lib/features/support/domain/use_cases/create_new_support_ticket_use_case.dart',
    'lib/features/support/domain/use_cases/load_support_assignees_use_case.dart',
    'lib/features/support/data/repositories/support_new_ticket_repository_impl.dart',
    'lib/features/support/data/sources/support_new_ticket_api_service.dart',
    'lib/features/admin/data/repositories/admin_form_repository_impl.dart',
    'lib/features/admin/data/repositories/admin_driver_form_repository_impl.dart',
    'lib/features/admin/data/repositories/admin_device_form_repository_impl.dart',
    'lib/features/admin/data/repositories/admin_team_form_repository_impl.dart',
    'lib/features/user/data/repositories/user_vehicle_form_repository_impl.dart',
    'lib/features/admin/di/admin_form_providers.dart',
    'lib/features/admin/di/admin_workflow_providers.dart',
    'lib/features/user/di/user_vehicle_form_providers.dart',
    'lib/features/reference_data/data/repositories/reference_data_repository_impl.dart',
    'lib/features/reference_data/di/reference_data_providers.dart',
    'lib/features/map/di/map_socket_providers.dart',
    'lib/features/map/data/mappers/map_vehicle_snapshot_mapper.dart',
    'lib/features/map/domain/entities/map_vehicle_snapshot.dart',
    'lib/features/map/presentation/providers/map_telemetry_provider.dart',
    'lib/features/map/presentation/open_vts_map/open_vts_map_marker_projection.dart',
    'lib/features/map/presentation/open_vts_map/open_vts_map_screen.dart',
    'lib/features/map/presentation/open_vts_map/widgets/live_vehicle_marker_layer.dart',
    'lib/features/map/presentation/open_vts_map/widgets/vehicle_details_bottom_sheet.dart',
    'lib/features/map/presentation/controllers/map_vehicle_details_controller.dart',
    'lib/features/admin/presentation/screens/map/map_screen.dart',
    'lib/features/superadmin/presentation/screens/map/map_screen.dart',
    'lib/features/user/presentation/screens/map/map_screen.dart',
    'lib/features/vehicles/domain/entities/vehicle_details.dart',
    'lib/features/map/domain/entities/map_vehicle_point.dart',
    'lib/features/map/domain/entities/telemetry_data.dart',
    'lib/features/user/domain/entities/user_notification_preferences.dart',
    'lib/features/user/domain/entities/user_policy.dart',
    'lib/features/user/domain/entities/user_usage_last_7_days.dart',
    'lib/features/user/domain/entities/user_dashboard_usage.dart',
    'lib/features/superadmin/domain/entities/superadmin_profile.dart',
    'lib/features/superadmin/domain/entities/superadmin_total_counts.dart',
    'lib/features/admin/domain/entities/admin_dashboard_summary.dart',
    'lib/features/admin_tools/domain/entities/server_overall_status.dart',
    'lib/features/vehicles/data/mappers/vehicle_details_mapper.dart',
    'lib/features/map/data/mappers/map_vehicle_point_mapper.dart',
    'lib/features/map/data/mappers/telemetry_data_mapper.dart',
    'lib/features/user/data/mappers/user_policy_mapper.dart',
    'lib/features/user/data/mappers/user_usage_mapper.dart',
    'lib/features/superadmin/data/mappers/superadmin_profile_mapper.dart',
    'lib/features/superadmin/data/mappers/superadmin_total_counts_mapper.dart',
    'lib/features/admin/data/mappers/admin_dashboard_summary_mapper.dart',
    'lib/features/admin_tools/data/mappers/server_overall_status_mapper.dart',
}


MIGRATED_LEGACY_TRANSPORT_REPOSITORIES = {
    'lib/features/admin/data/repositories/admin_users_repository.dart',
    'lib/features/admin/data/repositories/admin_profile_repository.dart',
    'lib/features/admin/data/repositories/admin_calendar_repository.dart',
    'lib/features/admin/data/repositories/admin_logs_repository.dart',
    'lib/features/admin/data/repositories/admin_notifications_repository.dart',
    'lib/features/admin/data/repositories/admin_transactions_repository.dart',
    'lib/features/user/data/repositories/user_profile_repository.dart',
    'lib/features/user/data/repositories/user_vehicles_repository.dart',
    'lib/features/user/data/repositories/user_drivers_repository.dart',
    'lib/features/superadmin/data/repositories/superadmin_repository.dart',
}

ERROR_EFFECT_MIGRATED_FILES = {
    'lib/features/settings/presentation/controllers/settings_action_handler.dart',
    'lib/features/localization/presentation/controllers/localization_controller.dart',
    'lib/features/support/presentation/ticket_details/ticket_details_controller.dart',
    'lib/features/support/presentation/ticket_details/ticket_details_state.dart',
    'lib/features/user/presentation/screens/vehicles/vehicle_details/controller.dart',
    'lib/features/user/presentation/screens/admin/screens/share_track_link.dart',
    'lib/features/admin/presentation/screens/account/user.dart',
    'lib/features/admin/presentation/screens/account/user_details_screen.dart',
    'lib/features/superadmin/presentation/screens/notifications/superadmin_notifications_screen.dart',
    'lib/features/admin/presentation/screens/notifications/admin_notifications_screen.dart',
    'lib/features/superadmin/presentation/screens/dashboard/dashboard_screen.dart',
}

MIGRATED_BANNED_IMPORTS = [
    'repository_bridge_providers.dart',
    'legacy_repository_adapter_providers.dart',
    'core/providers/core_providers.dart',
    'core/api/common_repository.dart',
]
MIGRATED_BANNED_TOKENS = [
    'ApiClient',
    'CommonRepository',
    'adminUsersRepositoryAdapterProvider',
    'adminVehiclesRepositoryAdapterProvider',
    'legacyRepositoryAdapter',
    'AppCancellationHandle',
    'LegacyErrorPresenter',
]

def bump(name: str, amount: int = 1) -> None:
    metrics[name] = metrics.get(name, 0) + amount


def set_gateway_metric(name: str, value: int) -> None:
    enterprise_gateway_metrics[name] = value


def count_token(paths: list[Path], token: str) -> int:
    return sum(read(path).count(token) for path in paths)


def count_files_with_token(paths: list[Path], token: str) -> int:
    return sum(1 for path in paths if token in read(path))


def count_regex(paths: list[Path], pattern: str) -> int:
    compiled = re.compile(pattern, re.MULTILINE)
    return sum(len(compiled.findall(read(path))) for path in paths)


UPDATE_LOCAL_UI_BUSINESS_KEYWORDS = (
    'loading', 'saving', 'submitting', 'deleting', 'refresh', 'error',
    'result', 'response', 'data', 'items', 'users', 'vehicles', 'drivers',
    'documents', 'tickets', 'notifications', 'payments', 'transactions',
    'logs', 'profile', 'details', 'statussubmitting', 'upload', 'uploading',
    'token', 'session', 'role', 'permission', 'socket', 'telemetry',
)

UPDATE_LOCAL_UI_CALL_RE = re.compile(r'\bupdateLocalUiState\s*\((?P<body>.*?)\);', re.DOTALL)
UPDATE_LOCAL_UI_ASSIGN_RE = re.compile(r'\b(?P<name>_?[A-Za-z]\w*)\s*(?:=|\+=|-=|\.add\(|\.remove\(|\.clear\(|\[)')


def count_probable_business_update_local_ui_calls(paths: list[Path]) -> int:
    count = 0
    for path in paths:
        text = read(path)
        for match in UPDATE_LOCAL_UI_CALL_RE.finditer(text):
            assigned = ' '.join(
                name.lower()
                for name in UPDATE_LOCAL_UI_ASSIGN_RE.findall(match.group('body'))
                if name not in {'updateLocalUiState', 'this', 'context', 'ref'}
            )
            if any(keyword in assigned for keyword in UPDATE_LOCAL_UI_BUSINESS_KEYWORDS):
                count += 1
    return count


def read(path: Path) -> str:
    return path.read_text(encoding='utf-8', errors='ignore')

# Generated part files must exist.
for path in LIB.rglob('*.dart'):
    text = read(path)
    for match in re.finditer(r"part ['\"]([^'\"]+)['\"];", text):
        target = path.parent / match.group(1)
        if not target.exists():
            rel_target = str(target.relative_to(ROOT)).replace('\\', '/')
            if rel_target == 'lib/core/database/app_database.g.dart':
                bump('pending_drift_generated_parts')
            else:
                failures.append(f'Missing generated part: {target.relative_to(ROOT)}')

# Presentation boundary checks.
for path in LIB.glob('features/**/presentation/**/*.dart'):
    text = read(path)
    rel = path.relative_to(ROOT)
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith('import'):
            continue
        if 'features/' in stripped and '/data/' in stripped:
            failures.append(f'Presentation imports data: {rel}: {stripped}')
            bump('presentation_to_data_imports')
        if 'core/api/' in stripped:
            failures.append(f'Presentation imports core/api: {rel}: {stripped}')
            bump('presentation_to_core_api_imports')
        if 'core/utils/request_control.dart' in stripped:
            failures.append(f'Presentation imports request_control facade: {rel}: {stripped}')
        if 'core/error/api_exception.dart' in stripped:
            failures.append(f'Presentation imports API exception facade: {rel}: {stripped}')
        if 'core/utils/legacy_transport_result.dart' in stripped:
            failures.append(f'Presentation imports legacy transport result: {rel}: {stripped}')
        if 'core/services/api_gateway.dart' in stripped:
            failures.append(f'Presentation imports API gateway facade: {rel}: {stripped}')
        if 'core/services/common_repository_facade.dart' in stripped:
            failures.append(f'Presentation imports common repository facade: {rel}: {stripped}')
        if 'core/application/legacy_backend_client.dart' in stripped:
            failures.append(f'Presentation imports legacy backend client: {rel}: {stripped}')
        if 'core/providers/core_providers.dart' in stripped:
            failures.append(f'Presentation imports raw core providers: {rel}: {stripped}')
        if 'core/providers/repository_providers.dart' in stripped:
            bump('repository_provider_bridge_imports')
            if is_allowlisted(path):
                add_allowlisted_warning(path, 'core_repository_provider_import')
            else:
                failures.append(f'Presentation imports core repository providers: {rel}: {stripped}')
        if 'shared/presentation/providers/repository_bridge_providers.dart' in stripped:
            bump('repository_provider_bridge_imports')
            if is_allowlisted(path):
                add_allowlisted_warning(path, 'shared_repository_bridge_import')
            else:
                failures.append(f'Presentation imports shared repository bridge: {rel}: {stripped}')
        if 'legacy_repository_adapter_providers.dart' in stripped:
            if is_allowlisted(path):
                add_allowlisted_warning(path, 'legacy_repository_adapter_import')
            else:
                failures.append(f'Presentation imports legacy repository adapter providers: {rel}: {stripped}')
        if 'legacy_repository_facade_providers.dart' in stripped:
            if is_allowlisted(path):
                add_allowlisted_warning(path, 'legacy_repository_facade_import')
            else:
                failures.append(f'Presentation imports legacy repository facade providers: {rel}: {stripped}')
        if re.search(r'features/.+/application/.+_repositories\.dart', stripped):
            failures.append(f'Presentation imports application repository barrel: {rel}: {stripped}')
        if 'legacy_repositories.dart' in stripped or '_legacy_repositories.dart' in stripped:
            failures.append(f'Presentation imports legacy repository barrel: {rel}: {stripped}')
        if 'package:dio' in stripped:
            failures.append(f'Presentation imports Dio directly: {rel}: {stripped}')
    if re.search(r'\bApiClient\b', text):
        failures.append(f'ApiClient appears in presentation: {rel}')
    if re.search(r'\bApiGateway\b', text):
        failures.append(f'ApiGateway appears in presentation: {rel}')
    if re.search(r'\bLegacyBackendClient\b', text):
        failures.append(f'LegacyBackendClient appears in presentation: {rel}')
    if re.search(r'\bbackendClientProvider\b', text):
        failures.append(f'backendClientProvider appears in presentation: {rel}')
    if re.search(r'\bapiGatewayProvider\b', text):
        failures.append(f'apiGatewayProvider appears in presentation: {rel}')
    if re.search(r'\bCommonRepository\b', text):
        failures.append(f'CommonRepository appears in presentation: {rel}')
    if 'AppContainer.instance' in text:
        failures.append(f'AppContainer.instance appears in presentation: {rel}')
    if re.search(r'\bCancelToken\b', text):
        failures.append(f'CancelToken appears in presentation: {rel}')
    if re.search(r'\bDioException\b', text):
        failures.append(f'DioException appears in presentation: {rel}')
    if path.name == 'repository.dart' or path.name.endswith('_repository.dart'):
        failures.append(f'Repository file inside presentation: {rel}')
    if re.search(r'\b(debugPrint|print)\s*\(', text):
        warnings.append(f'Direct print/debugPrint in presentation; use AppLogger: {rel}')
        bump('direct_print_debugprint_calls')
    if 'LegacyErrorPresenter' in text:
        if rel_path(path) in ERROR_EFFECT_MIGRATED_FILES:
            failures.append(f'LegacyErrorPresenter reintroduced in error/effect migrated file: {rel}')
        elif is_allowlisted(path):
            add_allowlisted_warning(path, 'LegacyErrorPresenter')
        else:
            failures.append(f'LegacyErrorPresenter used in presentation: {rel}')
    if 'AppCancellationHandle' in text:
        if rel_path(path) in ERROR_EFFECT_MIGRATED_FILES:
            failures.append(f'AppCancellationHandle reintroduced in error/effect migrated file: {rel}')
        elif is_allowlisted(path):
            add_allowlisted_warning(path, 'AppCancellationHandle')
        else:
            failures.append(f'AppCancellationHandle used in presentation: {rel}')
    if re.search(r'(dynamic\s+repository|final\s+dynamic\s+_?repository|dynamic\s+_?repository)', text):
        if is_allowlisted(path):
            add_allowlisted_warning(path, 'dynamic_repository')
        else:
            failures.append(f'Dynamic repository pattern in presentation: {rel}')
    if '/screens/' in rel_path(path) and re.search(r'(new\s+)?\w+(Repository|ApiService|DataSource)\s*\(', text):
        if is_allowlisted(path):
            add_allowlisted_warning(path, 'screen_direct_instantiation')
        else:
            failures.append(f'Screen directly creates repository/data source/API service: {rel}')


# Application repository barrels must not expose data implementations.
for path in LIB.glob('features/*/application/*repositories.dart'):
    text = read(path)
    rel = path.relative_to(ROOT)
    if '/data/repositories/' in text:
        failures.append(f'Application repository barrel exports data implementation: {rel}')

# Domain purity checks.
for path in LIB.glob('features/**/domain/**/*.dart'):
    text = read(path)
    rel = path.relative_to(ROOT)
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith('import'):
            continue
        forbidden_tokens = [
            'package:flutter',
            'package:dio',
            'package:hive',
            'package:drift',
            'flutter_secure_storage',
            '/data/',
            '/presentation/',
            'core/api/',
        ]
        for token in forbidden_tokens:
            if token in stripped:
                failures.append(f'Domain forbidden import: {rel}: {stripped}')
                break

    if 'Map<String, dynamic>' in text:
        bump('domain_raw_dynamic_maps')
        if is_allowlisted(path):
            add_allowlisted_warning(path, 'domain_raw_map')
        else:
            failures.append(f'Domain exposes Map<String, dynamic>: {rel}')


# Repositories that have crossed the legacy-transport gateway must never
# reintroduce LegacyApiTransport. Remaining old repositories are tracked as
# metrics until their own migration gates are reached.
for rel in MIGRATED_LEGACY_TRANSPORT_REPOSITORIES:
    path = ROOT / rel
    if not path.exists():
        failures.append(f'Migrated repository is missing: {rel}')
        continue
    text = read(path)
    for token in ['LegacyApiTransport', 'legacy_api_transport.dart']:
        if token in text:
            failures.append(f'Migrated repository reintroduced legacy transport {token}: {rel}')

# Generated files must not contain custom parsing helpers or hand-written
# top-level helper shims. Generated Retrofit files must remain disposable.
for path in LIB.rglob('*.g.dart'):
    text = read(path)
    rel = path.relative_to(ROOT)
    for helper in ['_extractList', '_extractMap', '_jsonMap']:
        if helper in text:
            failures.append(f'Generated file contains custom helper parsing function {helper}: {rel}')
    if re.search(r'^\s*(?:Map<[^>]+>|List<[^>]+>|Object\??|dynamic|bool|String|int|double|num|void)\s+ApiResponseNormalizer\.', text, re.MULTILINE):
        failures.append(f'Generated file contains custom top-level ApiResponseNormalizer helper: {rel}')
    if re.search(r'^\s*(?:Map<[^>]+>|List<[^>]+>|Object\??|dynamic|bool|String|int|double|num|void)\s+_\w+\s*\(', text, re.MULTILINE):
        failures.append(f'Generated file contains custom top-level private helper: {rel}')

# AppError must stay infrastructure-neutral.
app_error = LIB / 'core/error/app_error.dart'
if app_error.exists():
    text = read(app_error)
    forbidden = ['package:dio', 'core/api/', 'ApiException', 'DioException', 'request_control']
    for token in forbidden:
        if token in text:
            failures.append(f'AppError infrastructure dependency found: {token}')

# Retrofit API boundaries must be typed. Source data services may return
# ApiResponse<T>/DTO envelopes, but not dynamic Future<Object?> payloads.
for path in LIB.glob('features/**/data/sources/*.dart'):
    if path.name.endswith('.g.dart'):
        continue
    text = read(path)
    rel = path.relative_to(ROOT)
    if re.search(r'Future\s*<\s*Object\s*\?\s*>\s+\w+\s*\(', text):
        failures.append(f'Retrofit data source exposes dynamic Future<Object?> API boundary: {rel}')
        bump('retrofit_future_object_methods')

# Retrofit request bodies must be typed request DTOs, not raw Object?/Map.
for path in LIB.glob('features/**/data/sources/*.dart'):
    if path.name.endswith('.g.dart'):
        continue
    text = read(path)
    rel = path.relative_to(ROOT)
    if '@Body() Object?' in text:
        failures.append(f'Retrofit method uses untyped @Body() Object?: {rel}')
        bump('retrofit_body_object_methods')
    if re.search(r'@Body\(\)\s+Map(?:<[^>]+>)?', text):
        failures.append(f'Retrofit method uses raw @Body() Map instead of a request DTO: {rel}')
        bump('retrofit_body_map_methods')


# Feature repository implementations must not depend on the legacy ApiClient type.
# Remaining old transport compatibility must be isolated behind LegacyApiTransport
# while modules are migrated to Retrofit.
for path in LIB.glob('features/**/data/repositories/*.dart'):
    text = read(path)
    rel = path.relative_to(ROOT)
    if re.search(r'\bApiClient\b', text):
        failures.append(f'Feature data repository still references legacy ApiClient: {rel}')
        bump('feature_repository_apiclient_refs')
    if re.search(r'final\s+dynamic\s+api\s*;', text):
        failures.append(f'Feature data repository uses dynamic api transport instead of LegacyApiTransport: {rel}')
        bump('feature_repository_dynamic_api_refs')

# Legacy infrastructure must not reintroduce HTTP body logging. Console-level
# Dio logging must stay metadata-only and pass through SafeDioLoggingInterceptor.
for path in [LIB / 'core/api/api_client.dart', *LIB.glob('core/api/interceptors/*.dart')]:
    if not path.exists():
        continue
    text = read(path)
    rel = path.relative_to(ROOT)
    if 'PrettyDioLogger' in text:
        failures.append(f'PrettyDioLogger is banned because it can expose HTTP bodies: {rel}')
        bump('unsafe_http_logging_interceptor')
    if re.search(r'\bLogInterceptor\s*\(', text):
        failures.append(f'Dio LogInterceptor is banned; use SafeDioLoggingInterceptor: {rel}')
        bump('unsafe_http_logging_interceptor')
    if re.search(r'\b(requestBody|responseBody)\s*:', text):
        failures.append(f'HTTP body logging flags are banned from Dio logging config: {rel}')
        bump('unsafe_http_body_logging')

# Direct body/response printing is always unsafe, even in debug builds.
for path in LIB.rglob('*.dart'):
    rel = str(path.relative_to(ROOT))
    if rel.endswith('core/debug/app_logger.dart') or rel.endswith('core/observability/app_logger.dart'):
        continue
    text = read(path)
    if re.search(r'\b(debugPrint|print)\s*\([^\n;]*(response\.data|request\.data|options\.data|err\.response\?\.data)', text):
        failures.append(f'Direct HTTP body print/debugPrint is banned: {rel}')
        bump('unsafe_direct_http_body_print')
    if re.search(r'\bAppLogger\.\w+\s*\([^\n;]*(response\.data|request\.data|options\.data|err\.response\?\.data)', text):
        failures.append(f'AppLogger must not log raw HTTP body data directly: {rel}')
        bump('unsafe_direct_http_body_print')

# Direct print/debugPrint with nearby sensitive terms is unsafe even when the
# printed value is not obviously an HTTP body. All such logging must go through
# AppLogger/TokenRedactor.
sensitive_log_terms = re.compile(
    r'(authorization|access[_-]?token|refresh[_-]?token|password|otp|private[_-]?key|secret)',
    re.IGNORECASE,
)
for path in LIB.rglob('*.dart'):
    rel = str(path.relative_to(ROOT))
    if rel.endswith('core/debug/app_logger.dart') or rel.endswith('core/observability/app_logger.dart'):
        continue
    lines = read(path).splitlines()
    for index, line in enumerate(lines):
        if not re.search(r'\b(debugPrint|print)\s*\(', line):
            continue
        window = '\n'.join(lines[max(0, index - 3): min(len(lines), index + 4)])
        if sensitive_log_terms.search(window):
            failures.append(f'Direct print/debugPrint near sensitive data is banned: {rel}:{index + 1}')
            bump('unsafe_sensitive_print_debugprint')

legacy_adapter = LIB / 'core/providers/legacy_repository_adapter_providers.dart'
if legacy_adapter.exists():
    text = read(legacy_adapter)
    if 'ref.watch(apiClientProvider)' in text:
        failures.append('Legacy repository adapters must use legacyApiTransportProvider, not apiClientProvider')


# Production observability/security must remain wired at startup and through core HTTP.
main_text = read(LIB / 'main.dart') if (LIB / 'main.dart').exists() else ''
bootstrap_text = read(LIB / 'bootstrap.dart') if (LIB / 'bootstrap.dart').exists() else ''
app_config_text = read(LIB / 'core/config/app_config.dart') if (LIB / 'core/config/app_config.dart').exists() else ''
app_config_validator_text = read(LIB / 'core/config/app_config_validator.dart') if (LIB / 'core/config/app_config_validator.dart').exists() else ''
observability_provider_text = read(LIB / 'core/observability/observability_provider.dart') if (LIB / 'core/observability/observability_provider.dart').exists() else ''
api_client_text = read(LIB / 'core/api/api_client.dart') if (LIB / 'core/api/api_client.dart').exists() else ''
core_providers_text = read(LIB / 'core/providers/core_providers.dart') if (LIB / 'core/providers/core_providers.dart').exists() else ''
if 'bootstrapOpenVts' not in main_text or 'runZonedGuarded' not in bootstrap_text:
    failures.append('App startup must be wrapped by bootstrapOpenVts/runZonedGuarded observability wiring')
if 'PlatformDispatcher.instance.onError' not in bootstrap_text or 'FlutterError.onError' not in bootstrap_text:
    failures.append('Global Flutter/platform errors must be captured by observability in bootstrap.dart')
if 'AppConfigValidator' not in bootstrap_text or '.validate(config)' not in bootstrap_text:
    failures.append('Production config validation must run during bootstrap before app initialization')
if 'config.enableNetworkLogs' not in app_config_validator_text or 'Production network logs must be disabled' not in app_config_validator_text:
    failures.append('AppConfigValidator must reject production config with network logs enabled')
if 'Production must enable at least one crash backend' not in app_config_validator_text:
    failures.append('AppConfigValidator must reject production config without a crash backend')
if 'Production socket URL' not in app_config_validator_text or '10.0.2.2' not in app_config_validator_text:
    failures.append('AppConfigValidator must reject missing/local/emulator production socket URLs')
if 'enableNetworkLogsRaw.trim().isEmpty' not in app_config_text or 'env != AppEnvironment.prod' not in app_config_text:
    failures.append('AppConfig.fromDartDefine must default production network logs to disabled')
if 'config.enableNetworkLogs' not in api_client_text:
    failures.append('ApiClient must gate SafeDioLoggingInterceptor behind config.enableNetworkLogs')
if 'config.enablePerformanceDiagnostics' not in api_client_text or 'container.appConfig.enablePerformanceDiagnostics' not in core_providers_text:
    failures.append('Diagnostic Dio interceptors must be gated by enablePerformanceDiagnostics')
if 'config.isProduction' not in observability_provider_text or observability_provider_text.find('config.isProduction') > observability_provider_text.find('NoopObservabilityService'):
    failures.append('Production observability provider must not return NoopObservabilityService')
if 'observabilityServiceProvider' not in read(LIB / 'core/diagnostics/diagnostics_providers.dart'):
    failures.append('Diagnostics providers must use observabilityServiceProvider, not a no-op crash reporter')
if 'NoopCrashReporter();' in read(LIB / 'core/diagnostics/diagnostics_providers.dart'):
    failures.append('crashReporterProvider must not return NoopCrashReporter in production wiring')

# Fake Retrofit pattern check: @RestApi class with Dio field/manual methods.
for path in LIB.glob('features/**/data/sources/*retrofit_service.dart'):
    text = read(path)
    rel = path.relative_to(ROOT)
    if '@RestApi()' in text and re.search(r'@RestApi\(\)\s*class\s+', text):
        failures.append(f'Fake Retrofit concrete service: {rel}')
    if '@RestApi()' in text and 'abstract class' not in text:
        failures.append(f'Retrofit service is not abstract: {rel}')
    if '@RestApi()' in text and re.search(r'\bfinal\s+Dio\b|\b_dio\b|\.get<|\.post<|\.patch<|\.delete<', text):
        failures.append(f'Potential manual Dio call inside Retrofit service: {rel}')




# Direct setState calls are banned in feature/shared presentation code.
# Use Riverpod controllers for API/business state and updateLocalUiState only for documented local UI state.
for path in list((LIB / 'features').glob('**/*.dart')) + list((LIB / 'shared').glob('**/*.dart')):
    rel = rel_path(path)
    text = read(path)
    if 'setState(' in text:
        failures.append(f'Direct setState call remains: {rel}')
        bump('direct_setstate_calls')
    if 'updateLocalUiState(this' in text:
        bump('centralized_local_ui_state_updates')

# Soft warning for remaining direct repository implementation type usage in presentation.
repository_type_names = set()
for repo_path in LIB.glob('features/**/data/repositories/*.dart'):
    for match in re.finditer(r'class\s+(\w+Repository)\b', read(repo_path)):
        repository_type_names.add(match.group(1))
for path in LIB.glob('features/**/presentation/**/*.dart'):
    text = read(path)
    rel = path.relative_to(ROOT)
    for name in sorted(repository_type_names):
        if re.search(rf'\b{name}\b', text):
            warnings.append(f'Direct repository implementation type still appears in presentation: {rel}: {name}')
            break

# Soft migration warnings (reported but not failing yet).
for path in LIB.glob('features/**/presentation/**/*.dart'):
    text = read(path)
    rel = path.relative_to(ROOT)
    if 'Map<String, dynamic>' in text:
        warnings.append(f'Map<String, dynamic> still used in presentation: {rel}')


# Direct logging checks outside logger implementation.
for path in LIB.rglob('*.dart'):
    rel = str(path.relative_to(ROOT))
    if rel.endswith('app_logger.dart'):
        continue
    text = read(path)
    if re.search(r'\b(debugPrint|print)\s*\(', text):
        warnings.append(f'Direct print/debugPrint outside logger implementation: {rel}')
        bump('direct_print_debugprint_calls')
    if re.search(r'(accessToken|refreshToken|Authorization|password|otp).*(debugPrint|print|AppLogger)', text, re.IGNORECASE):
        failures.append(f'Possible sensitive logging pattern outside logger: {rel}')


# Migrated files must stay free of migration-stage bridges.
for rel in sorted(MIGRATED_FILES):
    path = ROOT / rel
    if not path.exists():
        failures.append(f'Migrated file missing: {rel}')
        continue
    text = read(path)
    for banned in MIGRATED_BANNED_IMPORTS:
        if banned in text:
            failures.append(f'Migrated file imports banned bridge/infrastructure {banned}: {rel}')
    for token in MIGRATED_BANNED_TOKENS:
        if re.search(rf'\b{re.escape(token)}\b', text):
            failures.append(f'Migrated file references banned legacy token {token}: {rel}')
    if '/presentation/' in rel and 'Map<String, dynamic>' in text:
        failures.append(f'Migrated presentation file exposes Map<String, dynamic>: {rel}')
    if '/domain/' in rel and 'Map<String, dynamic>' in text:
        failures.append(f'Migrated domain file exposes Map<String, dynamic>: {rel}')

# Migrated repositories must call typed Retrofit/data sources, not legacy adapters.
admin_form_repo = ROOT / 'lib/features/admin/data/repositories/admin_form_repository_impl.dart'
if admin_form_repo.exists():
    text = read(admin_form_repo)
    if 'AdminFormApiService' not in text:
        failures.append('AdminFormRepositoryImpl does not use AdminFormApiService')
    for token in ['AdminUsersRepository', 'AdminVehiclesRepository', 'ApiClient', 'CommonRepository']:
        if token in text:
            failures.append(f'AdminFormRepositoryImpl still uses legacy dependency: {token}')
reference_repo = ROOT / 'lib/features/reference_data/data/repositories/reference_data_repository_impl.dart'
if reference_repo.exists():
    text = read(reference_repo)
    if 'ReferenceDataApiService' not in text:
        failures.append('ReferenceDataRepositoryImpl does not use ReferenceDataApiService')
    for token in ['CommonRepository', 'ApiClient']:
        if token in text:
            failures.append(f'ReferenceDataRepositoryImpl still uses legacy dependency: {token}')


admin_driver_repo = ROOT / 'lib/features/admin/data/repositories/admin_driver_form_repository_impl.dart'
if admin_driver_repo.exists():
    text = read(admin_driver_repo)
    if 'AdminWorkflowApiService' not in text:
        failures.append('AdminDriverFormRepositoryImpl does not use AdminWorkflowApiService')
    for token in ['ApiClient', 'CommonRepository', 'RepositoryAdapter']:
        if token in text:
            failures.append(f'AdminDriverFormRepositoryImpl still uses legacy dependency: {token}')

admin_device_repo = ROOT / 'lib/features/admin/data/repositories/admin_device_form_repository_impl.dart'
if admin_device_repo.exists():
    text = read(admin_device_repo)
    if 'AdminWorkflowApiService' not in text:
        failures.append('AdminDeviceFormRepositoryImpl does not use AdminWorkflowApiService')
    for token in ['ApiClient', 'CommonRepository', 'RepositoryAdapter']:
        if token in text:
            failures.append(f'AdminDeviceFormRepositoryImpl still uses legacy dependency: {token}')

admin_team_repo = ROOT / 'lib/features/admin/data/repositories/admin_team_form_repository_impl.dart'
if admin_team_repo.exists():
    text = read(admin_team_repo)
    if 'AdminWorkflowApiService' not in text:
        failures.append('AdminTeamFormRepositoryImpl does not use AdminWorkflowApiService')
    for token in ['ApiClient', 'CommonRepository', 'RepositoryAdapter']:
        if token in text:
            failures.append(f'AdminTeamFormRepositoryImpl still uses legacy dependency: {token}')

user_vehicle_repo = ROOT / 'lib/features/user/data/repositories/user_vehicle_form_repository_impl.dart'
if user_vehicle_repo.exists():
    text = read(user_vehicle_repo)
    if 'UserVehicleFormApiService' not in text:
        failures.append('UserVehicleFormRepositoryImpl does not use UserVehicleFormApiService')
    for token in ['ApiClient', 'CommonRepository', 'RepositoryAdapter']:
        if token in text:
            failures.append(f'UserVehicleFormRepositoryImpl still uses legacy dependency: {token}')



support_new_ticket_repo = ROOT / 'lib/features/support/data/repositories/support_new_ticket_repository_impl.dart'
if support_new_ticket_repo.exists():
    text = read(support_new_ticket_repo)
    if 'SupportNewTicketApiService' not in text:
        failures.append('SupportNewTicketRepositoryImpl does not use SupportNewTicketApiService')
    for token in ['ApiClient', 'CommonRepository', 'SupportRepositoryAdapter', 'AdminSupportRepository', 'UserSupportRepository', 'SuperadminRepository']:
        if token in text:
            failures.append(f'SupportNewTicketRepositoryImpl still uses legacy dependency: {token}')

support_new_ticket_screen = ROOT / 'lib/features/support/presentation/new_ticket/new_ticket_screen.dart'
if support_new_ticket_screen.exists():
    text = read(support_new_ticket_screen)
    for token in ['SupportNewTicketControllerDeps', 'supportNewTicketControllerDepsProvider', 'ChangeNotifier', 'AppCancellationHandle', 'LegacyErrorPresenter', 'repository_bridge_providers.dart']:
        if token in text:
            failures.append(f'SupportNewTicketScreen still uses legacy new-ticket dependency: {token}')

support_new_ticket_controller = ROOT / 'lib/features/support/presentation/new_ticket/new_ticket_controller.dart'
if support_new_ticket_controller.exists():
    text = read(support_new_ticket_controller)
    for token in ['ChangeNotifier', 'dynamic repository', 'AppCancellationHandle', 'TextEditingController', 'SupportNewTicketControllerDeps']:
        if token in text:
            failures.append(f'NewTicketController still uses legacy controller pattern: {token}')


map_telemetry_provider = ROOT / 'lib/features/map/presentation/providers/map_telemetry_provider.dart'
if map_telemetry_provider.exists():
    text = read(map_telemetry_provider)
    for token in ['repository_bridge_providers.dart', 'legacy_repository_adapter_providers.dart', 'core/providers/repository_providers.dart']:
        if token in text:
            failures.append(f'MapTelemetryProvider still imports bridge dependency: {token}')
    if 'mapVehicleSnapshotStreamProvider' not in text:
        failures.append('MapTelemetryProvider does not use map socket DI snapshot stream')

map_socket_providers = ROOT / 'lib/features/map/di/map_socket_providers.dart'
if map_socket_providers.exists():
    text = read(map_socket_providers)
    for token in ['repository_bridge_providers.dart', 'legacy_repository_adapter_providers.dart', 'core/providers/repository_providers.dart']:
        if token in text:
            failures.append(f'Map socket provider imports bridge dependency: {token}')

map_projection = ROOT / 'lib/features/map/presentation/open_vts_map/open_vts_map_marker_projection.dart'
if map_projection.exists():
    text = read(map_projection)
    if "domain/entities/telemetry_point.dart" in text:
        failures.append('OpenVTS map projection imports TelemetryPoint directly')
    if 'MapVehicleSnapshot' not in text:
        failures.append('OpenVTS map projection does not consume MapVehicleSnapshot')
    if re.search(r'Socket(Service|Events)|socket\.stream|Map<String, dynamic>', text):
        failures.append('OpenVTS map projection must consume typed domain/UI-ready entities, not raw socket payloads')

# Map-specific enterprise safety checks. The shared map screen and role wrappers
# must not reintroduce legacy facade access or repository-owned API state.
map_presentation_files = list((LIB / 'features/map/presentation').glob('**/*.dart'))
role_map_screens = [
    LIB / 'features/admin/presentation/screens/map/map_screen.dart',
    LIB / 'features/superadmin/presentation/screens/map/map_screen.dart',
    LIB / 'features/user/presentation/screens/map/map_screen.dart',
]
for path in [*map_presentation_files, *role_map_screens]:
    if not path.exists():
        continue
    text = read(path)
    rel = rel_path(path)
    if 'legacy_repository_facade_providers.dart' in text:
        failures.append(f'Map presentation imports legacy repository facade providers: {rel}')
    if re.search(r'ref\.(read|watch)\((adminVehiclesRepositoryProvider|superadminRepositoryProvider|userVehiclesRepositoryProvider|roleNotificationsRepositoryProvider)', text):
        failures.append(f'Map presentation reads legacy repository provider directly: {rel}')
    if 'SocketService' in text or 'socket.stream' in text or 'SocketEvents' in text:
        failures.append(f'Map presentation subscribes to raw socket events directly: {rel}')

map_screen = ROOT / 'lib/features/map/presentation/open_vts_map/open_vts_map_screen.dart'
if map_screen.exists():
    text = read(map_screen)
    if 'ref.listen<List<MapVehiclePoint>>' in text:
        failures.append('OpenVtsMapScreen listens to live telemetry in the full screen build/state')
    if 'final livePoints = ref.watch(liveMapVehiclePointsProvider);\n    final pointsToRender' in text:
        failures.append('OpenVtsMapScreen broadly watches live telemetry before building the full map stack')
    if 'RepaintBoundary' not in text or 'FlutterMap' not in text:
        failures.append('OpenVtsMapScreen must keep FlutterMap behind a RepaintBoundary')

marker_layer = ROOT / 'lib/features/map/presentation/open_vts_map/widgets/live_vehicle_marker_layer.dart'
if marker_layer.exists():
    text = read(marker_layer)
    for token in ['/data/repositories/', 'core/api', 'ApiClient', 'SocketService', 'SocketEvents', 'socket.stream']:
        if token in text:
            failures.append(f'LiveVehicleMarkerLayer must remain presentation-only and UI-ready: {token}')
    if 'MapVehiclePoint' not in text or 'MarkerLayer' not in text:
        failures.append('LiveVehicleMarkerLayer must receive UI-ready MapVehiclePoint data and render MarkerLayer')


# Offline/cache enterprise foundation checks.
pubspec_text = read(ROOT / 'pubspec.yaml') if (ROOT / 'pubspec.yaml').exists() else ''
for dependency in ['drift:', 'sqlite3_flutter_libs:', 'path_provider:']:
    if dependency not in pubspec_text:
        failures.append(f'Offline/cache dependency missing from pubspec.yaml: {dependency}')
if 'drift_dev:' not in pubspec_text:
    failures.append('Offline/cache code generation dependency missing from pubspec.yaml: drift_dev')

required_cache_files = [
    'lib/core/database/app_database.dart',
    'lib/core/database/database_providers.dart',
    'lib/core/database/tables/cached_vehicle_table.dart',
    'lib/core/database/tables/cached_history_point_table.dart',
    'lib/core/database/tables/cache_metadata_table.dart',
    'lib/core/storage/cache_policy.dart',
    'lib/core/storage/cache_keys.dart',
    'lib/features/vehicles/data/local/vehicle_local_source.dart',
]
for rel in required_cache_files:
    if not (ROOT / rel).exists():
        failures.append(f'Offline/cache foundation file missing: {rel}')

cache_key_builder_text = read(LIB / 'core/security/cache_key_builder.dart')
for token in ['environmentKey', 'role', 'accountId', 'userId']:
    if token not in cache_key_builder_text:
        failures.append(f'CacheKeyBuilder must include tenant/user/environment isolation field: {token}')

vehicle_repo_text = read(LIB / 'features/vehicles/data/repositories/vehicle_repository_impl.dart')
if 'VehicleLocalSource' not in vehicle_repo_text or 'saveVehicleList' not in vehicle_repo_text or 'readVehicleList' not in vehicle_repo_text:
    failures.append('VehicleRepositoryImpl must use VehicleLocalSource for vehicle list cache save/read fallback')

for path in [
    LIB / 'core/database/tables/cached_vehicle_table.dart',
    LIB / 'core/database/tables/cached_history_point_table.dart',
    LIB / 'core/database/tables/cache_metadata_table.dart',
]:
    text = read(path)
    if re.search(r'\b(TextColumn|BlobColumn)\s+get\s+(accessToken|refreshToken|token|password|otp|secret)\b', text, re.IGNORECASE):
        failures.append(f'Sensitive credential column must not be cached outside secure storage: {rel_path(path)}')

# Enterprise gateway metrics are intentionally non-failing during the
# migration baseline stage. They expose the remaining legacy surface area so
# each gate can reduce measured debt without hiding it behind the allowlist.
feature_shared_files = list((LIB / 'features').glob('**/*.dart')) + list((LIB / 'shared').glob('**/*.dart'))
presentation_files = list(LIB.glob('features/**/presentation/**/*.dart')) + list(LIB.glob('shared/**/presentation/**/*.dart'))
feature_source_files = [
    path
    for path in LIB.glob('features/**/data/sources/*.dart')
    if not path.name.endswith('.g.dart')
]
feature_repository_files = list(LIB.glob('features/**/data/repositories/*.dart'))

set_gateway_metric(
    'direct_setstate_calls_in_features_and_shared',
    count_token(feature_shared_files, 'setState('),
)
set_gateway_metric(
    'update_local_ui_state_calls_in_features_and_shared',
    count_regex(feature_shared_files, r'\bupdateLocalUiState\s*\('),
)
set_gateway_metric(
    'update_local_ui_state_calls_in_presentation',
    count_regex(presentation_files, r'\bupdateLocalUiState\s*\('),
)
set_gateway_metric(
    'update_local_ui_state_presentation_files',
    count_files_with_token(presentation_files, 'updateLocalUiState'),
)
set_gateway_metric(
    'probable_business_update_local_ui_state_calls',
    count_probable_business_update_local_ui_calls(presentation_files),
)
set_gateway_metric(
    'future_object_methods_in_feature_data_sources',
    count_regex(feature_source_files, r'Future\s*<\s*Object\s*\?\s*>\s+\w+\s*\('),
)
set_gateway_metric(
    'future_object_source_files',
    sum(
        1
        for path in feature_source_files
        if re.search(r'Future\s*<\s*Object\s*\?\s*>\s+\w+\s*\(', read(path))
    ),
)
set_gateway_metric(
    'legacy_api_transport_occurrences_in_repositories',
    count_token(feature_repository_files, 'LegacyApiTransport'),
)
set_gateway_metric(
    'migrated_repository_legacy_api_transport_files',
    count_files_with_token([ROOT / rel for rel in MIGRATED_LEGACY_TRANSPORT_REPOSITORIES if (ROOT / rel).exists()], 'LegacyApiTransport'),
)
set_gateway_metric(
    'legacy_api_transport_repository_files',
    count_files_with_token(feature_repository_files, 'LegacyApiTransport'),
)
set_gateway_metric(
    'legacy_error_presenter_occurrences_in_presentation',
    count_token(presentation_files, 'LegacyErrorPresenter'),
)
set_gateway_metric(
    'legacy_error_presenter_presentation_files',
    count_files_with_token(presentation_files, 'LegacyErrorPresenter'),
)
set_gateway_metric(
    'app_cancellation_handle_occurrences_in_presentation',
    count_token(presentation_files, 'AppCancellationHandle'),
)
set_gateway_metric(
    'app_cancellation_handle_presentation_files',
    count_files_with_token(presentation_files, 'AppCancellationHandle'),
)
set_gateway_metric(
    'legacy_repository_facade_import_occurrences_in_presentation',
    count_token(presentation_files, 'legacy_repository_facade_providers.dart'),
)
set_gateway_metric(
    'legacy_repository_facade_import_files_in_presentation',
    count_files_with_token(presentation_files, 'legacy_repository_facade_providers.dart'),
)
set_gateway_metric(
    'error_effect_migrated_legacy_error_presenter_files',
    count_files_with_token([ROOT / rel for rel in ERROR_EFFECT_MIGRATED_FILES if (ROOT / rel).exists()], 'LegacyErrorPresenter'),
)
set_gateway_metric(
    'error_effect_migrated_app_cancellation_handle_files',
    count_files_with_token([ROOT / rel for rel in ERROR_EFFECT_MIGRATED_FILES if (ROOT / rel).exists()], 'AppCancellationHandle'),
)
set_gateway_metric('migration_allowlist_entries', len(allowlisted))


set_gateway_metric(
    'offline_cache_drift_dependency_present',
    1 if 'drift:' in pubspec_text and 'drift_dev:' in pubspec_text else 0,
)
set_gateway_metric(
    'offline_cache_foundation_files_present',
    sum(1 for rel in required_cache_files if (ROOT / rel).exists()),
)
set_gateway_metric(
    'offline_cache_vehicle_local_source_files',
    1 if (LIB / 'features/vehicles/data/local/vehicle_local_source.dart').exists() else 0,
)

security_files = [
    LIB / 'bootstrap.dart',
    LIB / 'core/config/app_config_validator.dart',
    LIB / 'core/api/api_client.dart',
    LIB / 'core/providers/core_providers.dart',
    LIB / 'core/observability/observability_provider.dart',
    LIB / 'core/security/token_redactor.dart',
]
set_gateway_metric(
    'production_config_validation_in_bootstrap',
    1 if 'AppConfigValidator' in bootstrap_text and '.validate(config)' in bootstrap_text else 0,
)
set_gateway_metric(
    'production_network_logs_rejected_by_validator',
    1 if 'Production network logs must be disabled' in app_config_validator_text else 0,
)
set_gateway_metric(
    'production_crash_backend_required_by_validator',
    1 if 'Production must enable at least one crash backend' in app_config_validator_text else 0,
)
set_gateway_metric(
    'diagnostic_interceptors_gated_by_config',
    1 if 'enablePerformanceDiagnostics' in api_client_text and 'enablePerformanceDiagnostics' in core_providers_text else 0,
)
set_gateway_metric(
    'production_noop_observability_blocked',
    1 if 'config.isProduction' in observability_provider_text else 0,
)
set_gateway_metric(
    'token_redactor_private_key_rule_present',
    1 if 'PRIVATE KEY' in read(LIB / 'core/security/token_redactor.dart') else 0,
)
set_gateway_metric(
    'production_security_gate_files_present',
    sum(1 for path in security_files if path.exists()),
)

map_presentation_metric_files = list((LIB / 'features/map/presentation').glob('**/*.dart')) + [
    LIB / 'features/admin/presentation/screens/map/map_screen.dart',
    LIB / 'features/superadmin/presentation/screens/map/map_screen.dart',
    LIB / 'features/user/presentation/screens/map/map_screen.dart',
]
map_presentation_metric_files = [path for path in map_presentation_metric_files if path.exists()]
set_gateway_metric(
    'map_presentation_legacy_facade_import_files',
    count_files_with_token(map_presentation_metric_files, 'legacy_repository_facade_providers.dart'),
)
set_gateway_metric(
    'map_presentation_app_cancellation_handle_files',
    count_files_with_token(map_presentation_metric_files, 'AppCancellationHandle'),
)
set_gateway_metric(
    'map_presentation_legacy_error_presenter_files',
    count_files_with_token(map_presentation_metric_files, 'LegacyErrorPresenter'),
)
set_gateway_metric(
    'map_presentation_raw_socket_subscription_refs',
    sum(
        count_token(map_presentation_metric_files, token)
        for token in ['SocketService', 'SocketEvents', 'socket.stream']
    ),
)

for rel, categories in sorted(allowlisted_warning_categories.items()):
    for category in categories:
        allowlist_category_metric(rel, category)
    category_text = ', '.join(sorted(categories))
    warnings.append(f'Allowlisted legacy violations remain: {rel}: {category_text}')

metrics['migration_allowlist_files'] = len(allowlisted)
metrics['migration_allowlist_active_warning_files'] = len(allowlisted_warning_categories)

if failures:
    print('Architecture guard failed:')
    for failure in failures:
        print(f' - {failure}')
    sys.exit(1)

print('Architecture guard passed.')
print('Architecture guard metrics:')
for key in sorted(metrics):
    print(f' - {key}: {metrics[key]}')
print('Enterprise Gateway Metrics:')
for key in sorted(enterprise_gateway_metrics):
    print(f' - {key}: {enterprise_gateway_metrics[key]}')
if warnings:
    print(f'Architecture guard warnings: {len(warnings)}')
    for warning in warnings[:50]:
        print(f' - {warning}')
