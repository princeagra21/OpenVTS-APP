import 'package:open_vts/features/user/data/models/user_dashboard_response.dart';
import 'package:open_vts/features/user/domain/entities/user_dashboard.dart';

class UserDashboardMapper {
  const UserDashboardMapper();

  UserDashboard toDomain(UserDashboardResponse response) {
    return UserDashboard(metrics: _normalize(response.data));
  }

  Map<String, Object?> _normalize(Map<String, dynamic> source) {
    final nested = source['data'];
    if (nested is Map) return Map<String, Object?>.from(nested.cast());
    return Map<String, Object?>.from(source);
  }
}
