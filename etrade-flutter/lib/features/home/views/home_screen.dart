import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../models/product_item.dart';
import 'address_page.dart';
import 'cards_page.dart';
import 'cart_page.dart';
import 'change_password_page.dart';
import 'favorites_page.dart';
import 'my_reviews_page.dart';
import 'orders_screen.dart';
import 'productdetail_page.dart';
import 'profile_page.dart';
import '../../../theme/tradehub_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(
      () => Scaffold(
        backgroundColor: TradeHubColors.bg,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: controller.selectedBottomIndex.value,
          onTap: controller.changeBottomTab,
          type: BottomNavigationBarType.fixed,
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
              FavoritesPage(controller: controller),
              CartPage(controller: controller),
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
        return const Center(
          child: CircularProgressIndicator(color: TradeHubColors.accent),
        );
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: TradeHubColors.textMuted),
              ),
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
        return const Center(
          child: Text(
            'No results in the loaded catalog for this filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TradeHubColors.textMuted),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.selectedCategory.value == HomeController.bestsellerCategory) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Best Sellers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                      color: TradeHubColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Top items by purchase volume',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.25,
                      color: TradeHubColors.textMuted.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: _ProductGrid(
              controller: controller,
              items: controller.filteredProducts,
            ),
          ),
        ],
      );
    });
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                TradeHubColors.primary.withValues(alpha: 0.35),
                TradeHubColors.surface2,
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: TradeHubColors.primary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/icons/TradeHub-logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TradeHub',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: TradeHubColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Discover & shop',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: TradeHubColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TradeHubColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: TradeHubColors.textMuted,
            size: 22,
          ),
        ),
      ],
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
      style: const TextStyle(
        color: TradeHubColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: TradeHubColors.accent,
      decoration: InputDecoration(
        hintText: 'Search products…',
        hintStyle: TextStyle(
          color: TradeHubColors.textMuted.withValues(alpha: 0.85),
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 14,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: TradeHubColors.textMuted,
          size: 24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: TradeHubColors.accent,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: TradeHubColors.surface2,
      ),
    );
  }
}

/// All + shop categories in one horizontal strip (swipe left–right on mobile).
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedCategory.value;
      return SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: controller.categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = controller.categories[index];
            final isSel = selected == category;
            return _CategoryPill(
              label: category,
              selected: isSel,
              onTap: () => controller.changeCategory(category),
            );
          },
        ),
      );
    });
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TradeHubColors.primary,
                      TradeHubColors.primaryDeep,
                    ],
                  )
                : null,
            color: selected ? null : TradeHubColors.surface2,
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: TradeHubColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : TradeHubColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.controller, required this.items});

  final HomeController controller;
  final List<ProductItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        final isBestSeller = controller.selectedCategory.value == HomeController.bestsellerCategory;
        return Obx(() {
          final isFavorite = controller.favoriteProductIds.contains(product.id);
          return _ProductCard(
            product: product,
            isBestSeller: isBestSeller,
            isFavorite: isFavorite,
            controller: controller,
          );
        });
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isBestSeller,
    required this.isFavorite,
    required this.controller,
  });

  final ProductItem product;
  final bool isBestSeller;
  final bool isFavorite;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final subtitle = product.category.isNotEmpty
        ? '${product.category} • ${isBestSeller ? 'fast delivery' : 'Fresh and fast delivery'}'
        : (isBestSeller ? 'fast delivery' : 'Fresh quality • fast delivery');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.to(
          () => ProductDetailPage(
            controller: controller,
            product: product,
            allProducts: controller.products.toList(),
          ),
          transition: Transition.rightToLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: TradeHubColors.surface2,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 116,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_outlined,
                                size: 36,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        if (isBestSeller)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Bestseller',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () => controller.toggleFavorite(product.id),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: isFavorite ? Colors.redAccent : const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: TradeHubColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TradeHubColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${product.totalReviews})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: TradeHubColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: TradeHubColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'TRY ${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: TradeHubColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 34,
                      child: ElevatedButton.icon(
                        onPressed: () => controller.addToCart(product.id),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                        label: const Text(
                          'Order',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: TradeHubColors.textPrimary,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: authController.logout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Obx(() {
            final displayName = controller.profile.value.fullName.isNotEmpty
                ? controller.profile.value.fullName
                : (authController.userName.value.isNotEmpty
                      ? authController.userName.value
                      : 'Member');
            final email = controller.profile.value.email.isNotEmpty
                ? controller.profile.value.email
                : authController.userEmail.value;
            final dn = displayName.trim();
            final initial = dn.isEmpty ? 'T' : dn[0].toUpperCase();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    TradeHubColors.primaryDeep.withValues(alpha: 0.35),
                    TradeHubColors.surface2,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: TradeHubColors.primary.withValues(alpha: 0.25),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: TradeHubColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: TradeHubColors.textPrimary,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: TradeHubColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _AccountMenuTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  subtitle: 'Name, email, phone, gender & birthday',
                  onTap: () => Get.to(
                    () => ProfilePage(controller: controller),
                    transition: Transition.rightToLeft,
                  ),
                ),
                const SizedBox(height: 10),
                _AccountMenuTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Orders',
                  subtitle: 'History and delivery status',
                  onTap: () => Get.to(
                    () => OrdersScreen(controller: controller),
                    transition: Transition.rightToLeft,
                  ),
                ),
                const SizedBox(height: 10),
                _AccountMenuTile(
                  icon: Icons.location_on_outlined,
                  title: 'Addresses',
                  subtitle: 'Delivery addresses',
                  onTap: () => Get.to(
                    () => AddressPage(controller: controller),
                    transition: Transition.rightToLeft,
                  ),
                ),
                const SizedBox(height: 10),
                _AccountMenuTile(
                  icon: Icons.credit_card_outlined,
                  title: 'Saved cards',
                  subtitle: 'Payment cards on your account',
                  onTap: () => Get.to(
                    () => CardsPage(controller: controller),
                    transition: Transition.rightToLeft,
                  ),
                ),
                const SizedBox(height: 10),
                _AccountMenuTile(
                  icon: Icons.reviews_outlined,
                  title: 'My Reviews',
                  subtitle: 'Your product ratings and comments',
                  onTap: () => Get.to(
                    () => MyReviewsPage(controller: controller),
                    transition: Transition.rightToLeft,
                  ),
                ),
                const SizedBox(height: 10),
                _AccountMenuTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change password',
                  subtitle: 'Update your sign-in password',
                  onTap: () => Get.to(
                    () => ChangePasswordPage(controller: controller),
                    transition: Transition.rightToLeft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: TradeHubColors.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: TradeHubColors.surface,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Icon(icon, color: TradeHubColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: TradeHubColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: TradeHubColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: TradeHubColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
