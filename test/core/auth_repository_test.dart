import 'package:fleet_stack/core/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Extracts token from top-level token', () {
    final t = AuthRepository.extractToken({'token': 'abc'});
    expect(t, 'abc');
  });

  test('Extracts token from top-level accessToken', () {
    final t = AuthRepository.extractToken({'accessToken': 'abc'});
    expect(t, 'abc');
  });

  test('Extracts token from nested data.token', () {
    final t = AuthRepository.extractToken({
      'data': {'token': 'abc'},
    });
    expect(t, 'abc');
  });

  test('Returns null when token not present', () {
    final t = AuthRepository.extractToken({'data': {}});
    expect(t, isNull);
  });
}
