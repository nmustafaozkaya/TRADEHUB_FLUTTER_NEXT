import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../data/product_api_service.dart';
import '../models/product_item.dart';
import 'checkout_page.dart';
import '../../../theme/tradehub_theme.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    required this.controller,
    required this.product,
    required this.allProducts,
    super.key,
  });

  final HomeController controller;
  final ProductItem product;
  final List<ProductItem> allProducts;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int qty = 1;
  double? _selectedProtectionPrice;
  final ProductApiService _productApiService = ProductApiService();
  ProductReviewBundle _reviewBundle = ProductReviewBundle.empty();
  final TextEditingController _reviewCommentController = TextEditingController();
  int _reviewRating = 5;
  bool _isSubmittingReview = false;

  bool get _hasProtection {
    final cat = widget.product.category.toLowerCase();
    final name = widget.product.name.toLowerCase();
    return cat.contains('electronic') ||
        cat.contains('elektronik') ||
        name.contains('tv') ||
        name.contains('battery') ||
        name.contains('phone') ||
        name.contains('laptop') ||
        name.contains('camera');
  }

  List<({String title, double price})> get _protectionPlans => [
        (title: '1-year plan', price: 60.0),
        (title: '2-year plan', price: 100.0),
        (title: '3-year plan', price: 140.0),
      ];

  /// Same-order style affinity (category / name token), aligned with web “bought together”.
  List<ProductItem> get _boughtTogether {
    final p = widget.product;
    final token = p.name.split(' ').first.toLowerCase();
    return widget.allProducts
        .where(
          (x) =>
              x.id != p.id &&
              (x.category == p.category ||
                  x.name.toLowerCase().contains(token)),
        )
        .take(10)
        .toList();
  }

  List<ProductItem> get _similarProducts {
    final p = widget.product;
    final token = p.name.split(' ').first.toLowerCase();
    final exclude = _boughtTogether.map((e) => e.id).toSet();
    return widget.allProducts
        .where((x) {
          if (x.id == p.id || exclude.contains(x.id)) return false;
          final sameBrandPrefix = x.name.toLowerCase().startsWith(token);
          final sameCat = x.category == p.category;
          return sameBrandPrefix || sameCat;
        })
        .take(10)
        .toList();
  }

  List<ProductItem> get _recommendedProducts {
    final p = widget.product;
    final exclude = {
      p.id,
      ..._boughtTogether.map((e) => e.id),
      ..._similarProducts.map((e) => e.id),
    };
    final rest =
        widget.allProducts.where((x) => !exclude.contains(x.id)).toList()
          ..sort((a, b) => b.totalReviews.compareTo(a.totalReviews));
    return rest.take(10).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final bundle = await _productApiService.fetchItemReviews(itemId: widget.product.id);
    if (!mounted) return;
    setState(() => _reviewBundle = bundle);
  }

  Future<void> _submitReview() async {
    if (_isSubmittingReview) {
      return;
    }
    final comment = _reviewCommentController.text.trim();
    if (comment.length < 3) {
      Get.snackbar('Review', 'Please write at least 3 characters.');
      return;
    }
    setState(() => _isSubmittingReview = true);
    try {
      int? userId;
      String? username;
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        final id = auth.userId.value;
        userId = id > 0 ? id : null;
        final login = auth.username.value.trim().isNotEmpty
            ? auth.username.value.trim()
            : auth.userEmail.value.trim();
        username = login.isEmpty ? null : login;
      }
      final ok = await _productApiService.submitItemReview(
        itemId: widget.product.id,
        rating: _reviewRating,
        comment: comment,
        userId: userId,
        username: username,
      );
      if (!mounted) {
        return;
      }
      if (!ok) {
        Get.snackbar(
          'Review',
          'Review failed. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      _reviewCommentController.clear();
      await _loadReviews();
      if (!mounted) {
        return;
      }
      Get.snackbar('Review', 'Your review has been submitted.');
    } finally {
      if (mounted) {
        setState(() => _isSubmittingReview = false);
      }
    }
  }

  @override
  void dispose() {
    _reviewCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final brand = p.name.split(' ').first.toUpperCase();
    final isFav = widget.controller.favoriteProductIds.contains(p.id);

    return Scaffold(
      backgroundColor: TradeHubColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(
              product: p,
              controller: widget.controller,
              isFav: isFav,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Product image card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: _ImageCard(product: p),
                  ),

                  // Name, price, qty card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: _InfoCard(
                      product: p,
                      brand: brand,
                      qty: qty,
                      controller: widget.controller,
                      onQtyChanged: (v) => setState(() => qty = v),
                    ),
                  ),

                  // Specs card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: _SpecsCard(product: p, brand: brand),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: _ReviewsCard(
                      bundle: _reviewBundle,
                      listAverage: p.rating,
                      listTotalReviews: p.totalReviews,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: _ReviewComposerCard(
                      rating: _reviewRating,
                      busy: _isSubmittingReview,
                      controller: _reviewCommentController,
                      onRatingChanged: (v) => setState(() => _reviewRating = v),
                      onSubmit: _submitReview,
                    ),
                  ),

                  // Protection plans
                  if (_hasProtection)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: _ProtectionCard(
                        plans: _protectionPlans,
                        selected: _selectedProtectionPrice,
                        onSelect: (price) =>
                            setState(() => _selectedProtectionPrice = price),
                      ),
                    ),

                  if (_boughtTogether.isNotEmpty)
                    _RelatedProductStrip(
                      title: 'Frequently bought together',
                      subtitle: 'Often paired in orders',
                      controller: widget.controller,
                      allProducts: widget.allProducts,
                      items: _boughtTogether,
                    ),
                  if (_similarProducts.isNotEmpty)
                    _RelatedProductStrip(
                      title: 'Similar products',
                      subtitle: 'Same brand or category',
                      controller: widget.controller,
                      allProducts: widget.allProducts,
                      items: _similarProducts,
                    ),
                  if (_recommendedProducts.isNotEmpty)
                    _RelatedProductStrip(
                      title: 'Recommended for you',
                      subtitle: 'Popular picks',
                      controller: widget.controller,
                      allProducts: widget.allProducts,
                      items: _recommendedProducts,
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Bottom action bar
            _BottomBar(
              product: p,
              qty: qty,
              controller: widget.controller,
              protectionPrice: _selectedProtectionPrice,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.product,
    required this.controller,
    required this.isFav,
  });

  final ProductItem product;
  final HomeController controller;
  final bool isFav;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TradeHubColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: TradeHubColors.bg,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: TradeHubColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Product',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TradeHubColors.textPrimary,
              ),
            ),
          ),
          Obx(() {
            final isFavorite =
                controller.favoriteProductIds.contains(product.id);
            return GestureDetector(
              onTap: () => controller.toggleFavorite(product.id),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: TradeHubColors.bg,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_outline,
                  size: 18,
                  color: isFavorite ? Colors.redAccent : TradeHubColors.textMuted,
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: TradeHubColors.bg,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.ios_share_outlined,
              size: 16,
              color: TradeHubColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.product});

  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: TradeHubColors.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: 240,
                errorBuilder: (_, _, _) => Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: TradeHubColors.textMuted,
                ),
              ),
            ),
          ),
          // Badges top left
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                _Badge(text: 'In stock', color: Colors.green.shade50, textColor: Colors.green.shade800),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.product,
    required this.brand,
    required this.qty,
    required this.controller,
    required this.onQtyChanged,
  });

  final ProductItem product;
  final String brand;
  final int qty;
  final HomeController controller;
  final ValueChanged<int> onQtyChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TradeHubColors.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand & category pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pill(text: brand, isBlue: true),
              _Pill(text: product.category),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: TradeHubColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Code: ${product.id} · Brand: $brand',
            style: const TextStyle(fontSize: 13, color: TradeHubColors.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TRY ${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: TradeHubColors.accent,
                ),
              ),
            ],
          ),
          if (product.rating > 0 || product.totalReviews > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _RatingStars(value: product.rating, size: 18),
                const SizedBox(width: 8),
                Text(
                  product.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TradeHubColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${product.totalReviews} reviews)',
                  style: const TextStyle(fontSize: 12, color: TradeHubColors.textMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Qty selector
              Container(
                decoration: BoxDecoration(
                  color: TradeHubColors.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: qty > 1 ? () => onQtyChanged(qty - 1) : null,
                      icon: const Icon(Icons.remove),
                      color: TradeHubColors.accent,
                      iconSize: 20,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$qty',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: TradeHubColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onQtyChanged(qty + 1),
                      icon: const Icon(Icons.add),
                      color: TradeHubColors.accent,
                      iconSize: 20,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ),
              ),
              // Stock indicator
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: TradeHubColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'In stock',
                    style: TextStyle(
                      fontSize: 12,
                      color: TradeHubColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.isBlue = false});

  final String text;
  final bool isBlue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isBlue
            ? TradeHubColors.primary.withValues(alpha: 0.22)
            : TradeHubColors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isBlue ? TradeHubColors.primary : TradeHubColors.textMuted,
        ),
      ),
    );
  }
}

class _SpecsCard extends StatelessWidget {
  const _SpecsCard({required this.product, required this.brand});

  final ProductItem product;
  final String brand;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Code', product.id.toString()),
      ('Brand', brand),
      ('Category', product.category),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TradeHubColors.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TradeHubColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: TradeHubColors.panel,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: rows.map((row) {
                final isLast = row == rows.last;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            row.$1,
                            style: const TextStyle(
                              fontSize: 13,
                              color: TradeHubColors.textMuted,
                            ),
                          ),
                          Text(
                            row.$2,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TradeHubColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(height: 0, thickness: 0.5, color: Colors.white.withValues(alpha: 0.08)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatefulWidget {
  const _ReviewsCard({
    required this.bundle,
    required this.listAverage,
    required this.listTotalReviews,
  });

  final ProductReviewBundle bundle;
  final double listAverage;
  final int listTotalReviews;

  @override
  State<_ReviewsCard> createState() => _ReviewsCardState();
}

class _ReviewsCardState extends State<_ReviewsCard> {
  static const int _perPage = 5;
  int _page = 0;

  @override
  void didUpdateWidget(covariant _ReviewsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bundle.reviews.length != widget.bundle.reviews.length) {
      _page = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = widget.bundle;
    final hasFetched = bundle.reviews.isNotEmpty;
    final avg = (hasFetched ? bundle.averageRating : widget.listAverage)
        .clamp(0, 5)
        .toDouble();
    final totalCount =
        hasFetched ? bundle.totalReviews : widget.listTotalReviews;

    final reviews = bundle.reviews;
    final totalPages = reviews.isEmpty
        ? 1
        : ((reviews.length + _perPage - 1) ~/ _perPage);
    final safePage = _page.clamp(0, totalPages - 1);
    final start = safePage * _perPage;
    final pageItems = reviews.skip(start).take(_perPage).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TradeHubColors.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reviews',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TradeHubColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _RatingStars(value: avg),
              const SizedBox(width: 8),
              Text(
                '${avg.toStringAsFixed(1)} / 5',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TradeHubColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($totalCount total)',
                style: const TextStyle(fontSize: 12, color: TradeHubColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            const Text(
              'No reviews yet.',
              style: TextStyle(fontSize: 12, color: TradeHubColors.textMuted),
            )
          else ...[
            ...pageItems.map((r) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TradeHubColors.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.reviewer.isEmpty ? 'an*** us***' : r.reviewer,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TradeHubColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _RatingStars(value: r.rating.toDouble(), size: 14),
                    const SizedBox(height: 6),
                    Text(
                      r.comment.isEmpty ? 'No comment.' : r.comment,
                      style: const TextStyle(fontSize: 12, color: TradeHubColors.textPrimary),
                    ),
                  ],
                ),
              );
            }),
            if (totalPages > 1) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(totalPages, (i) {
                  final n = i + 1;
                  final selected = i == safePage;
                  return InkWell(
                    onTap: () => setState(() => _page = i),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: selected
                            ? TradeHubColors.accent.withValues(alpha: 0.25)
                            : TradeHubColors.panel,
                        border: Border.all(
                          color: selected
                              ? TradeHubColors.accent
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        '$n',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? TradeHubColors.accent
                              : TradeHubColors.textMuted,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReviewComposerCard extends StatelessWidget {
  const _ReviewComposerCard({
    required this.rating,
    required this.busy,
    required this.controller,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final int rating;
  final bool busy;
  final TextEditingController controller;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TradeHubColors.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write a review',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TradeHubColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            children: List.generate(5, (idx) {
              final v = idx + 1;
              final selected = v <= rating;
              return IconButton(
                onPressed: busy ? null : () => onRatingChanged(v),
                icon: Icon(
                  selected ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFACC15),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: TradeHubColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Share your experience...',
              hintStyle: const TextStyle(color: TradeHubColors.textMuted),
              filled: true,
              fillColor: TradeHubColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton(
              onPressed: busy ? null : onSubmit,
              child: Text(busy ? 'Sending...' : 'Submit review'),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Only users with successful purchases can post reviews.',
            style: TextStyle(fontSize: 11, color: TradeHubColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.value, this.size = 16});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final safe = value.clamp(0, 5).toDouble();
    return SizedBox(
      width: size * 5,
      height: size,
      child: Stack(
        children: [
          Row(
            children: List.generate(
              5,
              (_) => Icon(Icons.star_border_rounded, size: size, color: TradeHubColors.textMuted),
            ),
          ),
          ClipRect(
            clipper: _FractionalClipper(safe / 5),
            child: Row(
              children: List.generate(
                5,
                (_) => Icon(Icons.star_rounded, size: size, color: const Color(0xFFFACC15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FractionalClipper extends CustomClipper<Rect> {
  _FractionalClipper(this.fraction);
  final double fraction;

  @override
  Rect getClip(Size size) {
    final w = size.width * fraction.clamp(0, 1);
    return Rect.fromLTWH(0, 0, w, size.height);
  }

  @override
  bool shouldReclip(covariant _FractionalClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
}

class _ProtectionCard extends StatelessWidget {
  const _ProtectionCard({
    required this.plans,
    required this.selected,
    required this.onSelect,
  });

  final List<({String title, double price})> plans;
  final double? selected;
  final ValueChanged<double?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TradeHubColors.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TradeHub Protection',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TradeHubColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Extended warranty plans for this item',
            style: TextStyle(fontSize: 12, color: TradeHubColors.textMuted),
          ),
          const SizedBox(height: 12),
          ...plans.map((plan) {
            final isSelected = selected == plan.price;
            return GestureDetector(
              onTap: () => onSelect(isSelected ? null : plan.price),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? TradeHubColors.accent
                        : const Color(0x33FFFFFF),
                    width: isSelected ? 1.5 : 1,
                  ),
                  color: isSelected
                      ? const Color(0x26818CF8)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TradeHubColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Coverage for accidental damage',
                            style: TextStyle(
                              fontSize: 11,
                              color: TradeHubColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+TRY ${plan.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TradeHubColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? TradeHubColors.accent
                          : TradeHubColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RelatedProductStrip extends StatelessWidget {
  const _RelatedProductStrip({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.allProducts,
    required this.items,
  });

  final String title;
  final String subtitle;
  final HomeController controller;
  final List<ProductItem> allProducts;
  final List<ProductItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: TradeHubColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: TradeHubColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 272,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, index) => _DetailRelatedCard(
              product: items[index],
              controller: controller,
              allProducts: allProducts,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRelatedCard extends StatelessWidget {
  const _DetailRelatedCard({
    required this.product,
    required this.controller,
    required this.allProducts,
  });

  final ProductItem product;
  final HomeController controller;
  final List<ProductItem> allProducts;

  @override
  Widget build(BuildContext context) {
    final subtitle = product.category.isNotEmpty
        ? '${product.category} • Fresh and fast delivery'
        : 'Fresh and fast delivery';
    return SizedBox(
      width: 172,
      height: 260,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.off(
            () => ProductDetailPage(
              controller: controller,
              product: product,
              allProducts: allProducts,
            ),
            transition: Transition.rightToLeft,
          ),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: TradeHubColors.surface2,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 104,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 36,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Obx(() {
                              final isFavorite =
                                  controller.favoriteProductIds.contains(product.id);
                              return GestureDetector(
                                onTap: () => controller.toggleFavorite(product.id),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 16,
                                    color: isFavorite
                                        ? Colors.redAccent
                                        : const Color(0xFF4B5563),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: TradeHubColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: TradeHubColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.totalReviews})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: TradeHubColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: TradeHubColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'TRY ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: TradeHubColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            controller.addToCart(product.id);
                            Get.snackbar(
                              'Cart',
                              'Item added to cart.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: TradeHubColors.surface2,
                              colorText: TradeHubColors.textPrimary,
                              borderRadius: 12,
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 2),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Order Now',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.product,
    required this.qty,
    required this.controller,
    this.protectionPrice,
  });

  final ProductItem product;
  final int qty;
  final HomeController controller;
  final double? protectionPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: TradeHubColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: () {
            controller.addToCart(product.id, qty: qty);
            if (protectionPrice != null) {
              controller.setCartProtectionPlan(
                product.id,
                protectionPrice!,
              );
            }
            Get.to(
              () => CheckoutPage(controller: controller),
              transition: Transition.rightToLeft,
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: TradeHubColors.accent,
            foregroundColor: TradeHubColors.bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Order Now',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}