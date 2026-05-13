/// Product entity used by UI and home business logic.
class ProductItem {
  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.discountLabel,
    required this.rating,
    this.totalReviews = 0,
    required this.category,
    this.imageUrl = '',
  });

  final int id;
  final String name;
  final double price;
  final double oldPrice;
  final String discountLabel;
  final double rating;
  final int totalReviews;
  final String category;
  final String imageUrl;

  /// Converts API payload to app model.
  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final price = (json['UNITPRICE'] as num?)?.toDouble() ?? 0;
    final id = (json['ID'] as num?)?.toInt() ?? 0;
    final name = (json['ITEMNAME'] ?? '').toString();
    final category = (json['CATEGORY1'] ?? 'Genel').toString();
    final avgRating = (json['AVG_RATING'] as num?)?.toDouble() ?? 0;
    final reviewCount = (json['TOTAL_REVIEWS'] as num?)?.toInt() ?? 0;
    return ProductItem(
      id: id,
      name: name,
      price: price,
      oldPrice: (price * 1.2).toDouble(),
      discountLabel: '%20 indirim',
      rating: avgRating,
      totalReviews: reviewCount,
      category: category,
      imageUrl: (json['IMAGE_URL'] ?? '').toString(),
    );
  }
}

/// Read-only review summary and recent comments for a product.
class ProductReviewBundle {
  ProductReviewBundle({
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
  });

  final double averageRating;
  final int totalReviews;
  final List<ProductReview> reviews;

  factory ProductReviewBundle.fromJson(Map<String, dynamic> json) {
    final list = (json['reviews'] as List<dynamic>? ?? const []);
    return ProductReviewBundle(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      reviews: list
          .map((x) => ProductReview.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }

  factory ProductReviewBundle.empty() =>
      ProductReviewBundle(averageRating: 0, totalReviews: 0, reviews: const []);
}

class ProductReview {
  ProductReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.reviewer,
  });

  final int id;
  final int rating;
  final String comment;
  final String createdAt;
  final String reviewer;

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: (json['id'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: (json['comment'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      reviewer: (json['reviewer'] ?? '').toString(),
    );
  }
}
