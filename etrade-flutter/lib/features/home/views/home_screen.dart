import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';

/// First version of e-commerce mobile home screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Obx(
      () => Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: controller.selectedBottomIndex.value,
          onTap: controller.changeBottomTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.black54,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_rounded),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(
            index: controller.selectedBottomIndex.value,
            children: [
              _HomeContent(controller: controller),
              _FavoritesBody(controller: controller),
              _CartBody(controller: controller),
              _AccountBody(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _HeaderRow(),
          const SizedBox(height: 14),
          _SearchBar(controller: controller),
          const SizedBox(height: 14),
          _CampaignBanner(),
          const SizedBox(height: 14),
          _CategoryChips(controller: controller),
          const SizedBox(height: 14),
          Expanded(child: _HomeBody(controller: controller)),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(controller.errorMessage.value, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: controller.loadProducts,
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      }

      if (controller.filteredProducts.isEmpty) {
        return const Center(child: Text('No results found.'));
      }

      return _ProductGrid(controller: controller);
    });
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/icons/TradeHub-logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TradeHub',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text('Mobile Shopping', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        SvgPicture.asset(
          'assets/icons/globe.svg',
          width: 20,
          colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.notifications_none_rounded),
      ],
    );
  }
}

class _FavoritesBody extends StatelessWidget {
  const _FavoritesBody({required this.controller});

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
                separatorBuilder: (context, index) => const SizedBox(height: 10),
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
                    title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
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

class _CartBody extends StatelessWidget {
  const _CartBody({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final suggestedCount = controller.favoriteProductIds.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cart',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                suggestedCount == 0
                    ? 'Your cart is empty for now. Add favorites and move them to cart.'
                    : 'Cart module is ready. You can quickly add $suggestedCount favorite item(s) to cart.',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => controller.changeBottomTab(0),
              icon: const Icon(Icons.storefront),
              label: const Text('Continue shopping'),
            ),
          ],
        );
      }),
    );
  }
}

class _AccountBody extends StatelessWidget {
  const _AccountBody({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'Account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Obx(
            () => Text(
              authController.userName.value.isEmpty
                  ? 'TradeHub user'
                  : authController.userName.value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 12),
          const _AccountTile(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Manage your name, email and account details',
          ),
          const _AccountTile(
            icon: Icons.location_on_outlined,
            title: 'Addresses',
            subtitle: 'Update your delivery addresses',
          ),
          const _AccountTile(
            icon: Icons.receipt_long_outlined,
            title: 'Orders',
            subtitle: 'View your order history',
          ),
          const _AccountTile(
            icon: Icons.support_agent_outlined,
            title: 'Support',
            subtitle: 'Live chat and help center',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: authController.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black12),
        ),
        tileColor: Colors.white,
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: controller.updateSearch,
      decoration: InputDecoration(
        hintText: 'Search product, brand or category',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.tune_rounded),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CampaignBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spring Deal',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '20% discount in cart',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.categories.length,
          separatorBuilder: (_, index) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            final category = controller.categories[index];
            final isSelected = category == controller.selectedCategory.value;
            return ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => controller.changeCategory(category),
            );
          },
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.filteredProducts;
      return RefreshIndicator(
        onRefresh: controller.loadProducts,
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (_, index) {
            final product = items[index];
            final isFavorite = controller.favoriteProductIds.contains(
              product.id,
            );
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.image_outlined,
                                  size: 34,
                                  color: Colors.black38,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: IconButton(
                                onPressed: () =>
                                    controller.toggleFavorite(product.id),
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFavorite
                                      ? Colors.red
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.discountLabel,
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        Text(product.rating.toStringAsFixed(1)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(0)} TL',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${product.oldPrice.toStringAsFixed(0)} TL',
                      style: const TextStyle(
                        color: Colors.black45,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
