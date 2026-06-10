// Tambahkan class ProductVariation di atas
class ProductVariation {
  final int id;
  final String name;
  final String? image;

  ProductVariation({
    required this.id, 
    required this.name, 
    this.image
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      id: json['id'],
      name: json['name'],
      image: json['image'],
    );
  }
}

class Product {
  final int id;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? description;
  final double price;
  final double? salePrice;
  final String SKU;
  final String stockStatus;
  final int quantity;
  final String? image;
  // --- TAMBAHAN UNTUK VARIASI ---
  final List<ProductVariation>? variations; 

  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.description,
    required this.price,
    this.salePrice,
    required this.SKU,
    required this.stockStatus,
    required this.quantity,
    this.image,
    this.variations, // --- TAMBAHAN UNTUK VARIASI ---
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      shortDescription: json['short_description'],
      description: json['description'],
      price: double.parse(json['regular_price'].toString()),
      salePrice: json['sale_price'] != null ? double.parse(json['sale_price'].toString()) : null,
      SKU: json['SKU'] ?? '',
      stockStatus: json['stock_status'] ?? 'instock',
      quantity: json['quantity'] ?? 0,
      image: json['image'],
      // --- PARSING DATA VARIASI DARI API ---
      variations: json['variations'] != null 
          ? (json['variations'] as List).map((i) => ProductVariation.fromJson(i)).toList() 
          : [],
    );
  }
}