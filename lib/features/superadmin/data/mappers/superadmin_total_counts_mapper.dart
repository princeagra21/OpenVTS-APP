import 'package:open_vts/features/superadmin/domain/entities/superadmin_total_counts.dart';

class SuperadminTotalCountsMapper {
  const SuperadminTotalCountsMapper();

  SuperadminTotalCounts fromResponse(Object? response) => SuperadminTotalCounts(response);
}
