import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_profile_mapper.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_total_counts_mapper.dart';

void main() {
  test('profile mapper normalizes nested profile/company/address keys', () {
    const mapper = SuperadminProfileMapper();

    final profile = mapper.fromResponse(<String, Object?>{
      'data': <String, Object?>{
        'data': <String, Object?>{
          'user_id': 'sa-1',
          'full_name': 'Root User',
          'mail': 'root@example.com',
          'companies': <Object?>[<String, Object?>{'companyName': 'OpenVTS', 'customDomain': 'openvts.io'}],
          'address': <String, Object?>{'addressLine': 'Main Street', 'cityName': 'Delhi'},
        },
      },
    });

    expect(profile.id, 'sa-1');
    expect(profile.fullName, 'Root User');
    expect(profile.email, 'root@example.com');
    expect(profile.companyName, 'OpenVTS');
    expect(profile.website, 'openvts.io');
    expect(profile.addressLine, 'Main Street');
    expect(profile.city, 'Delhi');
  });

  test('total counts mapper normalizes count aliases and live status aliases', () {
    const mapper = SuperadminTotalCountsMapper();

    final counts = mapper.fromResponse(<String, Object?>{
      'data': <String, Object?>{
        'vehiclesCount': '10',
        'active_vehicles_count': 7,
        'users_count': '4',
        'licensedCredits': 20,
        'used_credits': '9',
        'vehicleLiveStatus': <String, Object?>{'online': 3, 'nodata': 2},
      },
    });

    expect(counts.totalVehicles, 10);
    expect(counts.activeVehicles, 7);
    expect(counts.totalUsers, 4);
    expect(counts.licensesIssued, 20);
    expect(counts.licensesUsed, 9);
    expect(counts.liveConnected, 3);
    expect(counts.liveNoData, 2);
  });
}
