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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
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
        const Icon(Icons.notifications_none_rounded),
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
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: controller.categories
              .map(
                (category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: controller.selectedCategory.value == category,
                    onSelected: (selected) {
                      if (selected) controller.changeCategory(category);
                    },
                  ),
                ),
              )
              .toList(),
        ),
      );
    });
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.controller, required this.items});

  final HomeController controller;
  final List<ProductItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        final isFavorite = controller.favoriteProductIds.contains(product.id);
        return GestureDetector(
          onTap: () => Get.to(
            () => _ProductDetailPage(
              controller: controller,
              product: product,
              allProducts: controller.products.toList(),
            ),
            transition: Transition.rightToLeft,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'TRY ${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => controller.toggleFavorite(product.id),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : null,
                      ),
                      iconSize: 20,
                    ),
                    IconButton(
                      onPressed: () => controller.addToCart(product.id),
                      icon: const Icon(Icons.add_shopping_cart),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'My Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton.icon(
                onPressed: authController.logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => Text(
              authController.userName.value.isEmpty
                  ? 'TradeHub user'
                  : authController.userName.value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 20),
          _AccountMenuTile(
            title: 'Profile',
            subtitle: 'Update your profile',
            onTap: () => Get.to(
              () => _ProfilePage(controller: controller),
              transition: Transition.rightToLeft,
            ),
          ),
          const SizedBox(height: 12),
          _AccountMenuTile(
            title: 'Orders',
            subtitle: 'View your order history',
            onTap: () => Get.to(
              () => OrdersScreen(controller: controller),
              transition: Transition.rightToLeft,
            ),
          ),
          const SizedBox(height: 12),
          _AccountMenuTile(
            title: 'Addresses',
            subtitle: 'Manage delivery addresses',
            onTap: () => Get.to(
              () => AddressPage(controller: controller),
              transition: Transition.rightToLeft,
            ),
          ),
          const SizedBox(height: 12),
          _AccountMenuTile(
            title: 'Cards',
            subtitle: 'Manage saved cards',
            onTap: () => Get.to(
              () => CardsPage(controller: controller),
              transition: Transition.rightToLeft,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final nameController = TextEditingController(text: controller.profile.value.fullName.isNotEmpty ? controller.profile.value.fullName : authController.userName.value);
    final emailController = TextEditingController(text: controller.profile.value.email.isNotEmpty ? controller.profile.value.email : authController.userEmail.value);
    final phoneController = TextEditingController(text: controller.profile.value.phone.isNotEmpty ? controller.profile.value.phone : authController.userPhone.value);
    final genderController = TextEditingController(text: controller.profile.value.gender.isNotEmpty ? controller.profile.value.gender : 'Other');
    final birthdateController = TextEditingController(text: controller.profile.value.birthdate.isNotEmpty ? controller.profile.value.birthdate : authController.userBirthdate.value);

    InputDecoration modernInput({
      required String label,
      required IconData icon,
    }) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: modernInput(label: 'Full name', icon: Icons.person_outline),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: modernInput(label: 'Email', icon: Icons.alternate_email_rounded),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: modernInput(label: 'Phone', icon: Icons.phone_outlined),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: genderController,
              decoration: modernInput(label: 'Gender', icon: Icons.wc_outlined),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: birthdateController,
              decoration: modernInput(label: 'Birthdate', icon: Icons.cake_outlined),
            ),
            const SizedBox(height: 18),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isSavingProfile.value
                    ? null
                    : () => controller.saveProfile(
                          controller.profile.value.copyWith(
                            fullName: nameController.text,
                            email: emailController.text,
                            phone: phoneController.text,
                            gender: genderController.text,
                            birthdate: birthdateController.text,
                          ),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  controller.isSavingProfile.value ? 'Saving...' : 'Save Profile',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailPage extends StatefulWidget {
  const _ProductDetailPage({
    required this.controller,
    required this.product,
    required this.allProducts,
  });

  final HomeController controller;
  final ProductItem product;
  final List<ProductItem> allProducts;

  @override
  State<_ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<_ProductDetailPage> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final brand = p.name.split(' ').first.toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Center(
              child: Image.network(
                p.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined, size: 64),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Brand: $brand', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Text('TRY ${p.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: qty > 1 ? () => setState(() => qty--) : null,
                icon: const Icon(Icons.remove),
              ),
              Text('$qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => setState(() => qty++),
                icon: const Icon(Icons.add),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  widget.controller.addToCart(p.id, qty: qty);
                  widget.controller.changeBottomTab(2);
                  Get.back();
                  Get.snackbar('Cart', '$qty item(s) added');
                },
                child: const Text('Add to cart'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
