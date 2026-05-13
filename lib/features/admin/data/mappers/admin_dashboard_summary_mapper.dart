import 'package:open_vts/features/admin/domain/entities/admin_dashboard_summary.dart';

class AdminDashboardSummaryMapper {
  const AdminDashboardSummaryMapper();

  AdminDashboardSummary fromResponse(Object? response) => AdminDashboardSummary(response);
}
