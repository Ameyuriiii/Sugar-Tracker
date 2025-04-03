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

  Future<void> _fetchProductData(String barcode) async {
    setState(() {
      _isLoading = true;
      _error = '';
      _productName = '';
      _nutriScore = '';
    });

    final url =
        'https://world.openfoodfacts.net/api/v2/product/$barcode?fields=product_name,nutrition_grades';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          setState(() {
            _productName = product['product_name'] ?? 'Unknown';
            _nutriScore = product['nutrition_grades']?.toUpperCase() ?? 'N/A';
          });
        } else {
          setState(() => _error = 'Product not found in Open Food Facts database.');
        }
      } else {
        setState(() => _error = 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Error fetching data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        setState(() => _scannedBarcode = rawValue);
        _controller?.stop();
        _fetchProductData(rawValue);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Scan a Product'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Scanner View
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller!,
                  onDetect: _onDetect,
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Result & Feedback
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          else if (_scannedBarcode.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Scan a barcode to see product information.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scanned Barcode: $_scannedBarcode',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Product Name:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple[700]),
                          ),
                          Text(
                            _productName,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nutri-Score:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple[700]),
                          ),
                          Text(
                            _nutriScore,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 80), // space for FAB
        ],
      ),

      // Clear/Refresh FAB
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.deepPurple,
            onPressed: () {
              setState(() {
                _scannedBarcode = '';
                _productName = '';
                _nutriScore = '';
                _error = '';
              });
              _controller?.start();
            },
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 6),
          const Text(
            "Rescan",
            style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
