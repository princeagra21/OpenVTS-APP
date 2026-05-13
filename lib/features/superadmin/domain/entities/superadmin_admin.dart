class SuperadminAdminListItem {
  SuperadminAdminListItem({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.company,
    required this.status,
    required this.isActive,
    required this.vehiclesCount,
    required this.credits,
    required this.role,
    required this.location,
    required this.recentLogin,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String company;
  final String status;
  bool isActive;
  final int vehiclesCount;
  final int credits;
  final String role;
  final String location;
  final String recentLogin;
  final String createdAt;

  Object? operator [](String key) {
    return switch (key) {
      'id' => id,
      'initials' => initials,
      'name' => name,
      'phone' => phone,
      'username' => displayUsername,
      'email' => email,
      'company' => company,
      'status' => displayStatus,
      'vehicles' => vehiclesCount == 0 ? '' : vehiclesCount.toString(),
      'credits' => credits == 0 ? '' : credits.toString(),
      'recentLogin' => formattedRecentLogin,
      'active' => isActive,
      'location' => location,
      'joined' => createdAt,
      'role' => role,
      _ => null,
    };
  }

  void operator []=(String key, Object? value) {
    if (key == 'active') {
      isActive = _bool(value);
    }
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final out = parts.where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();
    return out.isEmpty ? '—' : out.toUpperCase();
  }

  String get displayUsername {
    if (username.trim().isEmpty) return '—';
    return username.startsWith('@') ? username : '@$username';
  }

  String get displayStatus {
    final text = status.trim().toLowerCase();
    if (text.isEmpty) return isActive ? 'Active' : 'Disabled';
    if (text == 'true' || text == '1') return 'Active';
    if (text == 'false' || text == '0' || text == 'inactive') return 'Disabled';
    if (text == 'verified') return 'Verified';
    if (text == 'pending') return 'Pending';
    return status;
  }

  String get formattedRecentLogin {
    final raw = recentLogin.trim();
    if (raw.isEmpty || raw == '-') return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final local = parsed.toLocal();
    return '${local.year}, ${months[local.month - 1]} ${local.day}';
  }

  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'active' || text == 'verified';
  }
}

class SuperadminAdminDetail {
  const SuperadminAdminDetail({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.companyName,
    required this.website,
    required this.isActive,
    required this.isVerified,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String companyName;
  final String website;
  final bool isActive;
  final bool isVerified;
  final String addressLine;
  final String city;
  final String state;
  final String country;
  final String postalCode;
}

class SuperadminAdminMutationInput {
  const SuperadminAdminMutationInput(this.fields);
  final Map<String, Object?> fields;
}
