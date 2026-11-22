class Product {
  final String? id;
  final String name;
  final String? description;
  final String price;
  final String? imagePath;
  final String? section;

  const Product({
    this.id,
    required this.name,
    required this.price,
    this.description,
    this.imagePath,
    this.section,
  });

  Product copyWith({
    String? id,
    String? name,
    String? price,
    String? description,
    String? imagePath,
    String? section,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      section: section ?? this.section,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawDesc = json['description'] as String?;
    String? section = json['section'] as String?;
    String? cleanDesc = rawDesc;

    if (section == null && rawDesc != null && rawDesc.startsWith('[SEC:') && rawDesc.contains(']')) {
      final endIdx = rawDesc.indexOf(']');
      section = rawDesc.substring(5, endIdx).trim();
      cleanDesc = rawDesc.substring(endIdx + 1).trim();
      if (cleanDesc.isEmpty) cleanDesc = null;
    }

    return Product(
      id: json['id']?.toString(),
      name: json['name'] as String? ?? '',
      price: json['price'] as String? ?? '',
      description: cleanDesc,
      imagePath: json['image_path'] as String? ?? json['imagePath'] as String?,
      section: section,
    );
  }

  Map<String, dynamic> toJson() {
    String? encodedDesc = description;
    if (section != null && section!.trim().isNotEmpty) {
      encodedDesc = '[SEC:${section!.trim()}] ${description ?? ''}'.trim();
    }
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'description': encodedDesc,
      'image_path': imagePath,
      if (section != null) 'section': section,
    };
  }
}
