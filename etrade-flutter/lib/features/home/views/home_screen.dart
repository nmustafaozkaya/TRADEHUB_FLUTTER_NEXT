import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../models/product_item.dart';
import 'address_page.dart';
import 'cards_page.dart';
import 'cart_page.dart';
import 'favorites_page.dart';
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

      return _ProductGrid(
        controller: controller,
        items: controller.filteredProducts,
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
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
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        return Obx(() {
          final isFavorite = controller.favoriteProductIds.contains(product.id);
          return _ProductCard(
            product: product,
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
    required this.isFavorite,
    required this.controller,
  });

  final ProductItem product;
  final bool isFavorite;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                TradeHubColors.surface2,
                TradeHubColors.surface.withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: TradeHubColors.primary.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: TradeHubColors.bg.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: TradeHubColors.textMuted.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: TradeHubColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              color: TradeHubColors.textMuted.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                          Text(
                            product.price.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: TradeHubColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CardIconButton(
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: isFavorite
                          ? TradeHubColors.danger
                          : TradeHubColors.textMuted,
                      onPressed: () => controller.toggleFavorite(product.id),
                    ),
                    const SizedBox(width: 6),
                    _CardIconButton(
                      icon: Icons.add_shopping_cart_rounded,
                      iconColor: TradeHubColors.textPrimary,
                      highlight: true,
                      onPressed: () => controller.addToCart(product.id),
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

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor = TradeHubColors.textMuted,
    this.highlight = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color iconColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? TradeHubColors.primary.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.06);
    final border = highlight
        ? TradeHubColors.primary.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.08);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 19, color: iconColor),
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
