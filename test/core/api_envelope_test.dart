import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/api/api_envelope.dart';

void main() {
  group('ApiEnvelope', () {
    group('asMap', () {
      test('returns map as-is', () {
        const input = {'key': 'value'};
        expect(ApiEnvelope.asMap(input), input);
      });

      test('converts Map to Map<String, dynamic>', () {
        final input = <String, dynamic>{'key': 'value'};
        final result = ApiEnvelope.asMap(input);
        expect(result, {'key': 'value'});
        expect(result, isA<Map<String, dynamic>>());
      });

      test('returns empty map for non-map inputs', () {
        expect(ApiEnvelope.asMap(null), {});
        expect(ApiEnvelope.asMap('string'), {});
        expect(ApiEnvelope.asMap(42), {});
        expect(ApiEnvelope.asMap([]), {});
      });
    });

    group('nestedMap', () {
      test('extracts data from nested structure', () {
        final input = {
          'data': {
            'result': {
              'item': {'name': 'test'}
            }
          }
        };
        final result = ApiEnvelope.nestedMap(input);
        expect(result, {'name': 'test'});
      });

      test('stops at max depth', () {
        final input = {
          'data': {
            'data': {
              'data': {'name': 'test'}
            }
          }
        };
        final result = ApiEnvelope.nestedMap(input, maxDepth: 2);
        expect(result, {'data': {'name': 'test'}});
      });

      test('returns root if no nested data found', () {
        final input = {'name': 'test'};
        expect(ApiEnvelope.nestedMap(input), {'name': 'test'});
      });
    });

    group('payload', () {
      test('extracts data from root', () {
        final input = {'data': {'name': 'test'}};
        expect(ApiEnvelope.payload(input), {'name': 'test'});
      });

      test('extracts from nested structure', () {
        final input = {
          'response': {
            'data': {'name': 'test'}
          }
        };
        expect(ApiEnvelope.payload(input), {'name': 'test'});
      });
    });

    group('list', () {
      test('extracts list from root', () {
        final input = {'data': [1, 2, 3]};
        expect(ApiEnvelope.list(input), [1, 2, 3]);
      });

      test('extracts list from nested structure', () {
        final input = {
          'response': {
            'items': [1, 2, 3]
          }
        };
        expect(ApiEnvelope.list(input), [1, 2, 3]);
      });

      test('returns null if no list found', () {
        final input = {'name': 'test'};
        expect(ApiEnvelope.list(input), null);
      });
    });

    group('mapList', () {
      test('converts list of maps', () {
        final input = {
          'data': [
            {'id': 1, 'name': 'first'},
            {'id': 2, 'name': 'second'}
          ]
        };
        final result = ApiEnvelope.mapList(input);
        expect(result, [
          {'id': 1, 'name': 'first'},
          {'id': 2, 'name': 'second'}
        ]);
      });

      test('filters out non-map items', () {
        final input = {
          'data': [
            {'id': 1},
            'string',
            42
          ]
        };
        final result = ApiEnvelope.mapList(input);
        expect(result, [{'id': 1}]);
      });
    });

    group('message', () {
      test('extracts message from root', () {
        final input = {'message': 'Success'};
        expect(ApiEnvelope.message(input), 'Success');
      });

      test('extracts error from root', () {
        final input = {'error': 'Failed'};
        expect(ApiEnvelope.message(input), 'Failed');
      });

      test('extracts from nested structure', () {
        final input = {
          'data': {
            'message': 'Nested message'
          }
        };
        expect(ApiEnvelope.message(input), 'Nested message');
      });

      test('handles action/message/data pattern', () {
        final input = {
          'action': false,
          'message': 'Action failed',
          'data': {'some': 'data'}
        };
        expect(ApiEnvelope.message(input), 'Action failed');
      });

      test('returns null if no message found', () {
        final input = {'name': 'test'};
        expect(ApiEnvelope.message(input), null);
      });
    });

    group('errorMessage', () {
      test('returns message if present', () {
        final input = {'message': 'Error occurred'};
        expect(ApiEnvelope.errorMessage(input), 'Error occurred');
      });

      test('returns fallback if no message', () {
        final input = {'name': 'test'};
        expect(ApiEnvelope.errorMessage(input), 'Unknown error');
      });

      test('returns custom fallback', () {
        final input = {'name': 'test'};
        expect(ApiEnvelope.errorMessage(input, fallback: 'Custom error'), 'Custom error');
      });
    });

    group('isEmptyResponse', () {
      test('returns true for null', () {
        expect(ApiEnvelope.isEmptyResponse(null), isTrue);
      });

      test('returns true for empty collections', () {
        expect(ApiEnvelope.isEmptyResponse([]), isTrue);
        expect(ApiEnvelope.isEmptyResponse({}), isTrue);
      });

      test('returns false for non-empty data', () {
        expect(ApiEnvelope.isEmptyResponse([1, 2, 3]), isFalse);
        expect(ApiEnvelope.isEmptyResponse({'key': 'value'}), isFalse);
        expect(ApiEnvelope.isEmptyResponse('string'), isFalse);
      });
    });

    group('boolValue', () {
      test('converts boolean values', () {
        expect(ApiEnvelope.boolValue(true), isTrue);
        expect(ApiEnvelope.boolValue(false), isFalse);
      });

      test('converts numeric values', () {
        expect(ApiEnvelope.boolValue(1), isTrue);
        expect(ApiEnvelope.boolValue(0), isFalse);
        expect(ApiEnvelope.boolValue(2), isTrue);
      });

      test('converts string values', () {
        expect(ApiEnvelope.boolValue('true'), isTrue);
        expect(ApiEnvelope.boolValue('false'), isFalse);
        expect(ApiEnvelope.boolValue('1'), isTrue);
        expect(ApiEnvelope.boolValue('0'), isFalse);
        expect(ApiEnvelope.boolValue('yes'), isTrue);
        expect(ApiEnvelope.boolValue('no'), isFalse);
      });

      test('returns null for invalid values', () {
        expect(ApiEnvelope.boolValue(null), null);
        expect(ApiEnvelope.boolValue(''), null);
        expect(ApiEnvelope.boolValue('invalid'), null);
      });
    });

    group('text', () {
      test('converts to string', () {
        expect(ApiEnvelope.text('string'), 'string');
        expect(ApiEnvelope.text(42), '42');
        expect(ApiEnvelope.text(null), '');
      });
    });

    group('firstNonEmpty', () {
      test('returns first non-empty value', () {
        expect(ApiEnvelope.firstNonEmpty(['', 'first', 'second']), 'first');
      });

      test('returns fallback if all empty', () {
        expect(ApiEnvelope.firstNonEmpty(['', null, ''], fallback: 'fallback'), 'fallback');
      });
    });
  });
}