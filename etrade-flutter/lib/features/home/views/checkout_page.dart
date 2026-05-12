import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/tradehub_theme.dart';
import '../controllers/home_controller.dart';
import '../models/product_item.dart';
import 'address_page.dart';
import 'home_screen.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({required this.controller, super.key});

  final HomeController controller;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

enum _CheckoutPaymentMethod { card, cashOnDelivery }

class _CheckoutPageState extends State<CheckoutPage> {
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

    return Theme(
      data: Theme.of(context).copyWith(
        listTileTheme: const ListTileThemeData(
          textColor: TradeHubColors.textPrimary,
          iconColor: TradeHubColors.textMuted,
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TradeHubColors.primary;
            }
            return TradeHubColors.textMuted;
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: TradeHubColors.surface,
          labelStyle: const TextStyle(color: TradeHubColors.textMuted),
          hintStyle: TextStyle(color: TradeHubColors.textMuted.withValues(alpha: 0.8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: TradeHubColors.primary, width: 1.5),
          ),
        ),
      ),
      child: Scaffold(
      backgroundColor: TradeHubColors.bg,
      appBar: AppBar(
        title: const Text('Secure checkout'),
        backgroundColor: TradeHubColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: TradeHubColors.textPrimary,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- Adres Bölümü ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TradeHubColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 20, color: TradeHubColors.accent),
                            const SizedBox(width: 8),
                            const Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: TradeHubColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Get.to(
                                () => AddressPage(controller: c),
                                transition: Transition.rightToLeft,
                              ),
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (c.addresses.isEmpty)
                          const Text(
                            'No address saved. Please add an address.',
                            style: TextStyle(color: TradeHubColors.danger),
                          )
                        else
                          RadioGroup<int>(
                            groupValue: selectedAddressId,
                            onChanged: (value) => setState(() => selectedAddressId = value),
                            child: Column(
                              children: c.addresses
                                  .map(
                                    (addr) => RadioListTile<int>(
                                      value: addr.id,
                                      title: Text(
                                        addr.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        addr.addressText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Ödeme Yöntemi Bölümü ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TradeHubColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.payment_outlined, size: 20, color: TradeHubColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Payment Method',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: TradeHubColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RadioGroup<_CheckoutPaymentMethod>(
                          groupValue: paymentMethod,
                          onChanged: (value) => setState(() => paymentMethod = value!),
                          child: Column(
                            children: const [
                              RadioListTile<_CheckoutPaymentMethod>(
                                value: _CheckoutPaymentMethod.card,
                                title: Text('Credit/Debit Card'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              RadioListTile<_CheckoutPaymentMethod>(
                                value: _CheckoutPaymentMethod.cashOnDelivery,
                                title: Text('Cash on Delivery'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Kart Bilgileri Bölümü ---
                  if (paymentMethod == _CheckoutPaymentMethod.card) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TradeHubColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Card Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: TradeHubColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              // Saved / New toggle
                              RadioGroup<bool>(
                                groupValue: useNewCard,
                                onChanged: (value) => setState(() => useNewCard = value!),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text('Saved', style: TextStyle(color: TradeHubColors.textMuted)),
                                    Radio<bool>(value: false),
                                    Text('New', style: TextStyle(color: TradeHubColors.textMuted)),
                                    Radio<bool>(value: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (!useNewCard && c.savedCards.isNotEmpty)
                            RadioGroup<int>(
                              groupValue: selectedSavedCardId,
                              onChanged: (value) => setState(() => selectedSavedCardId = value),
                              child: Column(
                                children: c.savedCards
                                    .map(
                                      (card) => RadioListTile<int>(
                                        value: card.id,
                                        title: Row(
                                          children: [
                                            Image.asset(
                                              _cardBrandAsset(card.brand),
                                              height: 24,
                                              width: 36,
                                              fit: BoxFit.contain,
                                            ),
                                            const SizedBox(width: 8),
                                            Text('${_cardBrandLabel(card.brand)} ****${card.last4}'),
                                          ],
                                        ),
                                        subtitle: Text(card.cardHolder),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    )
                                    .toList(),
                              ),
                            )
                          else ...[
                            TextField(
                              controller: cardHolderController,
                              style: const TextStyle(color: TradeHubColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Card Holder Name',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: cardNumberController,
                              style: const TextStyle(color: TradeHubColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Card Number',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: expiryController,
                                    style: const TextStyle(color: TradeHubColors.textPrimary),
                                    decoration: const InputDecoration(
                                      labelText: 'Expiry (MM/YY)',
                                    ),
                                    keyboardType: TextInputType.datetime,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: cvvController,
                                    style: const TextStyle(color: TradeHubColors.textPrimary),
                                    decoration: const InputDecoration(
                                      labelText: 'CVV',
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              value: saveCardForAccount,
                              onChanged: (v) => setState(() => saveCardForAccount = v ?? false),
                              title: const Text('Save card for future purchases'),
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Sipariş Özeti ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TradeHubColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: TradeHubColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: 'Subtotal',
                          value: 'TRY ${subtotal.toStringAsFixed(2)}',
                        ),
                        _SummaryRow(
                          label: 'Protection',
                          value: 'TRY ${protection.toStringAsFixed(2)}',
                        ),
                        _SummaryRow(
                          label: shipping == 0
                              ? 'Shipping (free over TRY ${shippingThreshold.toStringAsFixed(0)})'
                              : 'Shipping',
                          value: 'TRY ${shipping.toStringAsFixed(2)}',
                        ),
                        _SummaryRow(
                          label: 'Discount',
                          value: 'TRY ${discount.toStringAsFixed(2)}',
                        ),
                        Divider(color: Colors.white.withValues(alpha: 0.08)),
                        _SummaryRow(
                          label: 'Total',
                          value: 'TRY ${total.toStringAsFixed(2)}',
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Alt Buton
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TradeHubColors.surface,
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (selectedAddressId == null) {
                      Get.snackbar('Error', 'Please select a delivery address');
                      return;
                    }
                    if (paymentMethod == _CheckoutPaymentMethod.card) {
                      if (!useNewCard && selectedSavedCardId == null) {
                        Get.snackbar(
                          'Error',
                          'Please select a saved card or enter new card details',
                        );
                        return;
                      }
                      if (useNewCard &&
                          (cardHolderController.text.isEmpty ||
                              cardNumberController.text.isEmpty ||
                              expiryController.text.isEmpty ||
                              cvvController.text.isEmpty)) {
                        Get.snackbar('Error', 'Please fill all card details');
                        return;
                      }
                    }

                    final orderId = await c.createOrder(
                      addressId: selectedAddressId!,
                      paymentMethod: paymentMethod == _CheckoutPaymentMethod.card
                          ? 'card'
                          : 'cash_on_delivery',
                      cardId: paymentMethod == _CheckoutPaymentMethod.card && !useNewCard
                          ? selectedSavedCardId
                          : null,
                      newCardDetails: paymentMethod == _CheckoutPaymentMethod.card && useNewCard
                          ? {
                              'holderName': cardHolderController.text,
                              'number': cardNumberController.text,
                              'expiry': expiryController.text,
                              'cvv': cvvController.text,
                              'saveForAccount': saveCardForAccount,
                            }
                          : null,
                    );

                    if (orderId != null) {
                      Get.off(
                        () => _OrderPlacedPage(orderId: orderId, controller: c),
                        transition: Transition.fadeIn,
                      );
                    } else {
                      Get.snackbar('Error', 'Failed to place order');
                    }
                  },
                  child: const Text('Place Order'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary row helper
// ---------------------------------------------------------------------------
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: TradeHubColors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order placed page
// ---------------------------------------------------------------------------
class _OrderPlacedPage extends StatelessWidget {
  const _OrderPlacedPage({required this.orderId, required this.controller});
  final int orderId;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeHubColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: TradeHubColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Color(0xFF0B1020), size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Order Placed!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: TradeHubColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #$orderId has been\nsuccessfully placed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: TradeHubColors.textMuted.withValues(alpha: 0.95)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      controller.changeBottomTab(0);
                      Get.offAll(() => const HomeScreen());
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: TradeHubColors.primaryDeep,
                      foregroundColor: TradeHubColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Continue Shopping',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}