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
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = 'Please enter a product name.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _results = [];
      _error = '';
    });

    final url = Uri.https(
      'world.openfoodfacts.org',
      '/cgi/search.pl',
      {
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'fields': 'product_name,nutriments',
        'page_size': '30',
      },
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List<dynamic>? ?? [];

        final queryLower = query.toLowerCase();
        final mapped = products
            .map((p) {
          final name = p['product_name']?.toString() ?? '';
          final sugar = p['nutriments']?['sugars_100g']?.toString() ?? '0';
          return {'name': name, 'sugar': sugar};
        })
            .where((e) =>
        e['name']!.isNotEmpty &&
            e['name']!.toLowerCase().contains(queryLower))
            .toList();

        setState(() {
          _results = mapped;
          _error = mapped.isEmpty ? 'No matching products found.' : '';
        });
      } else {
        setState(() {
          _error = 'API error: ${response.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _error = 'Failed to search. Please check your internet connection.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Search Products",
        style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Enter product name",
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.deepPurple[50],
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _results = [];
                      _error = '';
                    });
                  },
                ),
              ),
              onSubmitted: _searchProducts,
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              )
            else if (_results.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Search for a product to see results."),
                )
              else
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, index) {
                      final item = _results[index];
                      final name = item['name'] ?? '';
                      final sugar = item['sugar'] ?? '0';
                      return ListTile(
                        title: Text(name),
                        subtitle: Text("Sugar: $sugar g/100g"),
                        trailing: const Icon(Icons.add, color: Colors.deepPurple),
                        onTap: () => Navigator.pop(context, {
                          'name': name,
                          'sugar': sugar,
                        }),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
