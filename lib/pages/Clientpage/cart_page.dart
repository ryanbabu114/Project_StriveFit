import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_provider.dart';

class CartPage extends StatelessWidget {
  final supabase = Supabase.instance.client;

  // Updated: productId is String (UUID)
  Future<int> getLatestStock(String productId) async {
    final response = await supabase
        .from('gym_products')
        .select('stock')
        .eq('id', productId)
        .single();

    return (response['stock'] ?? 0) as int;
  }

  Future<void> _handleCheckout(BuildContext context, CartProvider cart) async {
    final items = cart.cartItems;

    try {
      for (var item in items) {
        final String productId = item['id']; // Now a String (uuid)
        final int purchaseQty = item['quantity'];

        int currentStock = await getLatestStock(productId);
        int newStock = currentStock - purchaseQty;

        if (newStock >= 0) {
          await supabase
              .from('gym_products')
              .update({'stock': newStock})
              .eq('id', productId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Not enough stock for ${item['name'] ?? item['title']}")),
          );
          return;
        }
      }

      cart.clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Purchase Successful!")),
      );
    } catch (e) {
      print("Checkout error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during checkout")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Shopping Cart")),
      body: cart.cartItems.isEmpty
          ? Center(child: Text("Your cart is empty"))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.cartItems.length,
              itemBuilder: (context, index) {
                var product = cart.cartItems[index];

                String name = product['name'] ?? product['title'] ?? 'No Name';
                String imageUrl = product['image'] ?? '';
                double price = (product['price'] ?? 0).toDouble();
                int quantity = (product['quantity'] ?? 1);
                String productId = product['id']; // UUID is String

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      width: 50,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image, size: 50);
                      },
                    )
                        : Icon(Icons.image_not_supported, size: 50),
                    title: Text(name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Rs.${price.toStringAsFixed(2)} x $quantity"),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline),
                              onPressed: quantity > 1
                                  ? () => cart.updateQuantity(product, quantity - 1)
                                  : null,
                            ),
                            Text(
                              quantity.toString(),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline),
                              onPressed: () async {
                                int currentStock = await getLatestStock(productId);

                                if (quantity < currentStock) {
                                  cart.updateQuantity(product, quantity + 1);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Only $currentStock in stock")),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        cart.removeFromCart(product);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Total: Rs.${cart.totalPrice.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: cart.cartItems.isNotEmpty
                      ? () => _handleCheckout(context, cart)
                      : null,
                  child: Text("Checkout"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
