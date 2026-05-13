import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/security/deep_link_validator.dart';

void main() {
  const validator = DeepLinkValidator(
    allowedRoutePrefixes: <String>{'/user', '/admin', '/track'},
    allowedHosts: <String>{'openvts.example'},
  );

  bool allowAll(String path) => true;

  test('rejects unauthorized host and unsafe route payloads', () {
    final badHost = validator.validate(
      Uri.parse('https://evil.example/user/dashboard'),
      canOpenPath: allowAll,
    );
    final tokenInQuery = validator.validate(
      Uri.parse('https://openvts.example/user/dashboard?access_token=abc'),
      canOpenPath: allowAll,
    );
    final traversal = validator.validate(
      Uri.parse('https://openvts.example/user/../admin'),
      canOpenPath: allowAll,
    );

    expect(badHost.isFailure, isTrue);
    expect(tokenInQuery.isFailure, isTrue);
    expect(traversal.isFailure, isTrue);
  });

  test('rejects route when role cannot open path', () {
    final result = validator.validate(
      Uri.parse('https://openvts.example/admin/dashboard'),
      canOpenPath: (_) => false,
    );

    expect(result.isFailure, isTrue);
  });

  test('accepts safe allowed route', () {
    final result = validator.validate(
      Uri.parse('https://openvts.example/user/dashboard?tab=vehicles'),
      canOpenPath: allowAll,
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.path, '/user/dashboard');
  });
}
