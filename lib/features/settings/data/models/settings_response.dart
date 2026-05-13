class SettingsResponse {
  const SettingsResponse({required this.data});
  final Map<String, dynamic> data;
  factory SettingsResponse.fromJson(Map<String, dynamic> json) => SettingsResponse(data: json);
  Map<String, dynamic> toJson() => data;
}
