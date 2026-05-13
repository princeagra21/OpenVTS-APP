import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/data/mappers/user_notification_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_notification_repository_impl.dart';
import 'package:open_vts/features/user/data/sources/user_notification_api_service.dart';

void main() {
  test('maps notifications from enveloped response', () async {
    final repo = UserNotificationRepositoryImpl(api: _FakeUserNotificationApiService(), mapper: const UserNotificationMapper());

    final result = await repo.getNotifications();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.single.title, 'Overspeed');
  });

  test('maps action=false to ServerError', () async {
    final repo = UserNotificationRepositoryImpl(api: _FakeUserNotificationApiService(action: false), mapper: const UserNotificationMapper());

    final result = await repo.markAllNotificationsRead();

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ServerError>());
  });
}

class _FakeUserNotificationApiService implements UserNotificationApiService {
  _FakeUserNotificationApiService({this.action = true});
  final bool action;
  @override
  Future<Object?> getNotifications() async => _response(<String, Object?>{'notifications': const <Object?>[<String, Object?>{'id': 'n-1', 'title': 'Overspeed'}]});
  @override
  Future<Object?> markNotificationRead(String id) async => _response(null);
  @override
  Future<Object?> markAllNotificationsRead() async => _response(null);
  @override
  Future<Object?> getPreferences() async => _response(<String, Object?>{'channels': const <String, Object?>{}});
  @override
  Future<Object?> updatePreferences(Map<String, Object?> body) async => _response(null);
  Map<String, Object?> _response(Object? data) => <String, Object?>{'data': <String, Object?>{'action': action, 'message': action ? '' : 'Notification rejected', 'data': data}};
}
