import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
          return const Center(child: Text('No favorite items yet.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Favorites',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                      side: const BorderSide(color: Colors.black12),
                    ),
                    tileColor: Colors.white,
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade100,
                      child: const Icon(Icons.favorite, color: Colors.red),
                    ),
                    title: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('${p.price.toStringAsFixed(0)} TL'),
                    trailing: IconButton(
                      onPressed: () => controller.toggleFavorite(p.id),
                      icon: const Icon(Icons.delete_outline),
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