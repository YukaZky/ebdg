class PaymentMethodModel {
  final int id;
  final String name;
  final String paymentType;
  final String? bankCode;
  final String iconUrl;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.paymentType,
    this.bankCode,
    required this.iconUrl,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      paymentType: json['payment_type'] ?? '',
      bankCode: json['bank_code'],
      iconUrl: json['icon_url'] ?? '',
    );
  }
}