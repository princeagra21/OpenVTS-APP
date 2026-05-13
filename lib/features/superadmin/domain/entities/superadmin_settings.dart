class SuperadminSettingsData {
  const SuperadminSettingsData({
    required this.language,
    required this.dateFormat,
    required this.use24Hour,
    required this.theme,
    required this.timezoneOffset,
    required this.units,
  });

  final String language;
  final String dateFormat;
  final bool? use24Hour;
  final String theme;
  final String timezoneOffset;
  final String units;
}

class SuperadminRole {
  const SuperadminRole({
    required this.key,
    required this.title,
    required this.currency,
    required this.amount,
    required this.permissions,
  });

  final String key;
  final String title;
  final String currency;
  final int amount;
  final Map<String, int> permissions;

  Object? operator [](String key) {
    return switch (key) {
      'key' => this.key,
      'title' => title,
      'currency' => currency,
      'amount' => amount,
      'permissions' => permissions,
      _ => null,
    };
  }
}

class SuperadminRoleMutationInput {
  const SuperadminRoleMutationInput({
    required this.key,
    required this.title,
    required this.currency,
    required this.amount,
    required this.permissions,
  });

  final String key;
  final String title;
  final String currency;
  final int amount;
  final Map<String, int> permissions;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': key,
        'title': title,
        'currency': currency,
        'amount': amount,
        'permissions': permissions,
      };
}
