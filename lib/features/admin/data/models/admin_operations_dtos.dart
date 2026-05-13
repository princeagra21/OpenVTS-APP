class AdminSendNotificationRequestDto {
  const AdminSendNotificationRequestDto({
    required this.channel,
    required this.userIds,
    required this.message,
    this.subject,
  });

  final String channel;
  final List<String> userIds;
  final String message;
  final String? subject;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'channel': channel,
        'userIds': userIds,
        if (subject != null && subject!.trim().isNotEmpty) 'subject': subject,
        'message': message,
      };
}

class AdminCreatePaymentRequestDto {
  const AdminCreatePaymentRequestDto({
    required this.userId,
    required this.vehicleIds,
    required this.amount,
    required this.paymentMode,
  });

  final Object userId;
  final List<Object> vehicleIds;
  final String amount;
  final String paymentMode;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'vehicleIds': vehicleIds,
        'amount': amount,
        'paymentMode': paymentMode,
      };
}

class AdminCreatePricingPlanRequestDto {
  const AdminCreatePricingPlanRequestDto({
    required this.name,
    required this.durationDays,
    required this.price,
    required this.currency,
  });

  final String name;
  final int durationDays;
  final num price;
  final String currency;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'durationDays': durationDays,
        'price': price,
        'currency': currency,
      };
}


class AdminEmptyRequestDto {
  const AdminEmptyRequestDto();

  Map<String, dynamic> toJson() => const <String, dynamic>{};
}

class AdminOperationMapDto {
  const AdminOperationMapDto({required this.raw});

  final Map<String, Object?> raw;

  factory AdminOperationMapDto.fromJson(Map<String, dynamic> json) {
    return AdminOperationMapDto(raw: Map<String, Object?>.from(json));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{...raw};
}
