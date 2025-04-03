import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScanPopup extends StatefulWidget {
  const ScanPopup({super.key});

  @override
  State<ScanPopup> createState() => _ScanPopupState();
}

class _ScanPopupState extends State<ScanPopup> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isLoading = false;
  bool _hasScanned = false;

  Future<void> _fetchProductData(String barcode) async {
    setState(() => _isLoading = true);

    final url =
        'https://world.openfoodfacts.net/api/v2/product/$barcode?fields=product_name,nutriments';

    try {
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
        final product = data['product'];
        final name = product['product_name']?.toString() ?? 'Unknown';
        final sugar =
            product['nutriments']?['sugars_100g']?.toString() ?? '';

        _controller.stop();

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

  void _closeWithError(String message) {
    if (Navigator.canPop(context)) Navigator.pop(context, null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

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
        aspectRatio: 0.75,
        child: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  _controller.stop();
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context, null);
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
