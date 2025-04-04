/// A service class to interact with the Open Food Facts API.
/// This class allows fetching detailed product information by barcode,
/// including product name, nutrition grade, sugar content, and NutriScore data.

import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  // Base URL for the Open Food Facts API
  static const String _baseUrl = 'https://world.openfoodfacts.net/api/v2/product';

  /// Fetches product details using the barcode.
  /// Returns a map containing product data if found, or null otherwise.
  static Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    // Construct the full request URL
    final String url = '$_baseUrl/$barcode?fields=product_name,nutriscore_data,nutrition_grades,nutriments';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 1) {
          // Product found
          return jsonData['product'];
        } else {
          // Product not found
          return null;
        }
      } else {
        // Error from server or no network
        return null;
      }
    } catch (e) {
      // Handle any exception
      rethrow;
    }
  }
}
