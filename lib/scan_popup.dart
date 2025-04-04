/// A popup widget that uses the device camera to scan a barcode,
/// fetches product data (name and sugar content) from the Open Food Facts API,
/// and returns the result to the calling widget.
/// If scanning fails or the product is not found, the popup shows an error
/// and allows the user to close the scanner.

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScanPopup extends StatefulWidget {
  const ScanPopup({super.key});

  @override
  State<ScanPopup> createState() => _ScanPopupState();
}

// Controller to manage the camera and scanning state
class _ScanPopupState extends State<ScanPopup> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isLoading = false;
  bool _hasScanned = false; // Prevents multiple barcode scans at once

  /// Fetches product data from Open Food Facts API using the scanned barcode.
  /// If successful, returns product name and sugar value to the previous screen.
  Future<void> _fetchProductData(String barcode) async {
    setState(() => _isLoading = true);

    final url =
        'https://world.openfoodfacts.net/api/v2/product/$barcode?fields=product_name,nutriments';

    try {
      final response = await http.get(Uri.parse(url));

      // if the widget was removed from the tree during fetch, abort
      if (!mounted) return;

      if (response.statusCode == 200) {
        // Parse JSON response
        final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
        final product = data['product'];
        final name = product['product_name']?.toString() ?? 'Unknown';
        final sugar =
            product['nutriments']?['sugars_100g']?.toString() ?? '';

        // Stop the camera after successful scan
        _controller.stop();

        // Return the result back to the caller
        if (Navigator.canPop(context)) {
          Navigator.pop(context, {
            'name': name,
            'sugar': sugar,
          });
        }
      } else {
        _controller.stop();
        _closeWithError("Product not found.");
      }
    } catch (e) {
      _controller.stop();
      _closeWithError("Fetch error: $e");
    }
  }

  /// Shows a snackbar with an error message and closes the popup
  void _closeWithError(String message) {
    if (Navigator.canPop(context)) Navigator.pop(context, null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  /// Triggered when a barcode is detected by the scanner.
  /// Ensures only the first barcode is handled.
  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue ?? '';
    if (barcode.isNotEmpty) {
      setState(() => _hasScanned = true);
      _fetchProductData(barcode);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      child: AspectRatio(
        aspectRatio: 0.75, // Adjusts scanner size
        child: Stack(
          children: [
            // Barcode scanner preview
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
            // Shows loading spinner during data fetch
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            // Close button in top-right corner
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  _controller.stop();
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context, null); // Cancel the scan
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
