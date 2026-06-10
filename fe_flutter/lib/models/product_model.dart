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
    this.image
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      id: json['id'],
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
    this.variations,
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
      variations: json['variations'] != null 
          ? (json['variations'] as List).map((i) => ProductVariation.fromJson(i)).toList() 
          : [],
    );
  }
}