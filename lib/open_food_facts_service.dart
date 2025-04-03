import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  // This endpoint is the "Get A Product By Barcode" endpoint for production
  // For more info, see: https://world.openfoodfacts.net/data
  static const String _baseUrl = 'https://world.openfoodfacts.net/api/v2/product';

  static Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final String url = '$_baseUrl/$barcode?fields=product_name,nutriscore_data,nutrition_grades,nutriments';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 1) {
          // Product found
          return jsonData['product'];
        } else {
          // Product not found in OFF database
          return null;
        }
      } else {
        // Error from server or no network
        return null;
      }
    } catch (e) {
      // Exception (e.g., network error)
      rethrow;
    }
  }
}
