import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/screen/new_item_screen.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    try {
      final url = Uri.https(
          "catat-duid-1df0b-default-rtdb.asia-southeast1.firebasedatabase.app",
          "shopping-list.json");

      final response = await http.get(url);

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final data in listData.entries) {
        loadedItems.add(
          GroceryItem(
            id: data.key,
            name: data.value["name"],
            quantity: data.value["quantity"],
            category: categories.entries
                .firstWhere((element) =>
                    element.value.category == data.value["category"])
                .value,
          ),
        );
      }
      setState(() {
        _isLoading = false;
        _groceryItems = loadedItems;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = "Failed to fetch data, please try again later";
      });
    }
  }

  void _addItem() async {
    await Navigator.push<GroceryItem>(
      context,
      MaterialPageRoute(
        builder: (ctx) => NewItemScreen(),
      ),
    );

    _loadItems();
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https(
        "catat-duid-1df0b-default-rtdb.asia-southeast1.firebasedatabase.app",
        "shopping-list/${item.id}.json");
    final res = await http.delete(url);

    if (res.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Text("No items added yet"),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_groceryItems.isEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          child: ListTile(
            leading: Container(
              color: _groceryItems[index].category.color,
              width: 24,
              height: 24,
            ),
            title: Text(_groceryItems[index].name),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }

    if (_errorMsg != null) {
      content = Center(child: Text(_errorMsg!));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Your Groceries"),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
