import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'activity_manager_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'scan_popup.dart';
import 'scan_product_screen.dart';
import 'sugar_product_lookup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _mealNameController = TextEditingController();
  final List<Map<String, dynamic>> _productsInMeal = [];
  String _mealType = 'breakfast';
  final TextEditingController _productSearchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _customProdNameCtrl = TextEditingController();
  final TextEditingController _customProdSugarCtrl = TextEditingController();
  bool _showMealHistory = false;

  Future<void> _scanProduct() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const ScanPopup(),
    );
    if (result != null) {
      final name = result['name'] ?? 'Unknown';
      final sugar = double.tryParse(result['sugar'] ?? '0') ?? 0.0;
      setState(() {
        _productsInMeal.add({'name': name, 'sugar': sugar});
      });
    }
  }

  Future<void> _searchProductAPI(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _searchResults = [];
    });

    final url = Uri.parse(
      'https://world.openfoodfacts.net/api/v2/search?'
          'search_terms=${Uri.encodeQueryComponent(query)}&'
          'fields=product_name,nutriments&'
          'sort_by=unique_scans_n&'
          'page_size=20',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> products = data['products'] ?? [];

        setState(() {
          _searchResults = products
              .map((p) => {
            'product_name': p['product_name'] ?? 'Unknown',
            'nutriments': {
              'sugars_100g': p['nutriments'] != null
                  ? (p['nutriments']['sugars_100g']?.toString() ?? '0')
                  : '0',
            },
          })
              .where((p) => p['product_name'] != 'Unknown')
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API error. Please try again.')),
        );
      }
    } catch (e) {
      debugPrint('Search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to search products. Check your connection.')),
      );
    }
  }

  void _addSearchProduct(Map<String, dynamic> product) {
    final productName = product['product_name'] ?? 'No name';
    final sugarNum = double.tryParse(product['nutriments']?['sugars_100g'] ?? '0') ?? 0.0;
    setState(() {
      _productsInMeal.add({'name': productName, 'sugar': sugarNum});
    });
  }

  Widget _buildProductSearchDialog() {
    _productSearchController.clear();
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Search Product",
            style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _productSearchController,
                  decoration: InputDecoration(
                    hintText: "Enter product name",
                    prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.deepPurple[50],
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _productSearchController.clear();
                        setDialogState(() => _searchResults = []);
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    _searchProductAPI(value);
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 10),
                if (_searchResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Search for a product or check your spelling."),
                  )
                else
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        final name = product['product_name'] ?? 'No name';
                        final sugar = product['nutriments']?['sugars_100g'] ?? '0';

                        return ListTile(
                          title: Text(name),
                          subtitle: Text("Sugar: $sugar g/100g"),
                          trailing: const Icon(Icons.add, color: Colors.deepPurple),
                          onTap: () {
                            _addSearchProduct(product);
                            Navigator.pop(context);
                          },
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
              child: const Text("Close", style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomProductDialog() {
    _customProdNameCtrl.clear();
    _customProdSugarCtrl.clear();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Custom Product",
        style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _customProdNameCtrl,
            decoration: InputDecoration(
              labelText: "Name",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.deepPurple[50],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customProdSugarCtrl,
            decoration: InputDecoration(
              labelText: "Sugar (g)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.deepPurple[50],
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _customProdNameCtrl.text.trim();
            final sugar = double.tryParse(_customProdSugarCtrl.text.trim()) ?? 0.0;
            if (name.isNotEmpty && sugar >= 0) {
              setState(() {
                _productsInMeal.add({'name': name, 'sugar': sugar});
              });
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid name and sugar value.')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text("Add"),
        ),
      ],
    );
  }

  double get _sumMealSugar => _productsInMeal.fold(0.0, (sum, p) => sum + (p['sugar'] as double));

  Future<void> _saveMeal() async {
    final mealName = _mealNameController.text.trim();
    if (mealName.isEmpty && _productsInMeal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a meal name or products.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('meals').add({
        'userId': user!.uid,
        'name': mealName.isNotEmpty ? mealName : '(Unnamed Meal)',
        'type': _mealType,
        'timestamp': DateTime.now().toUtc(),
        'products': _productsInMeal,
        'sugar': _sumMealSugar,
      });

      setState(() {
        _mealNameController.clear();
        _productsInMeal.clear();
        _mealType = 'breakfast';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal saved successfully!')),
      );
    } catch (e) {
      debugPrint('Save meal error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save meal. Please try again.')),
      );
    }
  }

  Future<void> _toggleActivityDone(String docId, bool currentVal) async {
    await FirebaseFirestore.instance
        .collection('activities')
        .doc(docId)
        .update({'isDone': !currentVal});
  }

  List<FlSpot> _getWeeklySugarData(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData) return [];
    final docs = snapshot.data!.docs;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    Map<int, double> dailyTotals = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != user!.uid) continue;
      final sugarVal = (data['sugar'] as num?)?.toDouble() ?? 0.0;
      final ts = (data['timestamp'] as Timestamp).toDate();
      final diff = ts.difference(startOfWeek).inDays;
      if (diff >= 0 && diff < 7) {
        dailyTotals[diff] = (dailyTotals[diff] ?? 0) + sugarVal;
      }
    }

    return dailyTotals.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
  }

  double _computeTodaySugar(AsyncSnapshot<QuerySnapshot> snapshot) {
    double total = 0;
    if (!snapshot.hasData) return total;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    for (var doc in snapshot.data!.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != user!.uid) continue;
      final sugarVal = (data['sugar'] as num?)?.toDouble() ?? 0.0;
      final ts = (data['timestamp'] as Timestamp).toDate();
      if (ts.isAfter(start) && ts.isBefore(end)) {
        total += sugarVal;
      }
    }
    return total;
  }

  double _getMaxSugarValue(List<FlSpot> spots) {
    if (spots.isEmpty) return 50.0; // Default max if no data
    final maxValue = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble(); // Add 20% padding and round up
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 70, fit: BoxFit.contain),
            const SizedBox(width: 8),
            const Text('Sugar Tracker',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('User', style: TextStyle(color: Colors.white)),
              accountEmail: Text(user?.email ?? '', style: const TextStyle(color: Colors.white70)),
              currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 30, color: Colors.deepPurple)),
              decoration: BoxDecoration(color: Colors.deepPurple[700]),
            ),
            _buildDrawerItem(Icons.home, 'Home', () => Navigator.pop(context)),
            _buildDrawerItem(Icons.person, 'Profile',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: user!.uid)))),
            _buildDrawerItem(Icons.qr_code, 'Scan Product',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanProductScreen()))),
            _buildDrawerItem(Icons.search, 'Sugar Lookup',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SugarProductLookup()))),
            _buildDrawerItem(Icons.list, 'Activity Manager',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityManagerPage()))),
            _buildDrawerItem(Icons.logout, 'Logout', () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            }),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('meals')
                  .where('userId', isEqualTo: user!.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final sugarToday = _computeTodaySugar(snapshot);
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello, ${user?.email?.split('@')[0] ?? ''}",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.cake, color: Colors.deepPurple, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              "Today's Sugar: ${sugarToday.toStringAsFixed(1)} g",
                              style: const TextStyle(fontSize: 20, color: Colors.deepPurple),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Weekly Sugar Trend",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('meals')
                            .where('userId', isEqualTo: user!.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final spots = _getWeeklySugarData(snapshot);
                          final maxY = _getMaxSugarValue(spots);
                          return LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                drawHorizontalLine: true,
                                horizontalInterval: maxY / 5,
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) => Text(
                                      '${value.toInt()} g',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                      return Text(days[value.toInt()], style: const TextStyle(fontSize: 12));
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  curveSmoothness: 0.5,
                                  color: Colors.deepPurple,
                                  barWidth: 3,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.deepPurple.withOpacity(0.1),
                                  ),
                                  dotData: const FlDotData(show: true),
                                ),
                              ],
                              minY: 0,
                              maxY: maxY,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Add Meal",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mealNameController,
                      decoration: InputDecoration(
                        labelText: 'Meal Name (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.deepPurple[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _mealType,
                      items: ['breakfast', 'lunch', 'dinner', 'snack']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e.capitalize())))
                          .toList(),
                      onChanged: (val) => setState(() => _mealType = val!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.deepPurple[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Products:", style: TextStyle(fontWeight: FontWeight.w600)),
                    if (_productsInMeal.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text("No products added yet."),
                      )
                    else
                      ..._productsInMeal.map((p) => ListTile(
                        leading: const Icon(Icons.fastfood, color: Colors.deepPurple),
                        title: Text(p['name']),
                        subtitle: Text("${p['sugar']} g sugar"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _productsInMeal.remove(p)),
                        ),
                      )),
                    const SizedBox(height: 12),
                    Text("Total sugar: ${_sumMealSugar.toStringAsFixed(1)} g",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _scanProduct,
                          icon: const Icon(Icons.qr_code, color: Colors.white),
                          label: const Text("Scan", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => showDialog(context: context, builder: (_) => _buildProductSearchDialog()),
                          icon: const Icon(Icons.search, color: Colors.white),
                          label: const Text("Search", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => showDialog(context: context, builder: (_) => _buildCustomProductDialog()),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text("Custom", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveMeal,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text("Save Meal", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                title: const Text("Today's Activities",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('activities')
                          .where('userId', isEqualTo: user!.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text("No activities yet.");
                        }

                        final docs = snapshot.data!.docs;
                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return CheckboxListTile(
                              title: Text(data['name'] ?? 'Untitled'),
                              subtitle: Text(data['description'] ?? ''),
                              value: data['isDone'] ?? false,
                              onChanged: (_) => _toggleActivityDone(doc.id, data['isDone'] ?? false),
                              activeColor: Colors.deepPurple,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                title: const Text("Meal History",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('meals')
                        .where('userId', isEqualTo: user!.uid)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Padding(padding: EdgeInsets.all(16), child: Text("No meals logged yet."));
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final ts = (data['timestamp'] as Timestamp).toDate();
                          final sugarVal = (data['sugar'] as num?)?.toDouble() ?? 0.0;
                          return ListTile(
                            title: Text("${data['name']} (${data['type']})"),
                            subtitle: Text("${DateFormat.yMMMd().format(ts)} - $sugarVal g sugar"),
                            leading: const Icon(Icons.history, color: Colors.deepPurple),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}