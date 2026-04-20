/// Product entity used by UI and home business logic.
class ProductItem {
  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.discountLabel,
    required this.rating,
    required this.category,
    this.imageUrl = '',
  });

  final int id;
  final String name;
  final double price;
  final double oldPrice;
  final String discountLabel;
  final double rating;
  final String category;
  final String imageUrl;

  /// Converts API payload to app model.
  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final price = (json['UNITPRICE'] as num?)?.toDouble() ?? 0;
    final id = (json['ID'] as num?)?.toInt() ?? 0;
    final name = (json['ITEMNAME'] ?? '').toString();
    final category = (json['CATEGORY1'] ?? 'Genel').toString();
    return ProductItem(
      id: id,
      name: name,
      price: price,
      oldPrice: (price * 1.2).toDouble(),
      discountLabel: '%20 indirim',
      rating: 4.5,
      category: category,
      imageUrl: (json['IMAGE_URL'] ?? '').toString(),
    );
  }
}
