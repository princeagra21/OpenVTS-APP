import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/security/token_redactor.dart';

void main() {
  const redactor = TokenRedactor();

  test('redacts bearer tokens and sensitive json fields', () {
    final output = redactor.redact(
      'Authorization: Bearer abc.def.ghi {"accessToken":"a","refreshToken":"b","password":"secret","otp":"123456","email":"u@example.com"}',
    );

    expect(output, isNot(contains('abc.def.ghi')));
    expect(output, isNot(contains('secret')));
    expect(output, isNot(contains('123456')));
    expect(output, isNot(contains('u@example.com')));
    expect(output, contains('[REDACTED]'));
  });

  test('redacts private key blocks and sensitive map values', () {
    final output = redactor.redact('''
-----BEGIN PRIVATE KEY-----
abc123
-----END PRIVATE KEY-----
address: 12-main-st phone: 9999999999 lat: 28.6
''');

    expect(output, isNot(contains('abc123')));
    expect(output, isNot(contains('12-main-st')));
    expect(output, isNot(contains('9999999999')));
    expect(output, isNot(contains('28.6')));
  });
}
