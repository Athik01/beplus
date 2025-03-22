import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
class TallyERP extends StatefulWidget {
  const TallyERP({Key? key}) : super(key: key);

  @override
  State<TallyERP> createState() => _TallyERPState();
}

class _TallyERPState extends State<TallyERP> {
  List<Map<String, dynamic>> customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() => isLoading = true);

    final billsSnapshot = await FirebaseFirestore.instance
        .collection('bills')
        .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    final customerMap = <String, Map<String, dynamic>>{};

    for (var doc in billsSnapshot.docs) {
      final data = doc.data();
      final customerId = data['customerId'];

      if (!customerMap.containsKey(customerId)) {
        customerMap[customerId] = {
          'customerId': customerId,
          'totalAmount': 0.0,
          'customerName': '',
        };
      }
      customerMap[customerId]!['totalAmount'] += (data['totalAmount'] ?? 0.0);
    }

    await Future.forEach(customerMap.keys, (customerId) async {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();

      customerMap[customerId]!['customerName'] = userDoc.exists
          ? userDoc['name'] ?? 'Unknown'
          : 'Unknown';
    });

    setState(() {
      customers = customerMap.values.toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tally ERP - Customer List',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color:Colors.white),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedOpacity(
        opacity: isLoading ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 600),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Text(
                    customer['customerName'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  customer['customerName'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Total Amount: ₹${customer['totalAmount'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            MonthlyInvoicesPage(
                                customerId: customer['customerId']),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end).chain(
                            CurveTween(curve: curve),
                          );

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
class MonthlyInvoicesPage extends StatefulWidget {
  final String customerId;

  const MonthlyInvoicesPage({Key? key, required this.customerId})
      : super(key: key);

  @override
  State<MonthlyInvoicesPage> createState() => _MonthlyInvoicesPageState();
}

class _MonthlyInvoicesPageState extends State<MonthlyInvoicesPage> {
  List<Map<String, dynamic>> monthlyInvoices = [];
  bool isLoading = true;
  String customerName = 'Loading...';

  @override
  void initState() {
    super.initState();
    fetchCustomerName();
    fetchMonthlyInvoices();
  }

  Future<void> fetchCustomerName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.customerId)
          .get();

      if (doc.exists) {
        setState(() {
          customerName = doc['name'] ?? 'Unknown Customer';
        });
      } else {
        setState(() {
          customerName = 'Unknown Customer';
        });
      }
    } catch (e) {
      setState(() {
        customerName = 'Error fetching customer';
      });
    }
  }

  Future<void> fetchMonthlyInvoices() async {
    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('bills')
        .where('customerId', isEqualTo: widget.customerId)
        .orderBy('billDate', descending: true)
        .get();

    final Map<String, List<Map<String, dynamic>>> monthlyData = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['billDate'] as Timestamp).toDate();
      final monthYear = "${date.year}-${date.month}";

      if (!monthlyData.containsKey(monthYear)) {
        monthlyData[monthYear] = [];
      }

      monthlyData[monthYear]!.add({
        'billDate': date,
        'totalAmount': data['totalAmount'],
        'orders': data['orders'],
      });
    }

    setState(() {
      monthlyInvoices = monthlyData.entries.map((e) => {
        'month': e.key,
        'invoices': e.value,
      }).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoices for $customerName',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : monthlyInvoices.isEmpty
          ? Center(
        child: Text(
          "No invoices found",
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: monthlyInvoices.length,
        itemBuilder: (context, index) {
          final monthData = monthlyInvoices[index];
          final month = monthData['month'];
          final invoices = monthData['invoices'];

          return Card(
            elevation: 6,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ExpansionTile(
              leading: Icon(Icons.calendar_month, color: Colors.teal),
              title: Text(
                'Month: $month',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              children: invoices.map<Widget>((invoice) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  title: Text(
                    'Date: ${invoice['billDate'].toString().split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Total: ₹${invoice['totalAmount']}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Colors.teal),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvoiceDetailPage(
                          invoiceData: invoice,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
class InvoiceDetailPage extends StatefulWidget {
  final Map<String, dynamic> invoiceData;

  const InvoiceDetailPage({Key? key, required this.invoiceData}) : super(key: key);

  @override
  _InvoiceDetailPageState createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  Map<String, String> productNames = {}; // Store product names
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProductNames();
  }

  // 🔥 Fetch product names from Firestore
  Future<void> _fetchProductNames() async {
    final orders = widget.invoiceData['orders'] as List;
    Map<String, String> names = {};

    for (var order in orders) {
      final productId = order['productId'];

      if (!productNames.containsKey(productId)) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

          if (doc.exists) {
            names[productId] = doc['name'] ?? 'Unknown Product';
          } else {
            names[productId] = 'Unknown Product';
          }
        } catch (e) {
          names[productId] = 'Error fetching product';
        }
      }
    }

    setState(() {
      productNames = names;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = widget.invoiceData['orders'] as List;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.white)),
        backgroundColor: Colors.teal[400],
        elevation: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ✅ Invoice Details Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInvoiceDetailRow(Icons.calendar_today, 'Bill Date', '${widget.invoiceData['billDate']}'),
                  const Divider(),
                  _buildInvoiceDetailRow(Icons.monetization_on, 'Total Amount', '₹${widget.invoiceData['totalAmount']}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ✅ Product List Section
          Text(
            'Products Ordered',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal[800]),
          ),
          const SizedBox(height: 10),

          if (isLoading)
            ...List.generate(3, (index) => _buildShimmerEffect())
          else
            ...orders.map((order) {
              final productId = order['productId'];
              final productName = productNames[productId] ?? 'Loading...';
              final selectedSize = order['selectedSize'] as Map<String, dynamic>? ?? {};

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: Icon(Icons.shopping_cart, color: Colors.teal[400]),
                  title: Text(
                    productName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: selectedSize.entries.map((entry) {
                      return Text(
                        'Size: ${entry.key}  |  Qty: ${entry.value}',
                        style: TextStyle(color: Colors.grey[700]),
                      );
                    }).toList(),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // 🔥 Helper Widget for Invoice Row
  Widget _buildInvoiceDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal[400], size: 30),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 🔥 Shimmer effect while loading products
  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            color: Colors.white,
          ),
          title: Container(
            width: double.infinity,
            height: 16,
            color: Colors.white,
          ),
          subtitle: Container(
            width: 100,
            height: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}