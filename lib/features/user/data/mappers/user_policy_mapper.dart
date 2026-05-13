import 'package:open_vts/features/user/domain/entities/user_policy.dart';

class UserPolicyMapper {
  const UserPolicyMapper();

  List<UserPolicy> fromResponse(Object? response) => UserPolicy.fromResponse(response);
}
