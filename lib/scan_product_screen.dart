import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScanProductScreen extends StatefulWidget {
  const ScanProductScreen({super.key});

  @override
  State<ScanProductScreen> createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  String _scannedBarcode = '';
  String _productName = '';
  String _nutriScore = '';
  bool _isLoading = false;
  String _error = '';

  // This function calls the Open Food Facts "Get Product By Barcode" endpoint.
  Future<void> _fetchProductData(String barcode) async {
    setState(() {
      _isLoading = true;
      _error = '';
      _productName = '';
      _nutriScore = '';
    });

    final url = 'https://world.openfoodfacts.net/api/v2/product/$barcode?fields=product_name,nutrition_grades';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          // Product found
          final product = data['product'];
          setState(() {
            _productName = product['product_name'] ?? 'Unknown';
            _nutriScore = product['nutrition_grades'] ?? 'Not available';
          });
        } else {
          setState(() {
            _error = 'Product not found in Open Food Facts database.';
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    // If multiple barcodes are detected, we can handle them, but usually there's just one.
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        // We got a valid barcode. Let's stop the scanner, fetch product data.
        setState(() {
          _scannedBarcode = rawValue;
        });

        // We can pause the scanner so it doesn't keep scanning.
        _controller?.stop();

        // Fetch product data from OFF
        _fetchProductData(rawValue);
        break; // Just handle the first scanned code
      }
    }
  }

  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan a Product'),
      ),
      body: Column(
        children: [
          // Camera preview widget
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller!,
                  onDetect: _onDetect,
                ),
                // You can add an overlay or bounding box here if desired
              ],
            ),
          ),

          // Results or loading states
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            )
          else if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error, style: const TextStyle(color: Colors.red)),
            )
          else if (_scannedBarcode.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Scan a barcode to see product info.'),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text('Scanned Barcode: $_scannedBarcode'),
                    const SizedBox(height: 10),
                    Text('Product Name: $_productName'),
                    const SizedBox(height: 5),
                    Text('Nutri-Score: $_nutriScore'),
                  ],
                ),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _scannedBarcode = '';
            _productName = '';
            _nutriScore = '';
            _error = '';
          });
          _controller?.start();
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}
