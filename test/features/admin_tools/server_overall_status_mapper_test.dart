import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/admin_tools/data/mappers/server_overall_status_mapper.dart';

void main() {
  test('server overall status mapper normalizes nested system metrics', () {
    const mapper = ServerOverallStatusMapper();

    final status = mapper.fromResponse(<String, Object?>{
      'data': <String, Object?>{
        'system': <String, Object?>{
          'uptime_s': 3661,
          'serverTime': '2026-05-10T10:00:00Z',
          'cpu': <String, Object?>{'usagePct': '12.5', 'load5': '0.4'},
          'memory': <String, Object?>{'total': 100, 'used': 25},
          'disk': <Object?>[<String, Object?>{'total': 200, 'used': 100}],
        },
      },
    });

    expect(status.isUp, isTrue);
    expect(status.uptimeSeconds, 3661);
    expect(status.uptimeText, '1h 1m');
    expect(status.cpuPercent, 12.5);
    expect(status.memPercent, 25);
    expect(status.diskPercent, 50);
    expect(status.loadAvg5, 0.4);
  });
}
