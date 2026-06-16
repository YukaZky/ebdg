class ProductVariation {
  final int id;
  final String name;
  final String? description;
  final double regularPrice;
  final double? salePrice;
  final int weight;
  final int quantity;
  final String? image;

  ProductVariation({
    required this.id,
    required this.name,
    this.description,
    required this.regularPrice,
    this.salePrice,
    required this.weight,
    required this.quantity,
    this.image,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      regularPrice: json['regular_price'] != null ? double.tryParse(json['regular_price'].toString()) ?? 0.0 : 0.0,
      salePrice: json['sale_price'] != null ? double.tryParse(json['sale_price'].toString()) : null,
      weight: json['weight'] != null ? int.tryParse(json['weight'].toString()) ?? 0 : 0,
      quantity: json['quantity'] != null ? int.tryParse(json['quantity'].toString()) ?? 0 : 0,
      image: json['image'],
    );
  }
}

class Product {
  final int id;
  final int? userId;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? description;
  final double price;
  final double? salePrice;
  final String SKU;
  final String stockStatus;
  final int quantity;
  final int weight;
  final String? image;
  final int? categoryId;
  final String? categoryName;
  final Map<String, dynamic>? store;
  final List<dynamic> galleryImages;
  final List<ProductVariation>? variations;

  Product({
    required this.id,
    this.userId,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.description,
    required this.price,
    this.salePrice,
    required this.SKU,
    required this.stockStatus,
    required this.quantity,
    required this.weight,
    this.image,
    this.categoryId,
    this.categoryName,
    this.store,
    this.galleryImages = const [],
    this.variations,
  });

  static List<dynamic> _parseGalleryImages(Map<String, dynamic> json) {
    if (json['images'] is List) return List<dynamic>.from(json['images']);
    if (json['product_images'] is List) return List<dynamic>.from(json['product_images']);
    return [];
  }

  static String? _firstGalleryImage(List<dynamic> galleryImages) {
    if (galleryImages.isEmpty) return null;
    final first = galleryImages.first;
    if (first is Map && first['image'] != null && first['image'].toString().trim().isNotEmpty) return first['image'].toString();
    if (first != null && first.toString().trim().isNotEmpty) return first.toString();
    return null;
  }

  static String? _coverImage(Map<String, dynamic> json, List<dynamic> galleryImages) {
    final mainImage = json['image']?.toString().trim();
    if (mainImage != null && mainImage.isNotEmpty && mainImage != 'null') return mainImage;
    return _firstGalleryImage(galleryImages);
  }

  static Map<String, dynamic>? _parseMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final galleryImages = _parseGalleryImages(json);
    final category = _parseMap(json['category']);

    return Product(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      shortDescription: json['short_description'],
      description: json['description'],
      price: double.tryParse(json['regular_price'].toString()) ?? 0.0,
      salePrice: json['sale_price'] != null ? double.tryParse(json['sale_price'].toString()) : null,
      SKU: json['SKU'] ?? '',
      stockStatus: json['stock_status'] ?? 'instock',
      quantity: json['quantity'] != null ? int.tryParse(json['quantity'].toString()) ?? 0 : 0,
      weight: json['weight'] != null ? int.tryParse(json['weight'].toString()) ?? 0 : 0,
      image: _coverImage(json, galleryImages),
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      categoryName: category?['name']?.toString(),
      store: _parseMap(json['store']),
      galleryImages: galleryImages,
      variations: json['variations'] != null
          ? (json['variations'] as List).map((i) => ProductVariation.fromJson(Map<String, dynamic>.from(i))).toList()
          : [],
    );
  }
}
