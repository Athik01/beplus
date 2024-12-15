import 'dart:convert';
import 'package:beplus/order_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
class CartPage extends StatefulWidget {
  final String userId;

  const CartPage({Key? key, required this.userId}) : super(key: key);
  @override
  _CartPageState createState() => _CartPageState();
}
class _CartPageState extends State<CartPage> {
  late Future<List<Map<String, dynamic>>> _cartItemsFuture;
  @override
  void initState() {
    super.initState();
    _cartItemsFuture = _fetchCartItems();
  }

  Future<List<Map<String, dynamic>>> _fetchCartItems() async {
    final cartsRef = FirebaseFirestore.instance.collection('carts');
    final productsRef = FirebaseFirestore.instance.collection('products');
    late String userId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch cart items for the given userId
    final cartSnapshot = await cartsRef.where('userId', isEqualTo: userId).get();

    if (cartSnapshot.docs.isEmpty) return []; // No items in cart

    List<Map<String, dynamic>> cartItems = [];
    for (var doc in cartSnapshot.docs) {
      final cartData = doc.data();
      final productId = cartData['productId'];
      final totalAmount = cartData['totalAmount']; // Include totalAmount from the cart document
      final cartSize = cartData['selectedSize'];
      // Fetch product details
      final productSnapshot = await productsRef.doc(productId).get();
      if (productSnapshot.exists) {
        final productData = productSnapshot.data();
        if (productData != null) {
          cartItems.add({
            'cartId': doc.id,
            'productId': productId,
            'productImage': productData['imageUrl'], // Base64 image string
            'productName': productData['name'],
            'selectedSize':cartSize,
            'totalAmount': totalAmount, // Add totalAmount to the cart item
          });
        }
      }
    }
    return cartItems;
  }

  Widget _buildCartItem(Map<String, dynamic> cartItem, BuildContext context) {
    final decodedImage = base64Decode(cartItem['productImage']);

    return GestureDetector(
      onTap: () {
        // Navigate to the OrderPage with the productId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderPage(productId: cartItem['productId']),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.withOpacity(0.1), Colors.tealAccent.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Image with rounded corners
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                decodedImage,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Product Name with bold and contrasting style
                            Text(
                              cartItem['productName'] ?? 'Product Name',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Total Amount with improved layout
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.attach_money, color: Colors.green, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  "Total:",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${cartItem['totalAmount'] ?? 0}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Display selected sizes and counters
                            if (cartItem['selectedSize'] != null && cartItem['selectedSize'].isNotEmpty)
                              ...cartItem['selectedSize'].entries.map((entry) {
                                String size = entry.key;
                                int counter = entry.value;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Size: $size",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.teal, width: 1),
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.grey[100],
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove, color: Colors.teal),
                                              onPressed: () async {
                                                // Decrement logic
                                                if (counter > 0) {
                                                  // Fetch the product document from Firestore
                                                  var productDoc = await FirebaseFirestore.instance
                                                      .collection('products')
                                                      .doc(cartItem['productId'])
                                                      .get();

                                                  if (productDoc.exists) {
                                                    var priceMap = productDoc['price'] ?? {};
                                                    if (priceMap[size] != null) {
                                                      var price = priceMap[size]['price'] ?? 0;

                                                      setState(() {
                                                        counter -= 1;
                                                        cartItem['selectedSize'][size] = counter;
                                                        cartItem['totalAmount'] = (cartItem['totalAmount'] ?? 0) - price;
                                                      });

                                                      // Update Firestore or local cart data
                                                      await FirebaseFirestore.instance
                                                          .collection('carts')
                                                          .doc(cartItem['cartId'])
                                                          .update({
                                                        'selectedSize': cartItem['selectedSize'],
                                                        'totalAmount': cartItem['totalAmount'],
                                                      });
                                                    }
                                                  }
                                                }
                                              },
                                            ),
                                            Text(
                                              "$counter",
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add, color: Colors.teal),
                                              onPressed: () async {
                                                // Increment logic
                                                var productDoc = await FirebaseFirestore.instance
                                                    .collection('products')
                                                    .doc(cartItem['productId'])
                                                    .get();
                                                print(cartItem['productId']);
                                                if (productDoc.exists) {
                                                  var priceMap = productDoc['price'] ?? {};
                                                  print(productDoc['price']);
                                                  if (priceMap[size] != null) {
                                                    var price = priceMap[size]['price'] ?? 0;

                                                    setState(() {
                                                      counter += 1;
                                                      cartItem['selectedSize'][size] = counter;
                                                      cartItem['totalAmount'] = (cartItem['totalAmount'] ?? 0) + price;
                                                    });

                                                    // Update Firestore or local cart data
                                                    await FirebaseFirestore.instance
                                                        .collection('carts')
                                                        .doc(cartItem['cartId'])
                                                        .update({
                                                      'selectedSize': cartItem['selectedSize'],
                                                      'totalAmount': cartItem['totalAmount'],
                                                    });
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            const SizedBox(height: 12),
                            // Delete Button with gradient and icon
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _deleteCartItem(cartItem['cartId']);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.delete, color: Colors.white),
                              label: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCartItem(String cartId) async {
    await FirebaseFirestore.instance.collection('carts').doc(cartId).delete();
    setState(() {
      _cartItemsFuture = _fetchCartItems();
    });
  }


  Widget _buildEmptyCartUI(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with shadow and gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.withOpacity(0.3), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Icon(
                  Icons.shopping_cart,
                  size: 100,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 20),
              // Main message
              Text(
                'Your Cart is Empty!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  shadows: [
                    Shadow(
                      blurRadius: 6.0,
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(3.0, 3.0),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Submessage with a friendly tone
              Text(
                '"Inner battles are hard, but faith leads to reward"',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Call-to-action button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: Colors.tealAccent.withOpacity(0.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_bag, size: 24, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Shop Now',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fetchCartItemsStream(), // Change to a stream method
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading cart items.'));
          }

          final cartItems = snapshot.data;

          if (cartItems == null || cartItems.isEmpty) {
            return _buildEmptyCartUI(context);
          }

          double totalAmount = cartItems.fold(0, (sum, item) => sum + (item['totalAmount'] as double));

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // Padding to avoid overlapping with the button
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  return _buildCartItem(cartItems[index], context);
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '\₹${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _checkout(context, totalAmount);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 4,
                          shadowColor: Colors.tealAccent.withOpacity(0.4),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.shopping_cart_checkout, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Checkout',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

// Change this method to return a stream
  Stream<List<Map<String, dynamic>>> _fetchCartItemsStream() {
    // Replace with the logic to return a stream that emits updates to cart items.
    return Stream.periodic(Duration(seconds: 1), (count) {
      // Replace this with the actual stream data fetching logic.
      return _fetchCartItems(); // Your method that returns a List<Map<String, dynamic>>.
    }).asyncMap((_) => _fetchCartItems());
  }

  void _checkout(BuildContext context, double totalAmount) async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Replace with actual userId logic.
    final cartCollection = FirebaseFirestore.instance.collection('carts');
    final ordersCollection = FirebaseFirestore.instance.collection('orders');

    try {
      // Fetch all cart items for the user
      final cartSnapshot = await cartCollection.where('userId', isEqualTo: userId).get();

      if (cartSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items in the cart to checkout.')),
        );
        return;
      }

      // Prepare cart items for orders collection
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in cartSnapshot.docs) {
        final cartItem = doc.data();

        // Add to orders collection
        final orderData = {
          'cartId': doc.id,
          'productId': cartItem['productId'],
          'selectedSize': cartItem['selectedSize'],
          'totalAmount': cartItem['totalAmount'],
          'userId': userId,
          'status': 'Not Confirmed',
          'orderDate': FieldValue.serverTimestamp(),
        };
        final orderDocRef = ordersCollection.doc();
        batch.set(orderDocRef, orderData);

        // Remove from carts collection
        batch.delete(doc.reference);
      }

      // Commit the batch operation
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Checkout successful! Your order is placed.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Error during checkout: $e',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

}
