class ProductRow {
  const ProductRow({
    required this.name,
    required this.price,
    required this.description,
    required this.phone,
  });

  final String name;
  final String price;
  final String description;
  final String phone;

  Map<String, Object?> toJson() => {
    'name': name,
    'price': price,
    'description': description,
    'phone': phone,
  };

  factory ProductRow.fromJson(Map<String, Object?> json) {
    return ProductRow(
      name: json['name'] as String? ?? '',
      price: json['price'] as String? ?? '',
      description: json['description'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}
