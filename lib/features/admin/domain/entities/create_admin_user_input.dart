import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';

class CreateAdminUserInput {
  const CreateAdminUserInput({
    required this.name,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.username,
    required this.password,
    required this.companyName,
    required this.address,
    required this.countryCode,
    required this.stateCode,
    required this.city,
    required this.pincode,
  });

  final String name;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String username;
  final String password;
  final String companyName;
  final String address;
  final String countryCode;
  final String stateCode;
  final String city;
  final String pincode;

  Result<CreateAdminUserInput, AppError> validate() {
    if (name.trim().isEmpty) {
      return const Result.failure(ValidationError('Full name is required'));
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) {
      return const Result.failure(ValidationError('Please enter a valid email address'));
    }
    if (username.trim().isEmpty) {
      return const Result.failure(ValidationError('Username is required'));
    }
    if (password.trim().length < 6) {
      return const Result.failure(ValidationError('Password must be at least 6 characters'));
    }
    if (mobilePrefix.trim().isEmpty || mobileNumber.trim().isEmpty) {
      return const Result.failure(ValidationError('Mobile number is required'));
    }
    return Result.success(this);
  }
}
