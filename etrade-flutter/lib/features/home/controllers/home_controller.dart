import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final categories = <String>[
    'All',
    'Beauty & Personal Care',
    'Home & Living',
    'Candy & Sweets',
    'Fresh Fruits',
    'Fresh Vegetables',
    'Pantry & Spices',
    'Poultry & Eggs',
    'Breakfast & Dairy',
    'Toys & Games',
    'Fresh Greens',
  ].obs;

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
  final isSavingProfile = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadAccountModules();
  }

  /// Fetches products from repository and updates UI states.
  Future<void> loadProducts() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final fetchedProducts = await _repository.getProducts();
      products.assignAll(fetchedProducts);
      _syncCategories(fetchedProducts);
      await _loadFavorites();
    } catch (e) {
      errorMessage.value = 'Urunler yuklenemedi. Lutfen tekrar dene.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Products shown according to selected category and search query.
  List<ProductItem> get filteredProducts {
    final normalizedSearch = searchText.value.trim().toLowerCase();
    return products.where((product) {
      final categoryMatch = _matchesSelectedCategory(product.category);
      final searchMatch =
          normalizedSearch.isEmpty ||
          product.name.toLowerCase().contains(normalizedSearch);
      return categoryMatch && searchMatch;
    }).toList();
  }

  void changeCategory(String category) {
    selectedCategory.value = category;
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
        statusText: 'Received',
        dateLabel: '${now.year}-$month-$day',
      ),
    );
    clearCart();
    Get.snackbar('Checkout', 'Order created in MVP flow.');
  }

  Future<void> loadAccountModules() async {
    await _loadLocalProfile();
    await _loadAddresses();
    await _loadCards();
    await _loadOrders();
  }

  Future<void> saveProfile(UserProfile newProfile) async {
    isSavingProfile.value = true;
    try {
      profile.value = newProfile;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileNameKey, newProfile.fullName);
      await prefs.setString(_profileEmailKey, newProfile.email);
      await prefs.setString(_profileGenderKey, newProfile.gender);
      await prefs.setString(_profileBirthdateKey, newProfile.birthdate);
      await prefs.setString(_profilePhoneKey, newProfile.phone);
      await _accountApiService.updateProfile(
        newProfile,
        userId: _currentUserId(),
        username: _currentLogin(),
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

  void _syncCategories(List<ProductItem> list) {}

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

  Future<void> _loadOrders() async {
    final apiOrders = await _accountApiService.fetchOrders(
      userId: _currentUserId(),
      username: _currentLogin(),
    );
    if (apiOrders.isNotEmpty) {
      orders.assignAll(apiOrders);
      return;
    }
    orders.assignAll([
      UserOrderItem(
        id: 1001,
        totalPrice: 1249,
        statusText: 'Delivered',
        dateLabel: '2026-04-19',
      ),
      UserOrderItem(
        id: 1002,
        totalPrice: 399,
        statusText: 'Preparing',
        dateLabel: '2026-04-20',
      ),
    ]);
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

  bool _matchesSelectedCategory(String rawCategory) {
    final selected = selectedCategory.value.toLowerCase();
    if (selected == 'all') return true;
    final category = rawCategory.toLowerCase();

    final aliases = <String, List<String>>{
      'beauty & personal care': ['beauty', 'personal care', 'kozmetik', 'bakim'],
      'home & living': ['home', 'living', 'ev', 'yasam', 'mobilya'],
      'candy & sweets': ['candy', 'sweet', 'seker', 'tatli', 'cikolata'],
      'fresh fruits': ['fruit', 'meyve'],
      'fresh vegetables': ['vegetable', 'sebze'],
      'pantry & spices': ['pantry', 'spice', 'baharat', 'erzak', 'bakliyat'],
      'poultry & eggs': ['poultry', 'egg', 'tavuk', 'yumurta'],
      'breakfast & dairy': ['breakfast', 'dairy', 'kahvalti', 'sut', 'peynir'],
      'toys & games': ['toy', 'game', 'oyuncak', 'oyun'],
      'fresh greens': ['green', 'yesillik', 'salata'],
    };

    final keywords = aliases[selected];
    if (keywords == null || keywords.isEmpty) {
      return category.contains(selected);
    }
    return keywords.any(category.contains);
  }
}
