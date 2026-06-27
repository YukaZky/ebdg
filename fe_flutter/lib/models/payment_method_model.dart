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

  static String _normalizePaymentType(dynamic value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    if (raw == 'qriss' || raw == 'qris_static' || raw == 'qris_dynamic') return 'qris';
    return raw;
  }

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      paymentType: _normalizePaymentType(json['payment_type']),
      bankCode: json['bank_code'],
      iconUrl: json['icon_url'] ?? '',
    );
  }
}
