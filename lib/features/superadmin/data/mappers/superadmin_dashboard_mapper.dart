import 'package:open_vts/features/superadmin/data/models/superadmin_admins_response.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_dashboard.dart';

class SuperadminDashboardMapper {
  const SuperadminDashboardMapper();

  SuperadminDashboard toDomain(SuperadminDashboardResponse response) {
    return SuperadminDashboard(metrics: _normalize(response.data));
  }

  Map<String, Object?> _normalize(Map<String, dynamic> source) {
    final nested = source['data'];
    if (nested is Map) return Map<String, Object?>.from(nested.cast());
    return Map<String, Object?>.from(source);
  }
}
