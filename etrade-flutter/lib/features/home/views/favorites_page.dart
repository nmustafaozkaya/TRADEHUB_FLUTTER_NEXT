import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/tradehub_theme.dart';
import '../controllers/home_controller.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final favProducts = controller.products
            .where((p) => controller.favoriteProductIds.contains(p.id))
            .toList();
        if (favProducts.isEmpty) {
          return const Center(
            child: Text(
              'No favorite items yet.',
              style: TextStyle(color: TradeHubColors.textMuted),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Favorites',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: TradeHubColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: favProducts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = favProducts[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    tileColor: TradeHubColors.surface2,
                    leading: CircleAvatar(
                      backgroundColor: TradeHubColors.panel,
                      child: const Icon(Icons.favorite, color: Colors.redAccent),
                    ),
                    title: Text(
                      p.name,
                      maxLines: 1,
                      style: const TextStyle(color: TradeHubColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'TRY ${p.price.toStringAsFixed(0)}',
                      style: const TextStyle(color: TradeHubColors.accent),
                    ),
                    trailing: IconButton(
                      onPressed: () => controller.toggleFavorite(p.id),
                      icon: const Icon(Icons.delete_outline, color: TradeHubColors.textMuted),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}