class UserSettings {
  const UserSettings({
    this.theme = 'SYSTEM',
    this.languageCode = 'en',
    this.direction = 'LTR',
    this.units = 'KM',
  });

  final String theme;
  final String languageCode;
  final String direction;
  final String units;
}
