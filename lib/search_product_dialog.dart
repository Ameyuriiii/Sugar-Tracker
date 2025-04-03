import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchProductDialog extends StatefulWidget {
  const SearchProductDialog({super.key});

  @override
  State<SearchProductDialog> createState() => _SearchProductDialogState();
}

class _SearchProductDialogState extends State<SearchProductDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _results = [];
  bool _isLoading = false;
  String _error = '';

  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = [];
      _error = '';
    });

    final url =
        'https://world.openfoodfacts.net/api/v2/search?search_terms=$query&fields=product_name,nutriments&sort_by=unique_scans_n&page_size=20';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List<dynamic>;

        final List<Map<String, String>> mapped = products.map((p) {
          final name = p['product_name']?.toString() ?? 'Unknown';
          final sugar = p['nutriments']?['sugars_100g']?.toString() ?? '0';
          return {'name': name, 'sugar': sugar};
        }).where((e) => e['name'] != 'Unknown').toList();

        setState(() => _results = mapped);
      } else {
        setState(() => _error = 'API error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Search Products"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            onSubmitted: _searchProducts,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: "Enter product name",
              suffixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoading) const CircularProgressIndicator(),
          if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
          if (!_isLoading && _results.isNotEmpty)
            SizedBox(
              height: 300,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (_, index) {
                  final item = _results[index];
                  return ListTile(
                    title: Text(item['name'] ?? ''),
                    subtitle: Text("Sugar: ${item['sugar']} g"),
                    onTap: () {
                      Navigator.pop(context, item); // return name + sugar
                    },
                  );
                },
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
