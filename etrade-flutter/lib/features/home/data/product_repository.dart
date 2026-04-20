import '../models/product_item.dart';
import 'product_api_service.dart';

/// Abstracts data source and prepares products for controller.
class ProductRepository {
  ProductRepository({ProductApiService? apiService})
    : _apiService = apiService ?? ProductApiService();

  final ProductApiService _apiService;

  Future<List<ProductItem>> getProducts() {
    return _apiService.fetchProducts();
  }
}
