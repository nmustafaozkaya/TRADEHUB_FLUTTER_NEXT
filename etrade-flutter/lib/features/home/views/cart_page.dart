import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../models/product_item.dart';
import 'checkout_page.dart';
import '../../../theme/tradehub_theme.dart';
import 'home_shared_widgets.dart';

class CartPage extends StatelessWidget {
  const CartPage({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final cartEntries = controller.cartQuantities.entries.toList();
        final cartItems = cartEntries
            .map((entry) {
              ProductItem? product;
              for (final p in controller.products) {
                if (p.id == entry.key) {
                  product = p;
                  break;
                }
              }
              return (product: product, qty: entry.value);
            })
            .where((e) => e.product != null)
            .toList();
        final total = cartItems.fold<double>(
          0,
          (sum, item) => sum + (item.product!.price * item.qty),
        );
        final protectionTotal = cartItems.fold<double>(
          0,
          (sum, item) => sum + controller.getCartProtection(item.product!.id),
        );
        const shippingThreshold = 300.0;
        final shipping = total >= shippingThreshold ? 0.0 : 30.0;
        const discount = 0.0;
        final grandTotal = total + protectionTotal + shipping - discount;

        return ListView(
          children: [
            const Text(
              'Cart',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: TradeHubColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${cartItems.length} items',
              style: const TextStyle(color: TradeHubColors.textMuted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => controller.changeBottomTab(0),
                  icon: const Icon(Icons.storefront, size: 18),
                  label: const Text('Continue shopping'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: controller.clearCart,
                  child: const Text('Clear cart'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (cartItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TradeHubColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Text(
                  'Your cart is empty for now. Add products from item details.',
                  style: TextStyle(color: TradeHubColors.textMuted),
                ),
              ),
            ...cartItems.map((row) {
              final p = row.product!;
              final qty = row.qty;
              final lineTotal = p.price * qty;
              final lowerCategory = p.category.toLowerCase();
              final lowerName = p.name.toLowerCase();
              final hasProtection =
                  lowerCategory.contains('electronic') ||
                  lowerCategory.contains('elektronik') ||
                  lowerName.contains('tv') ||
                  lowerName.contains('battery') ||
                  lowerName.contains('phone') ||
                  lowerName.contains('laptop');
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TradeHubColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: TradeHubColors.panel,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.network(
                            p.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.image_outlined,
                              color: TradeHubColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: TradeHubColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'TRY ${p.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: TradeHubColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '•  Line: TRY ${lineTotal.toStringAsFixed(2)}',
                                style: const TextStyle(color: TradeHubColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => controller.decreaseCartItem(p.id),
                          icon: const Icon(Icons.remove),
                        ),
                        Text(
                          '$qty',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: TradeHubColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => controller.addToCart(p.id),
                          icon: const Icon(Icons.add),
                        ),
                        TextButton(
                          onPressed: () => controller.removeFromCart(p.id),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                    if (hasProtection) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'TradeHub Protection',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: TradeHubColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Home essentials protection (UI preview).',
                        style: TextStyle(color: TradeHubColors.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      ...[
                        (title: '1-year plan', price: 60.0),
                        (title: '2-year plan', price: 100.0),
                        (title: '3-year plan', price: 140.0),
                      ].map(
                        (plan) => Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.title,
                                    style: const TextStyle(color: TradeHubColors.textPrimary),
                                  ),
                                  const Text(
                                    'Protection plan preview for this item.',
                                    style: TextStyle(
                                      color: TradeHubColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'TRY ${plan.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: TradeHubColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () => controller.setCartProtectionPlan(
                                p.id,
                                plan.price,
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            if (cartItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TradeHubColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: TradeHubColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SummaryRow(label: 'Subtotal', value: total),
                    SummaryRow(label: 'Protection', value: protectionTotal),
                    SummaryRow(
                      label: 'Shipping',
                      value: shipping,
                      note: shipping == 0
                          ? '(free over TRY ${shippingThreshold.toStringAsFixed(2)})'
                          : null,
                    ),
                    SummaryRow(label: 'Discount', value: discount),
                    const Divider(),
                    SummaryRow(
                      label: 'Total',
                      value: grandTotal,
                      isBold: true,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Get.to(
                          () => CheckoutPage(controller: controller),
                          transition: Transition.rightToLeft,
                        ),
                        child: const Text('Checkout'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Checkout will create an order record in the database (MVP).',
                      style: TextStyle(color: TradeHubColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}