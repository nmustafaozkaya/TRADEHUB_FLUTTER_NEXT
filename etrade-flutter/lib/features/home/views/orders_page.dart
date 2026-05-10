import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../models/account_models.dart';
import 'home_shared_widgets.dart';

/// Full-screen order detail page.
/// Replaces the inner [OrderDetailPage] widget in orders_page.dart.
/// Usage:
///   Get.to(() => OrderDetailPage(orderId: order.id, controller: controller));
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    required this.orderId,
    required this.controller,
    super.key,
  });

  final int orderId;
  final HomeController controller;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Future<UserOrderDetail?>? _detailFuture;

  @override
void initState() {
  super.initState();
  _detailFuture = widget.controller.fetchOrderDetail(widget.orderId);
}

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final h24 = d.hour;
      final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
      final min = d.minute.toString().padLeft(2, '0');
      final ampm = h24 >= 12 ? 'PM' : 'AM';
      return '${months[d.month - 1]} ${d.day}, ${d.year}, $h12:$min $ampm';
    } catch (_) {
      return raw;
    }
  }

  int _activeStep(int status) {
    if (status <= 1) return 0;
    if (status >= 5) return 4;
    return status - 1;
  }

  /// Maps status int → human-readable label.
  String _statusLabel(int s) {
    const labels = {
      1: 'Placed',
      2: 'Preparing',
      3: 'Shipped',
      4: 'Delivered',
      5: 'Completed',
      6: 'Rejected',
    };
    return labels[s] ?? 'Processing';
  }

  Color _statusColor(int s) {
    if (s == 5) return const Color(0xFF34C759); // completed = green
    if (s == 6) return const Color(0xFFFF3B30); // rejected = red
    return const Color(0xFF007AFF); // others = blue
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: FutureBuilder<UserOrderDetail?>(
                future: _detailFuture,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snap.hasData || snap.data == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.black38,
                          ),
                          const SizedBox(height: 12),
                          const Text('Could not load order details.'),
                          const SizedBox(height: 12),
                          FilledButton(
  onPressed: () {
    final future = widget.controller.fetchOrderDetail(widget.orderId);
    setState(() {
      _detailFuture = future;
    });
  },
  child: const Text('Retry'),
),  
                        ],
                      ),
                    );
                  }
                  return _buildBody(snap.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Appbar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
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
              'Order Details',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF9500),
              side: const BorderSide(color: Color(0x99FF9500)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Invoice',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main body ────────────────────────────────────────────────────────────

  Widget _buildBody(UserOrderDetail detail) {
    final dateStr = _formatDate(detail.dateLabel);
    final itemCount = detail.items.fold<int>(0, (s, i) => s + i.qty);
    final pkgLabel =
        detail.items.length == 1 ? '1 package' : '${detail.items.length} packages';

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ── Order header card ──────────────────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${detail.id}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 5),
                        _StatusBadge(
                          label: _statusLabel(detail.status),
                          color: _statusColor(detail.status),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'TRY ${detail.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoGrid(tiles: [
                ('Order date', dateStr),
                ('Items', '$pkgLabel · $itemCount items'),
                ('Subtotal', 'TRY ${detail.subtotal.toStringAsFixed(2)}'),
                ('Shipping', 'TRY ${detail.shippingFee.toStringAsFixed(2)}'),
              ]),
            ],
          ),
        ),

        // ── Progress timeline card ─────────────────────────────────────
        _card(
          child: _ProgressTimeline(
            statusText: _statusLabel(detail.status),
            activeStep: _activeStep(detail.status),
            isRejected: detail.status == 6,
            cargoCompany: detail.cargoCompany,
            trackingNo: detail.trackingNo,
          ),
        ),

        // ── Order items ────────────────────────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order items',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 12),
              ...detail.items.map(_buildItemCard),
            ],
          ),
        ),

        // ── Delivery & Invoice addresses ───────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AddressSection(
                title: 'Delivery address',
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFF007AFF),
                addressText: detail.addressText,
                town: detail.town,
                city: detail.city,
              ),
              const Divider(height: 24, thickness: 0.5),
              _AddressSection(
                title: 'Invoice address',
                icon: Icons.receipt_outlined,
                iconColor: Colors.black45,
                addressText: detail.addressText,
                town: detail.town,
                city: detail.city,
              ),
            ],
          ),
        ),

        // ── Payment summary ────────────────────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment info',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 12),
              SummaryRow(label: 'Subtotal', value: detail.subtotal),
              SummaryRow(label: 'Shipping', value: detail.shippingFee),
              const Divider(height: 16, thickness: 0.5),
              SummaryRow(
                label: 'Total',
                value: detail.total,
                isBold: true,
              ),

              // Confirm delivery button (visible when Delivered/Shipped)
              if (detail.status == 3 || detail.status == 4) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.snackbar(
                        'Delivery confirmed',
                        'Your order has been marked as received.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF34C759),
                        colorText: Colors.white,
                        borderRadius: 12,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34C759),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirm delivery',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Item card row ────────────────────────────────────────────────────────

  Widget _buildItemCard(OrderLineItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: item.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.image_outlined,
                            color: Colors.black38,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.black38,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.brand,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Qty: ${item.qty}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TRY ${item.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF9500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9500),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Review',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    onPressed: () => widget.controller.addToCart(item.itemId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF9500),
                      side: const BorderSide(color: Color(0x66FF9500)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Buy again',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.5),
        ],
      ),
    );
  }

  // ─── Shared card wrapper ──────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.tiles});

  final List<(String, String)> tiles;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: tiles
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t.$1,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ProgressTimeline extends StatelessWidget {
  const _ProgressTimeline({
    required this.statusText,
    required this.activeStep,
    required this.isRejected,
    this.cargoCompany,
    this.trackingNo,
  });

  final String statusText;
  final int activeStep;
  final bool isRejected;
  final String? cargoCompany;
  final String? trackingNo;

  static const _steps = ['Placed', 'Preparing', 'Shipped', 'Delivered', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ORDER PROGRESS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Connector line
              final lineIndex = i ~/ 2;
              final isDone = lineIndex < activeStep && !isRejected;
              return Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF34C759)
                        : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }
            // Step circle
            final stepIndex = i ~/ 2;
            final isDone = stepIndex < activeStep && !isRejected;
            final isCurrent = stepIndex == activeStep && !isRejected;
            return Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? const Color(0xFF34C759)
                        : isCurrent
                            ? const Color(0xFF007AFF)
                            : const Color(0xFFF2F2F7),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF007AFF)
                          : isDone
                              ? const Color(0xFF34C759)
                              : const Color(0xFFE5E5EA),
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                              blurRadius: 0,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isCurrent ? Colors.white : Colors.black45,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 54,
                  child: Text(
                    _steps[stepIndex],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDone || isCurrent
                          ? isDone
                              ? const Color(0xFF34C759)
                              : const Color(0xFF007AFF)
                          : Colors.black45,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        if (cargoCompany != null || trackingNo != null) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              if (cargoCompany != null)
                _CargoPill(
                  icon: Icons.local_shipping_outlined,
                  text: cargoCompany!,
                ),
              if (trackingNo != null)
                _CargoPill(
                  icon: Icons.barcode_reader,
                  text: 'Tracking: $trackingNo',
                ),
            ],
          ),
        ],
        if (isRejected) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cancel_outlined,
                  size: 16,
                  color: Color(0xFFFF3B30),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Order rejected by admin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF3B30),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CargoPill extends StatelessWidget {
  const _CargoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.black54),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF636366),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.addressText,
    this.town,
    this.city,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String? addressText;
  final String? town;
  final String? city;

  @override
  Widget build(BuildContext context) {
    final location = [town, city].where((s) => s != null && s.isNotEmpty).join(' / ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          addressText ?? '-',
          style: const TextStyle(fontSize: 13, color: Color(0xFF636366)),
        ),
        if (location.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            location,
            style: const TextStyle(fontSize: 13, color: Colors.black45),
          ),
        ],
      ],
    );
  }
}