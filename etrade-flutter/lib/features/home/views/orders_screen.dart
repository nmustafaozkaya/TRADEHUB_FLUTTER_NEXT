import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../models/account_models.dart';
import 'orders_page.dart';
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({required this.controller, super.key});

  final HomeController controller;

  Color _statusColor(String? statusText, int? status) {
    final s = status ?? 0;
    if (s == 5) return const Color(0xFF34C759);
    if (s == 6) return const Color(0xFFFF3B30);
    final t = (statusText ?? '').toLowerCase();
    if (t.contains('complet') || t.contains('done')) return const Color(0xFF34C759);
    if (t.contains('reject') || t.contains('cancel')) return const Color(0xFFFF3B30);
    return const Color(0xFF007AFF);
  }

  String _statusLabel(String? statusText, int? status) {
    if (statusText != null && statusText.isNotEmpty) return statusText;
    const labels = {
      1: 'Placed',
      2: 'Preparing',
      3: 'Shipped',
      4: 'Delivered',
      5: 'Completed',
      6: 'Rejected',
    };
    return labels[status] ?? 'Processing';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'My Orders',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
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
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.black54,
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.ordersErrorMessage.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.ordersErrorMessage.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
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
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No orders yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your orders will appear here.',
                          style: TextStyle(fontSize: 13, color: Colors.black38),
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
                      statusColor: _statusColor(order.statusText, order.status),
                      statusLabel: _statusLabel(order.statusText, order.status),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.dateLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
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
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black26,
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