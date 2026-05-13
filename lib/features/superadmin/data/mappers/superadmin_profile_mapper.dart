import 'package:open_vts/features/superadmin/domain/entities/superadmin_profile.dart';

class SuperadminProfileMapper {
  const SuperadminProfileMapper();

  SuperadminProfile fromResponse(Object? response) => SuperadminProfile(response);
}
