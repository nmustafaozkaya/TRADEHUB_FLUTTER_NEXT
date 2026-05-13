import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/order_status.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/account_api_service.dart';
import '../data/product_repository.dart';
import '../models/account_models.dart';
import '../models/product_item.dart';

/// Home page business logic (filters, favorites, and product state).
class HomeController extends GetxController {
  HomeController({ProductRepository? repository})
    : _repository = repository ?? ProductRepository();

  final ProductRepository _repository;
  final AccountApiService _accountApiService = AccountApiService();
  static const _profileNameKey = 'profile_name';
  static const _profileEmailKey = 'profile_email';
  static const _profileGenderKey = 'profile_gender';
  static const _profileBirthdateKey = 'profile_birthdate';
  static const _profilePhoneKey = 'profile_phone';
  /// Eight shop tiles + All — same order/labels as `etrade-next/src/lib/shopCategories.ts`.
  static const shopCategoryTiles = <String>[
    'Fresh Produce',
    'Beauty & Personal Care',
    'Home & Living',
    'Snacks & Confectionery',
    'Pantry & Staples',
    'Meat, Poultry & Seafood',
    'Dairy, Cheese & Eggs',
    'Toys & Games',
  ];

  static const bestsellerCategory = 'Bestseller';
  final categories = <String>['All', bestsellerCategory, ...shopCategoryTiles].obs;

  final selectedCategory = 'All'.obs;
  final searchText = ''.obs;
  final products = <ProductItem>[].obs;
  final favoriteProductIds = <int>{}.obs;
  final cartQuantities = <int, int>{}.obs;
  final cartProtectionPrices = <int, double>{}.obs;
  final selectedBottomIndex = 0.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final profile = UserProfile.empty().obs;
  final addresses = <UserAddress>[].obs;
  final savedCards = <SavedCardItem>[].obs;
  final orders = <UserOrderItem>[].obs;
  final reviews = <UserReviewItem>[].obs;
  final isOrdersLoading = false.obs;
  final isReviewsLoading = false.obs;
  final ordersErrorMessage = ''.obs;
  final reviewsErrorMessage = ''.obs;
  final isSavingProfile = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadAccountModules();
  }
  

  /// Fetches products from repository and updates UI states.
  /// Category filter uses the web API (`shopCategories.ts` / SQL) — same buckets as `/items?category=`.
  Future<void> loadProducts() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final selected = selectedCategory.value.trim().toLowerCase();
      final String? cat =
          selected == 'all' ? null : selectedCategory.value;
      final fetchedProducts = await _repository.getProducts(category: cat);
      products.assignAll(fetchedProducts);
      await _loadFavorites();
    } catch (e) {
      errorMessage.value = 'Could not load products. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Search only; category is applied server-side in [loadProducts].
  List<ProductItem> get filteredProducts {
    final normalizedSearch = searchText.value.trim().toLowerCase();
    final base = products.toList();

    if (normalizedSearch.isEmpty) return base;
    return base.where((product) => product.name.toLowerCase().contains(normalizedSearch)).toList();
  }

  void changeCategory(String category) {
    selectedCategory.value = category;
    loadProducts();
  }

  void updateSearch(String text) {
    searchText.value = text;
  }

  Future<void> toggleFavorite(int productId) async {
    final ids = await _accountApiService.toggleFavorite(
      itemId: productId,
      userId: _currentUserId(),
      username: _currentLogin(),
    );
    if (ids.isNotEmpty) {
      favoriteProductIds
        ..clear()
        ..addAll(ids);
      favoriteProductIds.refresh();
      return;
    }
    if (favoriteProductIds.contains(productId)) {
      favoriteProductIds.remove(productId);
      favoriteProductIds.refresh();
      return;
    }
    favoriteProductIds.add(productId);
    favoriteProductIds.refresh();
  }

  void changeBottomTab(int index) {
    selectedBottomIndex.value = index;
  }

  void addToCart(int productId, {int qty = 1}) {
    if (qty <= 0) return;
    final current = cartQuantities[productId] ?? 0;
    cartQuantities[productId] = current + qty;
    cartQuantities.refresh();
  }

  void decreaseCartItem(int productId) {
    final current = cartQuantities[productId] ?? 0;
    if (current <= 1) {
      cartQuantities.remove(productId);
      cartQuantities.refresh();
      return;
    }
    cartQuantities[productId] = current - 1;
    cartQuantities.refresh();
  }

  void removeFromCart(int productId) {
    cartQuantities.remove(productId);
    cartProtectionPrices.remove(productId);
    cartQuantities.refresh();
    cartProtectionPrices.refresh();
  }

  void clearCart() {
    cartQuantities.clear();
    cartProtectionPrices.clear();
    cartQuantities.refresh();
    cartProtectionPrices.refresh();
  }

  void setCartProtectionPlan(int productId, double? planPrice) {
    if (planPrice == null || planPrice <= 0) {
      cartProtectionPrices.remove(productId);
      cartProtectionPrices.refresh();
      return;
    }
    cartProtectionPrices[productId] = planPrice;
    cartProtectionPrices.refresh();
  }

  double getCartProtection(int productId) {
    return cartProtectionPrices[productId] ?? 0;
  }

  void checkoutCart() {
    if (cartQuantities.isEmpty) {
      Get.snackbar('Checkout', 'Your cart is empty.');
      return;
    }
    double subtotal = 0;
    for (final entry in cartQuantities.entries) {
      ProductItem? product;
      for (final p in products) {
        if (p.id == entry.key) {
          product = p;
          break;
        }
      }
      if (product == null) continue;
      subtotal += product.price * entry.value;
    }
    final protection = cartProtectionPrices.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final total = subtotal + protection;
    var nextId = 2001;
    if (orders.isNotEmpty) {
      final maxId = orders.map((o) => o.id).reduce((a, b) => a > b ? a : b);
      nextId = maxId + 1;
    }
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    orders.insert(
      0,
      UserOrderItem(
        id: nextId,
        totalPrice: total,
        status: OrderStatus.placed,
        statusText: OrderStatus.label(OrderStatus.placed),
        dateLabel: '${now.year}-$month-$day',
      ),
    );
    clearCart();
    Get.snackbar('Checkout', 'Order created in MVP flow.');
  }
Future<int?> createOrder({
  required int addressId,
  required String paymentMethod,
  int? cardId,
  Map<String, dynamic>? newCardDetails,
}) async {
  if (cartQuantities.isEmpty) {
    Get.snackbar('Checkout', 'Your cart is empty.');
    return null;
  }

  if (newCardDetails != null && newCardDetails['saveForAccount'] == true) {
    final holder = (newCardDetails['holderName'] ?? '').toString();
    final number = (newCardDetails['number'] ?? '').toString();
    final expiry = (newCardDetails['expiry'] ?? '').toString();
    final parts = expiry.split('/');
    final month = parts.isNotEmpty ? parts.first : '';
    final year = parts.length > 1 ? parts.last : '';
    await addCard(
      cardNo: number,
      cardHolder: holder,
      expMonth: month,
      expYear: year,
    );
  }

  // Cart lines'ı API formatına çevir
  final lines = <Map<String, dynamic>>[];
  for (final entry in cartQuantities.entries) {
    ProductItem? product;
    for (final p in products) {
      if (p.id == entry.key) {
        product = p;
        break;
      }
    }
    if (product == null) continue;
    lines.add({
      'itemId': product.id,
      'name': product.name,
      'unitPrice': product.price,
      'qty': entry.value,
    });
  }

  final orderId = await _accountApiService.createOrder(
    addressId: addressId,
    paymentMethod: paymentMethod,
    lines: lines,
    userId: _currentUserId(),
    username: _currentLogin(),
  );

  if (orderId != null) {
    clearCart();
    await _loadOrders();
  }

  return orderId;
}
  Future<void> loadAccountModules() async {
    await _waitForAuthReady();
    await _loadLocalProfile();
    await _loadAddresses();
    await _loadCards();
    await _loadOrders();
  }

  Future<void> _waitForAuthReady() async {
    if (!Get.isRegistered<AuthController>()) return;
    final auth = Get.find<AuthController>();
    if (auth.isReady.value) return;
    try {
      await auth.isReady.stream.firstWhere((ready) => ready);
    } catch (_) {
      // Ignore if auth readiness stream is closed or unavailable.
    }
  }

  Future<void> saveProfile(UserProfile newProfile) async {
    isSavingProfile.value = true;
    try {
      final ok = await _accountApiService.updateProfile(
        newProfile,
        userId: _currentUserId(),
        username: _currentLogin(),
      );
      if (ok) {
        profile.value = newProfile;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileNameKey, newProfile.fullName);
        await prefs.setString(_profileEmailKey, newProfile.email);
        await prefs.setString(_profileGenderKey, newProfile.gender);
        await prefs.setString(_profileBirthdateKey, newProfile.birthdate);
        await prefs.setString(_profilePhoneKey, newProfile.phone);
        if (Get.isRegistered<AuthController>()) {
          await Get.find<AuthController>().syncProfileFields(
            nameSurname: newProfile.fullName,
            email: newProfile.email,
            gender: newProfile.gender,
            birthdate: newProfile.birthdate,
            phone: newProfile.phone,
          );
        }
        Get.snackbar(
          'Profile',
          'Your profile has been saved.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF34D399),
          colorText: const Color(0xFF0B1020),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Profile',
          'Could not save profile. Check your connection and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFF87171),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (_) {
      Get.snackbar(
        'Profile',
        'Could not save profile. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF87171),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSavingProfile.value = false;
    }
  }

  Future<void> addAddress(String addressText) async {
    final text = addressText.trim();
    if (text.length < 5) return;
    final saved = await _accountApiService.createAddress(
      text,
      userId: _currentUserId(),
      username: _currentLogin(),
    );
    if (saved) {
      await _loadAddresses();
      return;
    }
    Get.snackbar('Address', 'Address could not be saved.');
  }

  Future<void> removeAddress(int id) async {
    final deleted = await _accountApiService.deleteAddress(
      id,
      userId: _currentUserId(),
      username: _currentLogin(),
    );
    if (deleted) {
      await _loadAddresses();
      return;
    }
    Get.snackbar('Address', 'Address could not be deleted.');
  }

  Future<void> addCard({
    required String cardNo,
    required String cardHolder,
    required String expMonth,
    required String expYear,
  }) async {
    final digits = cardNo.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 12) return;
    final month = int.tryParse(expMonth) ?? 1;
    final year = int.tryParse(expYear) ?? DateTime.now().year;
    final saved = await _accountApiService.createCard(
      cardNumber: digits,
      cardHolder: cardHolder.trim().isEmpty ? 'Card holder' : cardHolder.trim(),
      expMonth: month,
      expYear: year,
      userId: _currentUserId(),
      username: _currentLogin(),
    );
    if (saved) {
      await _loadCards();
      return;
    }
    Get.snackbar('Cards', 'Card could not be saved.');
  }

  Future<void> removeCard(int id) async {
    final deleted = await _accountApiService.deleteCard(
      id,
      userId: _currentUserId(),
      username: _currentLogin(),
    );
    if (deleted) {
      await _loadCards();
      return;
    }
    Get.snackbar('Cards', 'Card could not be deleted.');
  }

  Future<void> refreshAddresses() async {
    await _loadAddresses();
  }

  Future<void> refreshCards() async {
    await _loadCards();
  }

  Future<void> refreshFavorites() async {
    await _loadFavorites();
  }

  Future<void> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final fullName = prefs.getString(_profileNameKey) ?? '';
    final email = prefs.getString(_profileEmailKey) ?? '';
    final gender = prefs.getString(_profileGenderKey) ?? '';
    final birthdate = prefs.getString(_profileBirthdateKey) ?? '';
    final phone = prefs.getString(_profilePhoneKey) ?? '';
    profile.value = UserProfile(
      fullName: fullName.isNotEmpty ? fullName : (auth?.userName.value ?? ''),
      email: email.isNotEmpty ? email : (auth?.userEmail.value ?? ''),
      gender: gender.isNotEmpty ? gender : (auth?.userGender.value ?? ''),
      birthdate: birthdate.isNotEmpty
          ? birthdate
          : (auth?.userBirthdate.value ?? ''),
      phone: phone.isNotEmpty ? phone : (auth?.userPhone.value ?? ''),
    );
  }

  Future<void> _loadAddresses() async {
    final fetched = await _accountApiService.fetchAddresses(
      userId: _currentUserId(),
      username: _currentLogin(),
    );
    addresses.assignAll(fetched);
  }

  Future<void> _loadCards() async {
    final fetched = await _accountApiService.fetchCards(
      userId: _currentUserId(),
      username: _currentLogin(),
    );
    savedCards.assignAll(fetched);
  }

  Future<void> _loadFavorites() async {
    final ids = await _accountApiService.fetchFavoriteIds(
      userId: _currentUserId(),
      username: _currentLogin(),
    );
    favoriteProductIds
      ..clear()
      ..addAll(ids);
    favoriteProductIds.refresh();
  }

  Future<UserOrderDetail?> fetchOrderDetail(int orderId) async {
    return _accountApiService.fetchOrderDetail(
      orderId,
      userId: _currentUserId(),
      username: _currentLogin(),
    );
  }

  /// Customer confirms package received (shipped or delivered → completed).
  Future<bool> confirmOrderDelivery(int orderId) async {
    return _accountApiService.confirmOrderDelivery(
      orderId,
      userId: _currentUserId(),
      username: _currentLogin(),
    );
  }

  Future<bool> createReviewForItem({
    required int itemId,
    required int rating,
    required String comment,
  }) async {
    return _accountApiService.createItemReview(
      itemId: itemId,
      rating: rating,
      comment: comment,
      userId: _currentUserId(),
      username: _currentLogin(),
    );
  }

  Future<void> loadReviews() async {
    isReviewsLoading.value = true;
    reviewsErrorMessage.value = '';
    try {
      final list = await _accountApiService.fetchReviews(
        userId: _currentUserId(),
        username: _currentLogin(),
      );
      reviews.assignAll(list);
    } catch (_) {
      reviews.clear();
      reviewsErrorMessage.value = 'Could not load reviews. Please try again.';
    } finally {
      isReviewsLoading.value = false;
    }
  }

  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return _accountApiService.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
      userId: _currentUserId(),
      username: _currentLogin(),
    );
  }


  Future<void> _loadOrders() async {
    isOrdersLoading.value = true;
    ordersErrorMessage.value = '';
    try {
      final apiOrders = await _accountApiService.fetchOrders(
        userId: _currentUserId(),
        username: _currentLogin(),
      );
      if (apiOrders == null) {
        orders.clear();
        ordersErrorMessage.value = 'Could not load orders. Please try again.';
        return;
      }
      orders.assignAll(apiOrders);
    } catch (error) {
      orders.clear();
      ordersErrorMessage.value = 'Could not load orders. Please try again.';
    } finally {
      isOrdersLoading.value = false;
    }
  }

  int? _currentUserId() {
    if (!Get.isRegistered<AuthController>()) return null;
    final id = Get.find<AuthController>().userId.value;
    return id > 0 ? id : null;
  }

  String? _currentLogin() {
    if (!Get.isRegistered<AuthController>()) return null;
    final auth = Get.find<AuthController>();
    final username = auth.username.value.trim();
    if (username.isNotEmpty) return username;
    final email = auth.userEmail.value.trim();
    return email.isEmpty ? null : email;
  }
}
