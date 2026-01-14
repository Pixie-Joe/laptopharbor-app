// lib/models/product.dart
class Product {
  final int id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double originalPrice;
  final String discount;
  final List<String> specs;
  final String image;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.discount,
    required this.specs,
    required this.image,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      category: json['category'],
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? (json['price'] as num).toDouble(),
      discount: json['discount'] ?? '',
      specs: List<String>.from(json['specs'] ?? []),
      image: json['image'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
