import 'dart:convert';
import 'package:beplus/order_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16), // Adjust radius as needed
            child: Image.asset(
              'lib/assets/ease.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Product Image
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
                  // Product Name
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
                  // Total Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.currency_rupee, color: Colors.green, size: 20),
                      const SizedBox(width: 4),
                      const Text(
                        "Total:",
                        style: TextStyle(
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
                  // Size and Counter
                  if (cartItem['selectedSize'] != null &&
                      cartItem['selectedSize'].isNotEmpty)
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
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, color: Colors.teal),
                                    onPressed: () async {
                                      if (counter > 0) {
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
                                              cartItem['totalAmount'] =
                                                  (cartItem['totalAmount'] ?? 0) - price;
                                            });
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
                                      var productDoc = await FirebaseFirestore.instance
                                          .collection('products')
                                          .doc(cartItem['productId'])
                                          .get();
                                      if (productDoc.exists) {
                                        var priceMap = productDoc['price'] ?? {};
                                        if (priceMap[size] != null) {
                                          var price = priceMap[size]['price'] ?? 0;
                                          setState(() {
                                            counter += 1;
                                            cartItem['selectedSize'][size] = counter;
                                            cartItem['totalAmount'] =
                                                (cartItem['totalAmount'] ?? 0) + price;
                                          });
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
                ],
              ),
            ),
          ),
        ),
        // Delete Icon
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () async {
              await _deleteCartItem(cartItem['cartId']);
            },
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            splashRadius: 24,
            tooltip: 'Delete Item',
          ),
        ),
      ],
    );
  }

  Future<void> _deleteCartItem(String cartId) async {
    await FirebaseFirestore.instance.collection('carts').doc(cartId).delete();
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
    final PageController pageController = PageController(viewportFraction: 0.85);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        // Removed the shape property for no circular effect.
        flexibleSpace: Container(
          decoration: BoxDecoration(
            // Removed borderRadius to eliminate rounded corners.
            gradient: LinearGradient(
              colors: [Colors.teal.shade800, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _fetchCartItemsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading cart items.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            final cartItems = snapshot.data;
            if (cartItems == null || cartItems.isEmpty) {
              return _buildEmptyCartUI(context);
            }

            // Calculate the total amount.
            double totalAmount = cartItems.fold(
              0,
                  (sum, item) => sum + (item['totalAmount'] as double),
            );

            // Auto slide logic: schedule page change every 10 seconds.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(seconds: 10), () {
                if (pageController.hasClients) {
                  int nextPage = pageController.page!.round() + 1;
                  if (nextPage >= cartItems.length) {
                    nextPage = 0;
                  }
                  pageController.animateToPage(
                    nextPage,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                }
              });
            });

            return SafeArea(
              // The SafeArea automatically applies top and bottom insets.
              child: Column(
                children: [
                  // Use a fixed top spacer if needed
                  const SizedBox(height: 70),
                  // Carousel Section.
                  Expanded(
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(cardColor: Colors.transparent),
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          // Animated scaling effect for smooth carousel transition.
                          return AnimatedBuilder(
                            animation: pageController,
                            builder: (context, child) {
                              double value = 1.0;
                              if (pageController.position.haveDimensions) {
                                value = pageController.page! - index;
                                value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                              }
                              return Center(
                                child: Transform.scale(
                                  scale: value,
                                  child: child,
                                ),
                              );
                            },
                            child: _buildCartItem(cartItems[index], context),
                          );
                        },
                      ),
                    ),
                  ),
                  // Checkout Section.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Total Amount Display.
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\₹${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          // Gradient Checkout Button.
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.teal, Colors.tealAccent],
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                _checkout(context, totalAmount);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 36, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.shopping_cart_checkout,
                                      size: 20, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Checkout',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Note: Removed the bottom SizedBox to avoid extra space.
                ],
              ),
            );
          },
        ),
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
