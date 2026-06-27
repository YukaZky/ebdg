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

  static String _cleanString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _normalizePaymentType(dynamic value) {
    final raw = _cleanString(value).toLowerCase();

    if (raw == 'qriss' || raw == 'qris_static' || raw == 'qris_dynamic') {
      return 'qris';
    }

    return raw;
  }

  static String? _cleanBankCode(dynamic value) {
    final raw = _cleanString(value).toLowerCase();

    if (raw.isEmpty || raw == 'null') return null;

    if (raw.contains('bca')) return 'bca';
    if (raw.contains('bni')) return 'bni';
    if (raw.contains('bri')) return 'bri';
    if (raw.contains('permata')) return 'permata';

    return raw;
  }

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    final paymentType = _normalizePaymentType(json['payment_type']);

    return PaymentMethodModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: _cleanString(json['name']),
      paymentType: paymentType,
      bankCode: paymentType == 'bank_transfer'
          ? _cleanBankCode(json['bank_code'])
          : null,
      iconUrl: _cleanString(json['icon_url']),
    );
  }
}