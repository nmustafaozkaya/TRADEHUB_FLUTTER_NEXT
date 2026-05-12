import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
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

  List<ProductItem> get _relatedProducts {
    final p = widget.product;
    return widget.allProducts
        .where(
          (x) =>
              x.id != p.id &&
              (x.category == p.category ||
                  x.name.toLowerCase().contains(
                        p.name.split(' ').first.toLowerCase(),
                      )),
        )
        .take(8)
        .toList();
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

                  // Related products
                  if (_relatedProducts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                      child: Text(
                        'Frequently bought together',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TradeHubColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: _relatedProducts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, index) {
                          final r = _relatedProducts[index];
                          return GestureDetector(
                            onTap: () => Get.off(
                              () => ProductDetailPage(
                                controller: widget.controller,
                                product: r,
                                allProducts: widget.allProducts,
                              ),
                              transition: Transition.rightToLeft,
                            ),
                            child: Container(
                              width: 120,
                              decoration: BoxDecoration(
                                color: TradeHubColors.surface2,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(14),
                                    ),
                                    child: Image.network(
                                      r.imageUrl,
                                      height: 80,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => Container(
                                        height: 80,
                                        color: TradeHubColors.panel,
                                        child: const Icon(
                                          Icons.image_outlined,
                                          color: TradeHubColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: TradeHubColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'TRY ${r.price.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: TradeHubColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

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
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  controller.addToCart(product.id, qty: qty);
                  if (protectionPrice != null) {
                    controller.setCartProtectionPlan(
                      product.id,
                      protectionPrice!,
                    );
                  }
                  controller.changeBottomTab(2);
                  Get.back();
                  Get.snackbar(
                    'Cart',
                    '$qty item(s) added',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: TradeHubColors.surface2,
                    colorText: TradeHubColors.textPrimary,
                    borderRadius: 12,
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TradeHubColors.accent,
                  foregroundColor: TradeHubColors.bg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Add to cart',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: TradeHubColors.textPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Buy now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}