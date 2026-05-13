import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_admin_mapper.dart';

void main() {
  test('SuperadminAdminMapper maps admin list fallback keys', () {
    const mapper = SuperadminAdminMapper();
    final items = mapper.listFromResponse(_response(data: {
      'admins': [
        {'adminId': 'a1', 'fullName': 'Fleet Admin', 'companyName': 'OpenVTS', 'isActive': true},
      ],
    })).map(mapper.listItem).toList();

    expect(items, hasLength(1));
    expect(items.single.id, 'a1');
    expect(items.single.name, 'Fleet Admin');
    expect(items.single.company, 'OpenVTS');
    expect(items.single.isActive, isTrue);
  });
}

Map<String, Object?> _response({Object? data}) => <String, Object?>{
      'status': 'success',
      'data': <String, Object?>{'action': true, 'message': '', 'data': data},
    };
