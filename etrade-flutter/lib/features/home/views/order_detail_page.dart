import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/order_status.dart';
import '../../../theme/tradehub_theme.dart';
import '../controllers/home_controller.dart';
import '../models/account_models.dart';
import 'home_shared_widgets.dart';

/// Full-screen order detail: timeline, line items, addresses, payment summary.
/// Opened from [OrdersScreen] with `Get.to(() => OrderDetailPage(...))`.
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
  bool _confirmDeliveryBusy = false;

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

  /// Timeline step index 0–4 = Placed…Delivered; 5 = all complete; -1 = rejected.
  int _timelineActiveStep(int status) {
    if (status == OrderStatus.rejected) return -1;
    if (status == OrderStatus.completed) return 5;
    if (status >= OrderStatus.placed && status <= OrderStatus.delivered) {
      return status;
    }
    return OrderStatus.placed;
  }

  Color _statusAccent(int status) {
    if (status == OrderStatus.rejected) return TradeHubColors.danger;
    if (status == OrderStatus.completed || status == OrderStatus.delivered) {
      return TradeHubColors.success;
    }
    return TradeHubColors.primary;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeHubColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: FutureBuilder<UserOrderDetail?>(
                future: _detailFuture,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: TradeHubColors.primary),
                    );
                  }
                  if (!snap.hasData || snap.data == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: TradeHubColors.textMuted.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Could not load order details.',
                            style: TextStyle(color: TradeHubColors.textMuted),
                          ),
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
              'Order Details',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TradeHubColors.textPrimary,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: TradeHubColors.accent,
              side: BorderSide(color: TradeHubColors.accent.withValues(alpha: 0.5)),
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
    final statusLabel = OrderStatus.displayLabel(
      status: detail.status,
      statusText: detail.statusText,
    );

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
                            color: TradeHubColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _StatusBadge(
                          label: statusLabel,
                          color: _statusAccent(detail.status),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 11, color: TradeHubColors.textMuted),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'TRY ${detail.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: TradeHubColors.textPrimary,
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
            statusText: statusLabel,
            activeStep: _timelineActiveStep(detail.status),
            isRejected: detail.status == OrderStatus.rejected,
            rejectReasonCode: detail.rejectReasonCode,
            rejectReasonNote: detail.rejectReasonNote,
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
                  color: TradeHubColors.textPrimary,
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
                iconColor: TradeHubColors.accent,
                addressText: detail.addressText,
                town: detail.town,
                city: detail.city,
              ),
              Divider(height: 24, thickness: 0.5, color: Colors.white.withValues(alpha: 0.08)),
              _AddressSection(
                title: 'Invoice address',
                icon: Icons.receipt_outlined,
                iconColor: TradeHubColors.textMuted,
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
                  color: TradeHubColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SummaryRow(label: 'Subtotal', value: detail.subtotal),
              SummaryRow(label: 'Shipping', value: detail.shippingFee),
              Divider(height: 16, thickness: 0.5, color: Colors.white.withValues(alpha: 0.08)),
              SummaryRow(
                label: 'Total',
                value: detail.total,
                isBold: true,
              ),

              // Same rule as web account order: shipped or delivered → customer can complete.
              if (detail.status == OrderStatus.shipped ||
                  detail.status == OrderStatus.delivered) ...[
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'I received my order',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: TradeHubColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'If everything has arrived, confirm below to complete this order.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: TradeHubColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _confirmDeliveryBusy
                        ? null
                        : () async {
                            setState(() => _confirmDeliveryBusy = true);
                            final ok =
                                await widget.controller.confirmOrderDelivery(detail.id);
                            if (!mounted) return;
                            setState(() => _confirmDeliveryBusy = false);
                            if (!mounted) return;
                            if (ok) {
                              setState(() {
                                _detailFuture =
                                    widget.controller.fetchOrderDetail(widget.orderId);
                              });
                              Get.snackbar(
                                'Delivery',
                                'Your order has been marked as completed.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: TradeHubColors.success,
                                colorText: const Color(0xFF0B1020),
                                margin: const EdgeInsets.all(16),
                                borderRadius: 12,
                              );
                            } else {
                              Get.snackbar(
                                'Delivery',
                                'Could not confirm. Please try again.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: TradeHubColors.danger,
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(16),
                                borderRadius: 12,
                              );
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF34D399),
                      foregroundColor: const Color(0xFF0B1020),
                      disabledBackgroundColor: TradeHubColors.panel,
                      elevation: 0,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _confirmDeliveryBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFF0B1020),
                            ),
                          )
                        : const Text(
                            'I received it',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
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
                  color: TradeHubColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: item.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.image_outlined,
                            color: TradeHubColors.textMuted,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.shopping_bag_outlined,
                        color: TradeHubColors.textMuted,
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
                        color: TradeHubColors.textPrimary,
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
                        color: TradeHubColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Qty: ${item.qty}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: TradeHubColors.textMuted,
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
                  color: TradeHubColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: TradeHubColors.surface,
                    side: const BorderSide(color: Color(0x66FFFFFF)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Review',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed: () => widget.controller.addToCart(item.itemId),
                  style: FilledButton.styleFrom(
                    backgroundColor: TradeHubColors.accent,
                    foregroundColor: const Color(0xFF0B1020),
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Buy again',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B1020),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 20, thickness: 0.5, color: Colors.white.withValues(alpha: 0.08)),
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
        color: TradeHubColors.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                color: TradeHubColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t.$1,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TradeHubColors.textMuted,
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
                      color: TradeHubColors.textPrimary,
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
    this.rejectReasonCode,
    this.rejectReasonNote,
    this.cargoCompany,
    this.trackingNo,
  });

  final String statusText;
  final int activeStep;
  final bool isRejected;
  final String? rejectReasonCode;
  final String? rejectReasonNote;
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
            color: TradeHubColors.textMuted,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Connector line
              final lineIndex = i ~/ 2;
              final isDone = activeStep >= 0 && lineIndex < activeStep;
              return Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isDone ? TradeHubColors.success : TradeHubColors.panel,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }
            // Step circle
            final stepIndex = i ~/ 2;
            final isDone = activeStep >= 0 && stepIndex < activeStep;
            final isCurrent = activeStep >= 0 && stepIndex == activeStep;
            return Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? TradeHubColors.success
                        : isCurrent
                            ? TradeHubColors.primaryDeep
                            : TradeHubColors.surface,
                    border: Border.all(
                      color: isCurrent
                          ? TradeHubColors.primary
                          : isDone
                              ? TradeHubColors.success
                              : TradeHubColors.outline,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: TradeHubColors.primary.withValues(alpha: 0.35),
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
                            color: Color(0xFF0B1020),
                          )
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isCurrent ? Colors.white : TradeHubColors.textMuted,
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
                              ? TradeHubColors.success
                              : TradeHubColors.primary
                          : TradeHubColors.textMuted,
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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: TradeHubColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TradeHubColors.danger.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cancel_outlined, size: 16, color: TradeHubColors.danger),
                    SizedBox(width: 8),
                    Text(
                      'Order rejected',
                      style: TextStyle(
                        fontSize: 12,
                        color: TradeHubColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (rejectReasonCode != null && rejectReasonCode!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    rejectReasonCode!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TradeHubColors.textPrimary,
                    ),
                  ),
                ],
                if (rejectReasonNote != null && rejectReasonNote!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    rejectReasonNote!.trim(),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: TradeHubColors.textMuted,
                    ),
                  ),
                ],
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
        color: TradeHubColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: TradeHubColors.textMuted),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: TradeHubColors.textMuted,
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
                color: TradeHubColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          addressText ?? '-',
          style: const TextStyle(fontSize: 13, color: TradeHubColors.textMuted),
        ),
        if (location.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            location,
            style: const TextStyle(fontSize: 13, color: TradeHubColors.textMuted),
          ),
        ],
      ],
    );
  }
}