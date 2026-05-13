class SuperadminVehicleDto {
  const SuperadminVehicleDto(this.json);
  final Map<String, Object?> json;
  factory SuperadminVehicleDto.fromJson(Map<String, Object?> json) => SuperadminVehicleDto(Map<String, Object?>.unmodifiable(json));
}

class SuperadminCommandOptionDto {
  const SuperadminCommandOptionDto(this.json);
  final Map<String, Object?> json;
  factory SuperadminCommandOptionDto.fromJson(Map<String, Object?> json) => SuperadminCommandOptionDto(Map<String, Object?>.unmodifiable(json));
}

class SuperadminSendCommandRequestDto {
  const SuperadminSendCommandRequestDto({
    required this.imei,
    required this.commandCode,
    required this.payload,
    required this.confirm,
  });

  final String imei;
  final String commandCode;
  final Map<String, Object?> payload;
  final bool confirm;

  Map<String, Object?> toJson() => <String, Object?>{
        'imei': imei,
        'command': commandCode,
        'payload': payload,
        'confirm': confirm,
      };
}
