class Product {
  final String? id;
  final String name;
  final String? description;
  final String price;
  final String? imagePath;

  const Product({
    this.id,
    required this.name,
    required this.price,
    this.description,
    this.imagePath,
  });

  Product copyWith({
    String? id,
    String? name,
    String? price,
    String? description,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString(),
      name: json['name'] as String? ?? '',
      price: json['price'] as String? ?? '',
      description: json['description'] as String?,
      imagePath: json['image_path'] as String? ?? json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'description': description,
      'image_path': imagePath,
    };
  }
}
