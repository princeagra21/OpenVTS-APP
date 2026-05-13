import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/admin/data/mappers/admin_dashboard_summary_mapper.dart';

void main() {
  test('admin dashboard summary mapper normalizes totals, expiry, and live status aliases', () {
    const mapper = AdminDashboardSummaryMapper();

    final summary = mapper.fromResponse(<String, Object?>{
      'data': <String, Object?>{
        'totals': <String, Object?>{'vehicleCount': '12', 'usersCount': 5},
        'expiry': <String, Object?>{'thisMonth': 2, 'expiredCount': 1},
        'liveStatus': <String, Object?>{'running': 3, 'stopped': 4, 'noDevice': 2},
      },
    });

    expect(summary.totalVehicles, 12);
    expect(summary.totalUsers, 5);
    expect(summary.expiring30d, 2);
    expect(summary.expired, 1);
    expect(summary.running, 3);
    expect(summary.stop, 4);
    expect(summary.noData, 2);
  });
}
