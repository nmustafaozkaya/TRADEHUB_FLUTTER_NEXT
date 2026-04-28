import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../models/account_models.dart';
import '../models/product_item.dart';

/// First version of e-commerce mobile home screen.
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
      final favoriteCount = controller.favoriteProductIds.length;
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
        favoriteCount: favoriteCount,
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

class _CartBody extends StatelessWidget {
  const _CartBody({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final cartEntries = controller.cartQuantities.entries.toList();
        final cartItems = cartEntries.map((entry) {
          ProductItem? product;
          for (final p in controller.products) {
            if (p.id == entry.key) {
              product = p;
              break;
            }
          }
          return (product: product, qty: entry.value);
        }).where((e) => e.product != null).toList();
        final total = cartItems.fold<double>(
          0,
          (sum, item) => sum + (item.product!.price * item.qty),
        );
        final protectionTotal = cartItems.fold<double>(
          0,
          (sum, item) => sum + controller.getCartProtection(item.product!.id),
        );
        const shippingThreshold = 300.0;
        final shipping = total >= shippingThreshold ? 0.0 : 30.0;
        const discount = 0.0;
        final grandTotal = total + protectionTotal + shipping - discount;

        return ListView(
          children: [
            Text(
              'Cart',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${cartItems.length} items',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => controller.changeBottomTab(0),
                  icon: const Icon(Icons.storefront, size: 18),
                  label: const Text('Continue shopping'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: controller.clearCart,
                  child: const Text('Clear cart'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (cartItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Text(
                  'Your cart is empty for now. Add products from item details.',
                ),
              ),
            ...cartItems.map((row) {
              final p = row.product!;
              final qty = row.qty;
              final lineTotal = p.price * qty;
              final lowerCategory = p.category.toLowerCase();
              final lowerName = p.name.toLowerCase();
              final hasProtection = lowerCategory.contains('electronic') ||
                  lowerCategory.contains('elektronik') ||
                  lowerName.contains('tv') ||
                  lowerName.contains('battery') ||
                  lowerName.contains('phone') ||
                  lowerName.contains('laptop');
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.network(
                            p.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(Icons.image_outlined),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text('TRY ${p.price.toStringAsFixed(2)}'),
                              const SizedBox(height: 2),
                              Text(
                                '•  Line: TRY ${lineTotal.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => controller.decreaseCartItem(p.id),
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700)),
                        IconButton(
                          onPressed: () => controller.addToCart(p.id),
                          icon: const Icon(Icons.add),
                        ),
                        TextButton(
                          onPressed: () => controller.removeFromCart(p.id),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                    if (hasProtection) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'TradeHub Protection',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Text(
                        'Home essentials protection (UI preview).',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      ...[
                        (title: '1-year plan', price: 60.0),
                        (title: '2-year plan', price: 100.0),
                        (title: '3-year plan', price: 140.0),
                      ].map(
                        (plan) => Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(plan.title),
                                  const Text(
                                    'Protection plan preview for this item.',
                                    style: TextStyle(color: Colors.black54, fontSize: 12),
                                  ),
                                  Text(
                                    'TRY ${plan.price.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () =>
                                  controller.setCartProtectionPlan(p.id, plan.price),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            if (cartItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Subtotal', value: total),
                    _SummaryRow(label: 'Protection', value: protectionTotal),
                    _SummaryRow(
                      label: 'Shipping',
                      value: shipping,
                      note: shipping == 0
                          ? '(free over TRY ${shippingThreshold.toStringAsFixed(2)})'
                          : null,
                    ),
                    _SummaryRow(label: 'Discount', value: discount),
                    const Divider(),
                    _SummaryRow(
                      label: 'Total',
                      value: grandTotal,
                      isBold: true,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Get.to(
                          () => _CheckoutPage(controller: controller),
                          transition: Transition.rightToLeft,
                        ),
                        child: const Text('Checkout'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Checkout will create an order record in the database (MVP).',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.note,
    this.isBold = false,
  });

  final String label;
  final double value;
  final String? note;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      fontSize: isBold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(label, style: style),
                if (note != null) ...[
                  const SizedBox(width: 4),
                  Text(note!, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ],
            ),
          ),
          Text('TRY ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

enum _CheckoutPaymentMethod { card, eft, cod }

class _CheckoutPage extends StatefulWidget {
  const _CheckoutPage({required this.controller});

  final HomeController controller;

  @override
  State<_CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<_CheckoutPage> {
  _CheckoutPaymentMethod paymentMethod = _CheckoutPaymentMethod.card;
  int? selectedAddressId;
  int? selectedSavedCardId;
  bool useNewCard = false;
  bool saveCardForAccount = false;

  final cardHolderController = TextEditingController();
  final cardNumberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  String _cardBrandAsset(String brandRaw) {
    final brand = brandRaw.toLowerCase();
    if (brand.contains('visa')) return 'assets/icons/visa.png';
    if (brand.contains('master')) return 'assets/icons/master-card.png';
    if (brand.contains('american') || brand.contains('amex')) {
      return 'assets/icons/american-express.png';
    }
    if (brand.contains('union')) return 'assets/icons/unionpay.jpg';
    return 'assets/icons/visa.png';
  }

  String _cardBrandLabel(String brandRaw) {
    final brand = brandRaw.toLowerCase();
    if (brand.contains('visa')) return 'Visa';
    if (brand.contains('master')) return 'Mastercard';
    if (brand.contains('american') || brand.contains('amex')) return 'American Express';
    if (brand.contains('union')) return 'UnionPay';
    return 'Card';
  }

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    if (c.addresses.isNotEmpty) {
      selectedAddressId = c.addresses.first.id;
    }
    if (c.savedCards.isNotEmpty) {
      selectedSavedCardId = c.savedCards.first.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await c.refreshAddresses();
      await c.refreshCards();
      if (!mounted) return;
      setState(() {
        if (selectedAddressId == null && c.addresses.isNotEmpty) {
          selectedAddressId = c.addresses.first.id;
        }
        if (selectedSavedCardId == null && c.savedCards.isNotEmpty) {
          selectedSavedCardId = c.savedCards.first.id;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final cartEntries = c.cartQuantities.entries.toList();
    final cartItems = cartEntries
        .map((entry) {
          ProductItem? product;
          for (final p in c.products) {
            if (p.id == entry.key) {
              product = p;
              break;
            }
          }
          return (product: product, qty: entry.value);
        })
        .where((e) => e.product != null)
        .toList();
    final subtotal = cartItems.fold<double>(
      0,
      (sum, row) => sum + (row.product!.price * row.qty),
    );
    final protection = cartItems.fold<double>(
      0,
      (sum, row) => sum + c.getCartProtection(row.product!.id),
    );
    const shippingThreshold = 300.0;
    final shipping = subtotal >= shippingThreshold ? 0.0 : 30.0;
    const discount = 0.0;
    final total = subtotal + protection + shipping - discount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Secure checkout'),
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Address & payment details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1) Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(
                  'Choose a delivery address for your order.',
                  style: TextStyle(color: Colors.black54),
                ),
                const Divider(height: 22),
                const Text('Delivery address', style: TextStyle(fontWeight: FontWeight.w700)),
                const Text(
                  'Select where your order will be delivered.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => Get.to(
                      () => _AddressPage(controller: c),
                      transition: Transition.rightToLeft,
                    ),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Add new address'),
                  ),
                ),
                if (c.addresses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Text('No address yet. Add a new address first.'),
                  )
                else
                  RadioGroup<int>(
                    groupValue: selectedAddressId,
                    onChanged: (value) => setState(() => selectedAddressId = value),
                    child: Column(
                      children: c.addresses
                          .map(
                            (address) => RadioListTile<int>(
                              value: address.id,
                              title: Text(address.title),
                              subtitle: Text(address.addressText),
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment method', style: TextStyle(fontWeight: FontWeight.w700)),
                const Text(
                  'Payment is a UI preview in this MVP.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const Divider(height: 22),
                RadioGroup<_CheckoutPaymentMethod>(
                  groupValue: paymentMethod,
                  onChanged: (v) => setState(() => paymentMethod = v ?? paymentMethod),
                  child: Column(
                    children: [
                      RadioListTile<_CheckoutPaymentMethod>(
                        value: _CheckoutPaymentMethod.card,
                        title: const Text('Pay by card'),
                        subtitle: const Text(
                          'Use your debit/credit card. This is a demo flow and no real charge will be made.',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
          if (paymentMethod == _CheckoutPaymentMethod.card) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _PaymentBrandChip(assetPath: 'assets/icons/visa.png', label: 'Visa'),
                _PaymentBrandChip(assetPath: 'assets/icons/master-card.png', label: 'Mastercard'),
                _PaymentBrandChip(assetPath: 'assets/icons/american-express.png', label: 'American Express'),
                _PaymentBrandChip(assetPath: 'assets/icons/unionpay.jpg', label: 'UnionPay'),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Saved cards', style: TextStyle(fontWeight: FontWeight.w700)),
            if (c.savedCards.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('No saved cards yet.'),
              )
            else
              RadioGroup<int>(
                groupValue: selectedSavedCardId,
                onChanged: (value) {
                  if (useNewCard) return;
                  setState(() => selectedSavedCardId = value);
                },
                child: Column(
                  children: c.savedCards
                      .map(
                        (card) => RadioListTile<int>(
                          value: card.id,
                          title: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black12),
                                ),
                                alignment: Alignment.center,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    _cardBrandAsset(card.brand),
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.credit_card_outlined,
                                      size: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_cardBrandLabel(card.brand)} **** ${card.last4}',
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${card.cardHolder} · ${card.expMonth.toString().padLeft(2, '0')}/${card.expYear.toString().substring(2)}',
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
            SwitchListTile(
              value: useNewCard,
              onChanged: (v) => setState(() => useNewCard = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('Use a new card instead'),
            ),
            if (useNewCard) ...[
              TextField(
                controller: cardHolderController,
                decoration: const InputDecoration(labelText: 'Card holder'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Card number'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      decoration: const InputDecoration(labelText: 'Expiry date (MM/YY)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'CVV'),
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                value: saveCardForAccount,
                onChanged: (v) => setState(() => saveCardForAccount = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Save this card for my account'),
                subtitle: const Text(
                  'Security note: CVV is never stored. Only masked card details are saved.',
                ),
              ),
            ],
          ],
                      const Divider(height: 20),
                      RadioListTile<_CheckoutPaymentMethod>(
                        value: _CheckoutPaymentMethod.eft,
                        title: const Text('Bank transfer / EFT'),
                        subtitle: const Text(
                          'Place the order now, then complete payment by bank transfer.',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<_CheckoutPaymentMethod>(
                        value: _CheckoutPaymentMethod.cod,
                        title: const Text('Cash on delivery'),
                        subtitle: const Text(
                          'Pay with cash/card when the courier delivers the order.',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (cartItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('${cartItems.length} items'),
                  const SizedBox(height: 6),
                  ...cartItems.map(
                    (row) => Text(
                      '${row.product!.name} × ${row.qty}  •  TRY ${(row.product!.price * row.qty).toStringAsFixed(2)}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(label: 'Subtotal', value: subtotal),
                  _SummaryRow(label: 'Protection', value: protection),
                  _SummaryRow(
                    label: 'Shipping',
                    value: shipping,
                    note: shipping == 0
                        ? '(free over TRY ${shippingThreshold.toStringAsFixed(2)})'
                        : null,
                  ),
                  _SummaryRow(label: 'Discount', value: discount),
                  const Divider(),
                  _SummaryRow(label: 'Total', value: total, isBold: true),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (selectedAddressId == null) {
                          Get.snackbar('Checkout', 'Please select a delivery address.');
                          return;
                        }
                        if (paymentMethod == _CheckoutPaymentMethod.card) {
                          if (!useNewCard && c.savedCards.isEmpty) {
                            Get.snackbar('Checkout', 'Please add a card or use another payment method.');
                            return;
                          }
                          if (useNewCard && saveCardForAccount) {
                            final exp = expiryController.text.trim();
                            final parts = exp.split('/');
                            final month = parts.isNotEmpty ? parts.first : '';
                            final year = parts.length > 1 ? '20${parts.last}' : '';
                            await c.addCard(
                              cardNo: cardNumberController.text,
                              cardHolder: cardHolderController.text,
                              expMonth: month,
                              expYear: year,
                            );
                          }
                        }
                        UserAddress? selectedAddress;
                        for (final a in c.addresses) {
                          if (a.id == selectedAddressId) {
                            selectedAddress = a;
                            break;
                          }
                        }
                        final orderItems = cartItems
                            .map(
                              (row) => _PlacedOrderLine(
                                name: row.product!.name,
                                brand: 'TRADEHUB',
                                qty: row.qty,
                                unitPrice: row.product!.price,
                              ),
                            )
                            .toList();
                        c.checkoutCart();
                        final orderId = c.orders.isNotEmpty ? c.orders.first.id : 101281;
                        final placedAt = DateTime.now();
                        final paymentNote = switch (paymentMethod) {
                          _CheckoutPaymentMethod.card =>
                            'Card payment is a UI preview in this MVP; placing an order saves it to the database.',
                          _CheckoutPaymentMethod.eft =>
                            'Bank transfer / EFT is a UI preview in this MVP; placing an order saves it to the database.',
                          _CheckoutPaymentMethod.cod =>
                            'Cash on delivery is a UI preview in this MVP; placing an order saves it to the database.',
                        };
                        Get.off(
                          () => _OrderPlacedPage(
                            controller: c,
                            orderNumber: orderId,
                            items: orderItems,
                            subtotal: subtotal,
                            shipping: shipping,
                            total: total,
                            paymentNote: paymentNote,
                            deliveryTitle: selectedAddress?.title ?? 'Address not selected',
                            deliveryRegion: selectedAddress?.addressText ?? '',
                            placedAt: placedAt,
                          ),
                          transition: Transition.rightToLeft,
                        );
                      },
                      child: const Text('Place order'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'By placing an order, you agree that this MVP will create an order record in the database.',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Need help? Manage your addresses from My Account → Addresses.',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentBrandChip extends StatelessWidget {
  const _PaymentBrandChip({required this.assetPath, required this.label});

  final String assetPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Semantics(
        label: label,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            assetPath,
            width: 26,
            height: 18,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(
              Icons.credit_card,
              size: 16,
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacedOrderLine {
  const _PlacedOrderLine({
    required this.name,
    required this.brand,
    required this.qty,
    required this.unitPrice,
  });

  final String name;
  final String brand;
  final int qty;
  final double unitPrice;
}

class _OrderPlacedPage extends StatelessWidget {
  const _OrderPlacedPage({
    required this.controller,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.paymentNote,
    required this.deliveryTitle,
    required this.deliveryRegion,
    required this.placedAt,
  });

  final HomeController controller;
  final int orderNumber;
  final List<_PlacedOrderLine> items;
  final double subtotal;
  final double shipping;
  final double total;
  final String paymentNote;
  final String deliveryTitle;
  final String deliveryRegion;
  final DateTime placedAt;

  String _formatPlacedOn(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day}, ${dt.year}, $hour12:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = items.fold<int>(0, (sum, e) => sum + e.qty);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Order received'),
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order placed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Order number: $orderNumber', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonal(
                      onPressed: () {
                        controller.changeBottomTab(3);
                        Get.until((route) => route.isFirst);
                      },
                      child: const Text('View in My Orders'),
                    ),
                    FilledButton(
                      onPressed: () {
                        controller.changeBottomTab(0);
                        Get.until((route) => route.isFirst);
                      },
                      child: const Text('Continue shopping'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchased items',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('$itemCount item in your order.', style: const TextStyle(color: Colors.black54)),
                const Divider(height: 20),
                ...items.map((i) {
                  final amount = i.unitPrice * i.qty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(i.brand, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('${i.qty}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 16),
                        Text('TRY ${i.unitPrice.toStringAsFixed(2)}'),
                        const SizedBox(width: 16),
                        Text('TRY ${amount.toStringAsFixed(2)}'),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _SummaryRow(label: 'Subtotal', value: subtotal),
                _SummaryRow(label: 'Shipping', value: shipping),
                const Divider(),
                _SummaryRow(label: 'Total', value: total, isBold: true),
                const SizedBox(height: 10),
                const Text('Payment', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(paymentNote, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 10),
                const Text('Delivery', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(deliveryTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (deliveryRegion.trim().isNotEmpty)
                  Text(deliveryRegion, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Text(
                  'Placed on ${_formatPlacedOn(placedAt)}.',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Account',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton.icon(
                onPressed: authController.logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(
            () => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                authController.userName.value.isEmpty
                    ? 'TradeHub user'
                    : authController.userName.value,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _AccountMenuTile(
                  title: 'Profile',
                  icon: Icons.person_outline,
                  onTap: () => Get.to(
                    () => _ProfilePage(controller: controller),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 260),
                  ),
                ),
                _AccountMenuTile(
                  title: 'Orders',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => Get.to(
                    () => _OrdersPage(controller: controller),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 260),
                  ),
                ),
                _AccountMenuTile(
                  title: 'Address',
                  icon: Icons.location_on_outlined,
                  onTap: () => Get.to(
                    () => _AddressPage(controller: controller),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 260),
                  ),
                ),
                _AccountMenuTile(
                  title: 'Cards',
                  icon: Icons.credit_card_outlined,
                  onTap: () => Get.to(
                    () => _CardsPage(controller: controller),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 260),
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
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black12),
        ),
        tileColor: Colors.white,
        leading: Icon(icon, color: Colors.black87),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
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
    final nameFromSession = authController.userName.value.trim();
    final nameFromProfile = controller.profile.value.fullName.trim();
    final initialName = nameFromProfile.isNotEmpty
        ? nameFromProfile
        : nameFromSession;
    final emailFromSession = authController.userEmail.value.trim();
    final emailFromProfile = controller.profile.value.email.trim();
    final initialEmail = emailFromProfile.isNotEmpty
        ? emailFromProfile
        : emailFromSession;
    final genderFromSession = authController.userGender.value.trim();
    final genderFromProfile = controller.profile.value.gender.trim();
    final rawInitialGender = genderFromProfile.isNotEmpty
        ? genderFromProfile
        : genderFromSession;
    String normalizeGenderLabel(String value) {
      final v = value.trim().toLowerCase();
      if (v == 'm' || v == 'male' || v == 'erkek') return 'Male';
      if (v == 'f' || v == 'female' || v == 'kadin' || v == 'kadın') {
        return 'Female';
      }
      return 'Other';
    }
    final initialGender = normalizeGenderLabel(rawInitialGender);
    final birthdateFromSession = authController.userBirthdate.value.trim();
    final birthdateFromProfile = controller.profile.value.birthdate.trim();
    final initialBirthdate = birthdateFromProfile.isNotEmpty
        ? birthdateFromProfile
        : birthdateFromSession;
    final phoneFromSession = authController.userPhone.value.trim();
    final phoneFromProfile = controller.profile.value.phone.trim();
    final initialPhone = phoneFromProfile.isNotEmpty
        ? phoneFromProfile
        : phoneFromSession;
    final nameController = TextEditingController(text: initialName);
    final emailController = TextEditingController(text: initialEmail);
    final genderController = TextEditingController(text: initialGender);
    final birthdateController = TextEditingController(text: initialBirthdate);
    final phoneController = TextEditingController(text: initialPhone);
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
        enabledBorder: OutlineInputBorder(
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nameController.text.isEmpty
                              ? 'TradeHub User'
                              : nameController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emailController.text.isEmpty
                              ? authController.username.value
                              : emailController.text,
                          style: const TextStyle(color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: modernInput(
                label: 'Full name',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: modernInput(
                label: 'Email',
                icon: Icons.alternate_email_rounded,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: initialGender,
                    decoration: modernInput(
                      label: 'Gender',
                      icon: Icons.wc_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      genderController.text = value ?? 'Other';
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: birthdateController,
                    decoration: modernInput(
                      label: 'Birthdate',
                      icon: Icons.cake_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: modernInput(
                label: 'Phone',
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 14),
            Obx(
              () => SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: controller.isSavingProfile.value
                      ? null
                      : () => controller.saveProfile(
                          controller.profile.value.copyWith(
                            fullName: nameController.text,
                            email: emailController.text,
                            gender: genderController.text,
                            birthdate: birthdateController.text,
                            phone: phoneController.text,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    controller.isSavingProfile.value
                        ? 'Saving...'
                        : 'Update profile',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersPage extends StatelessWidget {
  const _OrdersPage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                  ),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Track your latest purchases quickly',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => controller.orders.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Text('No orders yet.'),
                    )
                  : ListView.separated(
                      itemCount: controller.orders.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final order = controller.orders[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blue.shade50,
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${order.id}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${order.statusText} • ${order.dateLabel}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${order.totalPrice.toStringAsFixed(0)} TL',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressPage extends StatefulWidget {
  const _AddressPage({required this.controller});

  final HomeController controller;

  @override
  State<_AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<_AddressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.refreshAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressController = TextEditingController();
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Address')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                  ),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved Addresses',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage delivery locations',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: addressController,
              minLines: 2,
              maxLines: 3,
              decoration: modernInput(
                label: 'New address',
                icon: Icons.home_work_outlined,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await widget.controller.addAddress(addressController.text);
                  addressController.clear();
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Add address'),
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => widget.controller.addresses.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Text('No address added yet.'),
                    )
                  : ListView.separated(
                      itemCount: widget.controller.addresses.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final address = widget.controller.addresses[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.teal.shade50,
                                child: const Icon(
                                  Icons.place_outlined,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      address.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      address.addressText,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    widget.controller.removeAddress(address.id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardsPage extends StatefulWidget {
  const _CardsPage({required this.controller});

  final HomeController controller;

  @override
  State<_CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<_CardsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.refreshCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardNumberController = TextEditingController();
    final cardHolderController = TextEditingController();
    final cardMonthController = TextEditingController();
    final cardYearController = TextEditingController();
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cards')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.credit_card_rounded,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved Cards',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Use your cards faster at checkout',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: cardNumberController,
              keyboardType: TextInputType.number,
              decoration: modernInput(
                label: 'Card number',
                icon: Icons.numbers_rounded,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cardHolderController,
              decoration: modernInput(
                label: 'Card holder',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cardMonthController,
                    keyboardType: TextInputType.number,
                    decoration: modernInput(
                      label: 'MM',
                      icon: Icons.date_range_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: cardYearController,
                    keyboardType: TextInputType.number,
                    decoration: modernInput(
                      label: 'YYYY',
                      icon: Icons.event_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await widget.controller.addCard(
                    cardNo: cardNumberController.text,
                    cardHolder: cardHolderController.text,
                    expMonth: cardMonthController.text,
                    expYear: cardYearController.text,
                  );
                  cardNumberController.clear();
                  cardHolderController.clear();
                  cardMonthController.clear();
                  cardYearController.clear();
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Save card'),
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => widget.controller.savedCards.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Text('No card saved yet.'),
                    )
                  : ListView.separated(
                      itemCount: widget.controller.savedCards.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final card = widget.controller.savedCards[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 19,
                                backgroundColor: Colors.indigo.shade50,
                                child: const Icon(
                                  Icons.credit_card,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${card.brand} •••• ${card.last4}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${card.cardHolder} • ${card.expMonth.toString().padLeft(2, '0')}/${card.expYear.toString().substring(2)}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    widget.controller.removeCard(card.id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    const topCategories = <MapEntry<String, int>>[
      MapEntry('Beauty & Personal Care', 190),
      MapEntry('Home & Living', 140),
      MapEntry('Candy & Sweets', 137),
      MapEntry('Fresh Fruits', 88),
      MapEntry('Fresh Vegetables', 87),
      MapEntry('Pantry & Spices', 74),
      MapEntry('Poultry & Eggs', 74),
      MapEntry('Breakfast & Dairy', 67),
      MapEntry('Toys & Games', 48),
      MapEntry('Fresh Greens', 26),
    ];

    return Obx(
      () {
        final selectedCategory = controller.selectedCategory.value;
        return Container(
          height: 146,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top categories',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  reverse: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: topCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final item = topCategories[index];
                    final isSelected = selectedCategory == item.key;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => controller.changeCategory(item.key),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 156,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.indigo.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.indigo : Colors.black12,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.key,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.indigo : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${item.value} items',
                                style: TextStyle(
                                  color: isSelected ? Colors.indigo : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.controller,
    required this.items,
    required this.favoriteCount,
  });

  final HomeController controller;
  final List<ProductItem> items;
  final int favoriteCount;

  @override
  Widget build(BuildContext context) {
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
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
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
                                  top: 8,
                                  right: 8,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () =>
                                          controller.toggleFavorite(product.id),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x1A000000),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          isFavorite
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          color: isFavorite
                                              ? Colors.red
                                              : Colors.black54,
                                          size: 20,
                                        ),
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
                ),
              ),
            );
          },
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
    final code = p.id;
    final lowerCategory = p.category.toLowerCase();
    final lowerName = p.name.toLowerCase();
    final hasProtection = lowerCategory.contains('electronic') ||
        lowerCategory.contains('elektronik') ||
        lowerName.contains('tv') ||
        lowerName.contains('battery') ||
        lowerName.contains('phone') ||
        lowerName.contains('laptop');
    final together = widget.allProducts.where((e) => e.id != p.id).take(8).toList();
    final similar = widget.allProducts
        .where((e) => e.id != p.id && (e.category == p.category || e.name.split(' ').first == p.name.split(' ').first))
        .take(6)
        .toList();
    final recommended = widget.allProducts.where((e) => e.id != p.id).skip(2).take(6).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Center(
              child: Image.network(
                p.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.image_outlined, size: 64),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Brand: $brand', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          const Text('Sold 235   •   36 orders', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Text('TRY ${p.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              Obx(() {
                final fav = widget.controller.favoriteProductIds.contains(p.id);
                return IconButton(
                  onPressed: () => widget.controller.toggleFavorite(p.id),
                  icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? Colors.red : Colors.black87),
                );
              }),
              const SizedBox(width: 8),
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
                  Get.snackbar('Cart', '$qty item added');
                },
                child: const Text('Add to cart'),
              ),
            ],
          ),
          if (hasProtection) ...[
            const SizedBox(height: 16),
            const Text(
              'TradeHub Protection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Electronics care plan (UI preview).',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            ...[
              (title: '1-year plan', price: 100.0),
              (title: '2-year plan', price: 160.0),
              (title: '3-year plan', price: 220.0),
            ].map(
              (plan) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
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
                            plan.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Protection coverage for eligible defects.',
                            style: TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TRY ${plan.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => Get.snackbar('Protection', '${plan.title} added'),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text('Product details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code: $code'),
                Text('Brand: $brand'),
                Text('Category: ${p.category}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Frequently bought together', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Text('Based on items that appear in the same orders.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          ...together.map(
            (e) => _MiniProductRow(
              item: e,
              onAdd: () {
                widget.controller.addToCart(e.id);
                Get.snackbar('Added', e.name);
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('Similar products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Text('Same brand or category.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          ...similar.map(
            (e) => _MiniProductRow(
              item: e,
              onAdd: () {
                widget.controller.addToCart(e.id);
                Get.snackbar('Added', e.name);
              },
              showMeta: true,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Recommended for you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Text('Popular items across the store.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          ...recommended.map(
            (e) => _MiniProductRow(
              item: e,
              onAdd: () {
                widget.controller.addToCart(e.id);
                Get.snackbar('Added', e.name);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProductRow extends StatelessWidget {
  const _MiniProductRow({
    required this.item,
    required this.onAdd,
    this.showMeta = false,
  });

  final ProductItem item;
  final VoidCallback onAdd;
  final bool showMeta;

  @override
  Widget build(BuildContext context) {
    final brand = item.name.split(' ').first.toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.image_outlined),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (showMeta)
                  Text('Code: ${item.id} • Brand: $brand', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Text('TRY ${item.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(onPressed: onAdd, child: const Text('Add')),
        ],
      ),
    );
  }
}
