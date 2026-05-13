import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';

void main() {
  test('extracts list from standard nested API envelope', () {
    final raw = <String, Object?>{
      'status': 'success',
      'data': <String, Object?>{
        'action': true,
        'message': '',
        'data': <String, Object?>{
          'userslist': const <Object?>[
            <String, Object?>{'id': '1'},
          ],
        },
      },
    };

    final list = ApiResponseNormalizer.listOf(raw, preferredKeys: const <String>['userslist']);

    expect(list.single, isA<Map<String, Object?>>());
  });

  test('extracts list from raw list without envelope', () {
    final list = ApiResponseNormalizer.listOf(const <Object?>[1, 2, 3]);

    expect(list, const <Object?>[1, 2, 3]);
    expect(ApiResponseNormalizer.action(list), isTrue);
  });

  test('extracts object map from nested feature key', () {
    final raw = <String, Object?>{
      'data': <String, Object?>{
        'action': true,
        'data': <String, Object?>{
          'vehicle': <String, Object?>{'id': 'v1'},
        },
      },
    };

    final map = ApiResponseNormalizer.mapPayloadOf(raw, preferredKeys: const <String>['vehicle']);

    expect(map['id'], 'v1');
  });

  test('malformed response is safe by default and strict when requested', () {
    expect(ApiResponseNormalizer.listOf('bad'), isEmpty);
    expect(
      () => ApiResponseNormalizer.listOf('bad', strict: true),
      throwsA(isA<FormatException>()),
    );
  });

  test('reads action and message from nested envelope', () {
    final raw = <String, Object?>{
      'data': <String, Object?>{
        'action': false,
        'message': 'Rejected',
      },
    };

    expect(ApiResponseNormalizer.action(raw), isFalse);
    expect(ApiResponseNormalizer.message(raw), 'Rejected');
  });
}
