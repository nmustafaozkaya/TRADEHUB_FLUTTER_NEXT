import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/tradehub_theme.dart';
import '../controllers/home_controller.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({required this.controller, super.key});

  final HomeController controller;

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeHubColors.bg,
      appBar: AppBar(
        title: const Text('My Reviews'),
        backgroundColor: TradeHubColors.bg,
        foregroundColor: TradeHubColors.textPrimary,
      ),
      body: Obx(() {
        if (widget.controller.isReviewsLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (widget.controller.reviewsErrorMessage.value.isNotEmpty) {
          return Center(
            child: Text(
              widget.controller.reviewsErrorMessage.value,
              style: const TextStyle(color: TradeHubColors.textMuted),
            ),
          );
        }
        if (widget.controller.reviews.isEmpty) {
          return const Center(
            child: Text('No reviews yet.', style: TextStyle(color: TradeHubColors.textMuted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: widget.controller.reviews.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final r = widget.controller.reviews[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TradeHubColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.itemName,
                    style: const TextStyle(
                      color: TradeHubColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${r.orderId} · ${r.brand}',
                    style: const TextStyle(color: TradeHubColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${'★' * r.rating}${'☆' * (5 - r.rating)}  (${r.rating}/5)',
                    style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.comment.isEmpty ? 'No comment.' : r.comment,
                    style: const TextStyle(color: TradeHubColors.textPrimary),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

