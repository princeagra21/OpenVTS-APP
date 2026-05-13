import 'package:open_vts/features/admin/data/models/admin_dashboard_response.dart';
import 'package:open_vts/features/admin/domain/entities/admin_dashboard.dart';

class AdminDashboardMapper {
  const AdminDashboardMapper();

  AdminDashboard toDomain(AdminDashboardResponse response) {
    return AdminDashboard(metrics: _normalize(response.data));
  }

  Map<String, Object?> _normalize(Map<String, dynamic> source) {
    final nested = source['data'];
    if (nested is Map) return Map<String, Object?>.from(nested.cast());
    return Map<String, Object?>.from(source);
  }
}
