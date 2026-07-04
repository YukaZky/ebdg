class AppPopupModel {
  final int id;
  final String? title;
  final String? subtitle;
  final String imageUrl;
  final String buttonText;
  final String? targetUrl;

  const AppPopupModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.buttonText = 'Belanja Sekarang',
    this.targetUrl,
  });

  factory AppPopupModel.fromJson(Map<String, dynamic> json) {
    return AppPopupModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: _clean(json['title']),
      subtitle: _clean(json['subtitle']),
      imageUrl: _clean(json['image_url']) ?? '',
      buttonText: _clean(json['button_text']) ?? 'Belanja Sekarang',
      targetUrl: _clean(json['target_url']),
    );
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return null;
    return text;
  }

  bool get isValid => id > 0 && imageUrl.isNotEmpty;
}
