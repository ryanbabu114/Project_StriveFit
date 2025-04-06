import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class CartProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  double get totalPrice {
    return _cartItems.fold(
      0,
          (sum, item) => sum + (item['price'] * item['quantity']),
    );
  }

  CartProvider() {
    loadCart();
  }

  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cart', json.encode(_cartItems));
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    String? cartData = prefs.getString('cart');
    if (cartData != null) {
      _cartItems = List<Map<String, dynamic>>.from(json.decode(cartData));
      notifyListeners();
    }
  }

  // Updated: productId is String (UUID)
  Future<int> getCurrentStock(String productId) async {
    final response = await supabase
        .from('gym_products')
        .select('stock')
        .eq('id', productId)
        .single();

    return (response['stock'] ?? 0) as int;
  }

  // Updated: product['id'] is a String (UUID)
  Future<void> addToCart(Map<String, dynamic> product) async {
    String productId = product['id'];
    int quantityToAdd = product['quantity'] ?? 1;
    int index = _cartItems.indexWhere((item) => item['id'] == productId);

    int currentStock = await getCurrentStock(productId);
    int currentQuantityInCart = index != -1 ? _cartItems[index]['quantity'] : 0;

    if (currentQuantityInCart + quantityToAdd > currentStock) {
      return; // Prevent adding more than available
    }

    if (index != -1) {
      _cartItems[index]['quantity'] += quantityToAdd;
    } else {
      _cartItems.add({
        ...product,
        'quantity': quantityToAdd,
      });
    }

    await saveCart();
    notifyListeners();
  }

  void removeFromCart(Map<String, dynamic> product) {
    _cartItems.removeWhere((item) => item['id'] == product['id']);
    saveCart();
    notifyListeners();
  }

  void updateQuantity(Map<String, dynamic> product, int quantity) {
    int index = _cartItems.indexWhere((item) => item['id'] == product['id']);
    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index]['quantity'] = quantity;
      }
    }
    saveCart();
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    saveCart();
    notifyListeners();
  }
}
