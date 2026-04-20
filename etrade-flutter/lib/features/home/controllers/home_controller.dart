import 'package:get/get.dart';

import '../data/product_repository.dart';
import '../models/product_item.dart';

/// Home page business logic (filters, favorites, and product state).
class HomeController extends GetxController {
  HomeController({ProductRepository? repository})
    : _repository = repository ?? ProductRepository();

  final ProductRepository _repository;
  final categories = <String>[
    'Tum',
    'Elektronik',
    'Moda',
    'Ev & Yasam',
    'Spor',
    'Kozmetik',
  ].obs;

  final selectedCategory = 'Tum'.obs;
  final searchText = ''.obs;
  final products = <ProductItem>[].obs;
  final favoriteProductIds = <int>{}.obs;
  final selectedBottomIndex = 0.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  /// Fetches products from repository and updates UI states.
  Future<void> loadProducts() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final fetchedProducts = await _repository.getProducts();
      products.assignAll(fetchedProducts);
      _syncCategories(fetchedProducts);
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
      final categoryMatch =
          selectedCategory.value == 'Tum' ||
          product.category.toLowerCase() ==
              selectedCategory.value.toLowerCase();
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

  void toggleFavorite(int productId) {
    if (favoriteProductIds.contains(productId)) {
      favoriteProductIds.remove(productId);
      return;
    }
    favoriteProductIds.add(productId);
  }

  void changeBottomTab(int index) {
    selectedBottomIndex.value = index;
  }

  void _syncCategories(List<ProductItem> list) {
    final dynamicCategories = list.map((p) => p.category).toSet().toList()
      ..sort();
    categories.assignAll(['Tum', ...dynamicCategories]);
  }
}
