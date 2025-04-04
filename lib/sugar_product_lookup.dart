/// A simple screen that lets users look up a food product by name using the
/// Open Food Facts API. It displays the product's name, Nutri-Score, and sugar content
/// (per 100g) if found. If no match is found, it displays an error message.
/// same like in home page

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SugarProductLookup extends StatefulWidget {
  const SugarProductLookup({super.key});

  @override
  State<SugarProductLookup> createState() => _SugarProductLookupState();
}

class _SugarProductLookupState extends State<SugarProductLookup> {
  final _controller = TextEditingController();
  Map<String, dynamic>? productData;
  bool isLoading = false;
  String? errorMessage;

  /// Queries Open Food Facts with the user's search and extracts product info.
  Future<void> _searchProduct() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      productData = null;
      errorMessage = null;
    });

    final url = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1');
    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      final List products = data['products'] ?? [];

      // Try to find a product whose name contains the query (case-insensitive)
      final match = products.firstWhere(
            (p) => p['product_name']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false,
        orElse: () => null,
      );

      if (match != null) {
        setState(() {
          productData = match;
        });
      } else {
        setState(() {
          errorMessage = 'No product found for "$query".';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Displays product info, an error, or a loading spinner based on state.
  Widget _buildResult() {
    if (isLoading) {
      return const CircularProgressIndicator();
    } else if (errorMessage != null) {
      return Text(errorMessage!, style: const TextStyle(color: Colors.red));
    } else if (productData != null) {
      final name = productData!['product_name'] ?? 'Unknown';
      final grade = productData!['nutrition_grades']?.toUpperCase() ?? 'N/A';
      final sugar = productData!['nutriments']?['sugars_100g'];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product: $name',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Nutri-Score: $grade'),
          Text('Sugars (per 100g): ${sugar ?? 'N/A'} g'),
        ],
      );
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Sugar Info'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchProduct(),
              decoration: InputDecoration(
                hintText: 'Enter product name (e.g., Nutella)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchProduct,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Result / Error / Loading
            _buildResult(),
          ],
        ),
      ),
    );
  }
}
