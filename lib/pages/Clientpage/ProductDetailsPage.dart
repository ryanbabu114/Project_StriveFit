import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_provider.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map product;

  ProductDetailsPage({required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;
  int stock = 0;
  bool isLoading = true;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchStock();
  }

  Future<void> fetchStock() async {
    final response = await supabase
        .from('gym_products')
        .select('stock')
        .eq('id', widget.product['id'])
        .single();

    setState(() {
      stock = (response['stock'] ?? 0).toInt(); // 🔧 Fix: num to int
      isLoading = false;
    });
  }

  Future<void> updateStock(int newStock) async {
    await supabase
        .from('gym_products')
        .update({'stock': newStock})
        .eq('id', widget.product['id']);
  }

  void addToCart() {
    if (quantity > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Only $stock items in stock")),
      );
      return;
    }

    Map<String, dynamic> cartItem = {
      ...widget.product,
      'quantity': quantity,
    };

    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addToCart(cartItem);

    updateStock(stock - quantity);
    setState(() {
      stock -= quantity;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Added to Cart"),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: "View Cart",
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }

  void removeFromCart() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    Map<String, dynamic>? existingItem;

    try {
      existingItem = cart.cartItems.firstWhere(
            (item) => item['id'] == widget.product['id'],
      );
    } catch (e) {
      existingItem = null;
    }

    if (existingItem != null) {
      int returnedQty = (existingItem['quantity'] ?? 0).toInt();
      cart.removeFromCart(existingItem);

      updateStock(stock + returnedQty);
      setState(() {
        stock += returnedQty;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Removed from Cart")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Item not in cart")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product['title'])),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(widget.product['image']),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(widget.product['title'],
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Rs.${widget.product['price']}",
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(widget.product['description'],
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            SizedBox(height: 10),
            Text("Available Stock: $stock",
                style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (quantity > 1) {
                      setState(() {
                        quantity--;
                      });
                    }
                  },
                ),
                Text(quantity.toString(),
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () {
                    if (quantity < stock) {
                      setState(() {
                        quantity++;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                            Text("Cannot add more than $stock items")),
                      );
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.shopping_cart),
                label: Text("Add to Cart"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: stock > 0 ? addToCart : null,
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.remove_shopping_cart),
                label: Text("Remove from Cart"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: removeFromCart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
