// lib/screens/shopping_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'home_screen.dart';
import 'product_detail_screen.dart';
import 'wishlist_screen.dart';
import 'account_screen.dart';
import '../backend/models/product.dart';

class HaborScreen extends StatefulWidget {
  const HaborScreen({super.key});

  @override
  State<HaborScreen> createState() => _HaborScreenState();
}

class _HaborScreenState extends State<HaborScreen> {
  int _selectedIndex = 1;

  List<Product> _allProducts = [];
  List<Product> _visibleProducts = [];

  // Filter state
  String? _selectedCategory;
  final Set<String> _selectedBrands = {};
  RangeValues _priceRange = const RangeValues(0, 3000);
  final Set<String> _selectedSpecs = {};

  // Available options
  List<String> _categories = [];
  List<String> _brands = [];
  List<String> _specs = [];

  // wishlist (using id)
  final Set<int> _wishlist = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final raw = await rootBundle.loadString('assets/products.json');
    final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
    final filters = data['filters'] as Map<String, dynamic>;

    final List<Product> products = [];
    final Set<String> brandsSet = {};
    final Set<String> specsSet = {};

    int idCounter = 1;

    filters.forEach((category, brandsMap) {
      final Map<String, dynamic> brands = brandsMap as Map<String, dynamic>;
      brands.forEach((brand, items) {
        final List<dynamic> list = items as List<dynamic>;
        for (final item in list) {
          final j = item as Map<String, dynamic>;
          final product = Product(
            id: idCounter++,
            name: j['name'] ?? '',
            brand: brand,
            category: category,
            price: (j['price'] ?? 0).toDouble(),
            originalPrice: (j['originalPrice'] ?? 0).toDouble(),
            discount: j['discount'] ?? '',
            image: j['image'] ?? '',
            description: j['description'] ?? '',
            specs: List<String>.from(j['specs'] ?? []),
          );
          products.add(product);
          brandsSet.add(brand);
          specsSet.addAll(product.specs);
        }
      });
    });

    setState(() {
      _allProducts = products;
      _visibleProducts = List.from(_allProducts);
      _categories = filters.keys.toList();
      _brands = brandsSet.toList()..sort();
      _specs = specsSet.toList()..sort();
    });
  }

  void _applyFilters() {
    final minPrice = _priceRange.start;
    final maxPrice = _priceRange.end;

    final filtered = _allProducts.where((p) {
      if (_selectedCategory != null && p.category != _selectedCategory) {
        return false;
      }
      if (_selectedBrands.isNotEmpty && !_selectedBrands.contains(p.brand)) {
        return false;
      }
      if (p.price < minPrice || p.price > maxPrice) {
        return false;
      }
      if (_selectedSpecs.isNotEmpty &&
          !_selectedSpecs.every((s) => p.specs.contains(s))) {
        return false;
      }
      return true;
    }).toList();

    setState(() {
      _visibleProducts = filtered;
    });

    Navigator.of(context).maybePop();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedBrands.clear();
      _selectedSpecs.clear();
      _priceRange = const RangeValues(0, 3000);
      _visibleProducts = List.from(_allProducts);
    });
  }

  Widget _buildProductCard(Product p) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: _assetImageOrPlaceholder(p.image),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B4D8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.discount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (_wishlist.contains(p.id)) {
                          _wishlist.remove(p.id);
                        } else {
                          _wishlist.add(p.id);
                        }
                      });
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white70,
                      child: Icon(
                        _wishlist.contains(p.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _wishlist.contains(p.id)
                            ? const Color(0xFF00B4D8)
                            : Colors.black54,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                p.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                p.brand,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SpacerWrapper(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${p.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${p.originalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.shopping_bag_outlined, color: Colors.black54),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assetImageOrPlaceholder(String filename) {
    if (filename.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.laptop, size: 48, color: Colors.grey),
        ),
      );
    }
    return Image.asset(
      'assets/images/$filename',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.broken_image, size: 46, color: Colors.grey),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habor', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.black),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Filters',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(_allProducts),
              );
            },
            tooltip: 'Search',
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (s) => setState(
                        () => _selectedCategory = s ? null : _selectedCategory,
                      ),
                    ),
                    ..._categories.map((cat) {
                      return ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (sel) => setState(() {
                          _selectedCategory = sel ? cat : null;
                        }),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Brand',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          children: _brands.map((b) {
                            final selected = _selectedBrands.contains(b);
                            return FilterChip(
                              label: Text(b),
                              selected: selected,
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _selectedBrands.add(b);
                                  } else {
                                    _selectedBrands.remove(b);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            'Price Range',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        RangeSlider(
                          min: 0,
                          max: 3000,
                          values: _priceRange,
                          divisions: 30,
                          labels: RangeLabels(
                            '\$${_priceRange.start.toInt()}',
                            '\$${_priceRange.end.toInt()}',
                          ),
                          onChanged: (v) => setState(() => _priceRange = v),
                        ),
                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            'Specifications',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _specs.map((s) {
                            final selected = _selectedSpecs.contains(s);
                            return FilterChip(
                              label: Text(s),
                              selected: selected,
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _selectedSpecs.add(s);
                                  } else {
                                    _selectedSpecs.remove(s);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetFilters,
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _visibleProducts.isEmpty
            ? const Center(child: Text('No products found'))
            : GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemCount: _visibleProducts.length,
                itemBuilder: (context, i) {
                  final p = _visibleProducts[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(product: p),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'product-${p.id}',
                      child: _buildProductCard(p),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);

          // HOME
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
          // SHOP → Habor
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HaborScreen()),
            );
          }

          // FAVORITES → WISHLIST
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WishlistScreen()),
            );
          }

          // PROFILE (optional)
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF00B4D8),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.laptop_mac_sharp),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class SpacerWrapper extends StatelessWidget {
  final double height;
  const SpacerWrapper({this.height = 8, super.key});
  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

class ProductSearchDelegate extends SearchDelegate {
  final List<Product> products;

  ProductSearchDelegate(this.products);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Product> results = products
        .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.brand.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) {
        final p = results[i];
        return ListTile(
          leading: Image.asset(
            'assets/images/${p.image}',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          title: Text(p.name),
          subtitle: Text(p.brand),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: p),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Product> suggestions = products
        .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.brand.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (_, i) {
        final p = suggestions[i];
        return ListTile(
          leading: Image.asset(
            'assets/images/${p.image}',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          title: Text(p.name),
          subtitle: Text(p.brand),
          onTap: () {
            query = p.name;
            showResults(context);
          },
        );
      },
    );
  }
}
