import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/user/data/mappers/user_notification_mapper.dart';
import 'package:open_vts/features/user/data/mappers/user_policy_mapper.dart';
import 'package:open_vts/features/user/data/mappers/user_usage_mapper.dart';

void main() {
  test('notification mapper normalizes channel, vehicle, basic, and overspeed keys', () {
    const mapper = UserNotificationMapper();
    final dto = mapper.preferencesFromResponse(<String, Object?>{
      'data': <String, Object?>{
        'preferences': <String, Object?>{
          'channels': <String, Object?>{
            'overspeed': <String, Object?>{'notifyEmail': 1, 'notifyMobilePush': 'true'},
          },
          'vehicles': <Object?>[<String, Object?>{'vehicleId': 'v1', 'plate': 'DL01'}],
          'overspeed': <Object?>[<String, Object?>{'vehicleId': 'v1', 'speedLimit': '80', 'enabled': 'on'}],
        },
      },
    });

    final prefs = mapper.toPreferences(dto);
    expect(prefs.items.single.eventType, 'OVERSPEED');
    expect(prefs.items.single.notifyEmail, isTrue);
    expect(prefs.items.single.notifyMobilePush, isTrue);
    expect(prefs.vehicles.single.plateNumber, 'DL01');
    expect(prefs.overspeedRules.single.speedLimitKph, 80);
  });

  test('policy mapper handles dictionary policy responses', () {
    const mapper = UserPolicyMapper();

    final policies = mapper.fromResponse(<String, Object?>{
      'data': <String, Object?>{
        'PRIVACY_POLICY': 'Privacy text',
        'TERMS': <String, Object?>{'PolicyText': 'Terms text', 'title': 'Terms'},
      },
    });

    expect(policies.map((e) => e.policyType), containsAll(<String>['PRIVACY_POLICY', 'TERMS']));
    expect(policies.firstWhere((e) => e.policyType == 'PRIVACY_POLICY').policyText, 'Privacy text');
  });

  test('usage mapper normalizes nested points and totals', () {
    const mapper = UserUsageMapper();

    final usage = mapper.last7DaysFromResponse(<String, Object?>{
      'data': <String, Object?>{
        'data': <String, Object?>{
          'totals': <String, Object?>{'distanceKm': '101.5', 'hours': 9},
          'points': <Object?>[<String, Object?>{'date': 'Mon', 'distanceKm': 10}],
        },
      },
    });

    expect(usage.totalDrivenKm, 101.5);
    expect(usage.totalEngineHours, 9);
    expect(usage.daysTracked, 1);
  });
}
