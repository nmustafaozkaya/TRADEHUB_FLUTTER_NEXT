import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/order_status.dart';
import '../../../theme/tradehub_theme.dart';
import '../controllers/home_controller.dart';
import '../models/account_models.dart';
import 'order_detail_page.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({required this.controller, super.key});

  final HomeController controller;

  Color _statusColor(int? status) {
    final s = status ?? OrderStatus.placed;
    if (s == OrderStatus.completed) return TradeHubColors.success;
    if (s == OrderStatus.rejected) return TradeHubColors.danger;
    if (s == OrderStatus.delivered) return TradeHubColors.accent;
    return TradeHubColors.primary;
  }

  String _statusLabel(UserOrderItem order) {
    return OrderStatus.displayLabel(status: order.status, statusText: order.statusText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeHubColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────
            Container(
              color: TradeHubColors.bg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: TradeHubColors.surface2,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: TradeHubColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'My Orders',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: TradeHubColors.textPrimary,
                      ),
                    ),
                  ),
                  // Refresh button
                  GestureDetector(
                    onTap: () async {
                      await controller.loadAccountModules();
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: TradeHubColors.surface2,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: TradeHubColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isOrdersLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: TradeHubColors.primary));
                }

                if (controller.ordersErrorMessage.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: TradeHubColors.textMuted.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.ordersErrorMessage.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: TradeHubColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: controller.loadAccountModules,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                if (controller.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: TradeHubColors.textMuted.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No orders yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: TradeHubColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your orders will appear here.',
                          style: TextStyle(fontSize: 13, color: TradeHubColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
                  itemCount: controller.orders.length,
                  itemBuilder: (context, index) {
                    final order = controller.orders[index];
                    return _OrderTile(
                      order: order,
                      controller: controller,
                      statusColor: _statusColor(order.status),
                      statusLabel: _statusLabel(order),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.controller,
    required this.statusColor,
    required this.statusLabel,
  });

  final UserOrderItem order;
  final HomeController controller;
  final Color statusColor;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => OrderDetailPage(orderId: order.id, controller: controller),
        transition: Transition.rightToLeft,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TradeHubColors.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            // Order icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_outlined,
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: TradeHubColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.dateLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TradeHubColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Price + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TRY ${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TradeHubColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right,
                  color: TradeHubColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}