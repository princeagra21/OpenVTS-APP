import 'package:open_vts/features/user/domain/entities/user_dashboard_usage.dart';
import 'package:open_vts/features/user/domain/entities/user_usage_last_7_days.dart';

class UserUsageMapper {
  const UserUsageMapper();

  UserUsageLast7Days last7DaysFromResponse(Object? response) => UserUsageLast7Days(response);
  UserDashboardUsage dashboardUsageFromResponse(Object? response) => UserDashboardUsage(response);
}
