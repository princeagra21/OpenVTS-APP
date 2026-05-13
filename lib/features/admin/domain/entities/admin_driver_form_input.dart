class CreateAdminDriverInput {
  const CreateAdminDriverInput({
    required this.primaryUserId,
    required this.name,
    required this.email,
    required this.username,
    required this.password,
    required this.mobilePrefix,
    required this.mobile,
    required this.countryCode,
    required this.stateCode,
    required this.city,
    required this.address,
    required this.pincode,
  });

  final String primaryUserId;
  final String name;
  final String email;
  final String username;
  final String password;
  final String mobilePrefix;
  final String mobile;
  final String countryCode;
  final String stateCode;
  final String city;
  final String address;
  final String pincode;

  Map<String, Object?> toPayload() => <String, Object?>{
        'primaryUserId': primaryUserId,
        'name': name,
        'email': email,
        'username': username,
        'password': password,
        'mobilePrefix': mobilePrefix,
        'mobile': mobile,
        'countryCode': countryCode,
        'stateCode': stateCode,
        'city': city,
        'address': address,
        'pincode': pincode,
      }..removeWhere((_, value) => value == null || (value is String && value.trim().isEmpty));
}
