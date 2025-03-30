import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
class TallyERP extends StatefulWidget {
  const TallyERP({Key? key}) : super(key: key);

  @override
  State<TallyERP> createState() => _TallyERPState();
}

class _TallyERPState extends State<TallyERP> {
  late BuildContext _parentContext;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parentContext = context;
  }
  // Helper method to build a bordered card with the border image (lib/assets/back2.png)
  Widget _buildBorderedCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/back2.png'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        // Inset the Card so that the border image appears around it.
        child: Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 4,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ),
    );
  }

  // Fetches collection entries for a customer and displays account details.
  Widget _buildAccountDetails(String customerId, double totalAmount) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('collectionEntries')
          .where('customerId', isEqualTo: customerId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Text(
            "Error fetching account details",
            style: GoogleFonts.montserrat(),
          );
        }
        double collected = 0.0;
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('amount')) {
            collected += (data['amount'] as num).toDouble();
          }
        }
        double balance = totalAmount - collected;
        bool isTally = balance.abs() < 0.01;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isTally ? Colors.green : Colors.black,
              ),
            ),
            Text(
              'Balance: ${isTally ? 'Nil' : '₹${balance.toStringAsFixed(2)}'}',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isTally ? Colors.green : Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  // Action dialog (unchanged)
  void _showActionDialog(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/back2.png'),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title Area
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.blueGrey.withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Choose Action",
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ),
                    ),
                    // Content Area
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 20.0),
                      child: Text(
                        "Select an option",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.blueGrey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // "Add Collection Entry" Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blueGrey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          minimumSize: Size(double.infinity, 0),
                        ),
                        onPressed: () async {
                          // Capture the messenger and current navigation context.
                          final messenger = ScaffoldMessenger.of(_parentContext);
                          final navContext = _parentContext;
                          Navigator.pop(context); // Dismiss dialog

                          // Query collection entries for this customer to check balance.
                          QuerySnapshot snapshot = await FirebaseFirestore.instance
                              .collection('collectionEntries')
                              .where('customerId', isEqualTo: customer['customerId'])
                              .get();
                          double collected = 0.0;
                          for (var doc in snapshot.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            if (data.containsKey('amount')) {
                              collected += (data['amount'] as num).toDouble();
                            }
                          }
                          double balance = (customer['totalAmount'] as num).toDouble() - collected;
                          bool isTally = balance.abs() < 0.01;

                          if (!isTally) {
                            Future.delayed(Duration.zero, () {
                              Navigator.push(
                                navContext,
                                MaterialPageRoute(
                                  builder: (context) => CollectionEntryPage(
                                      customerId: customer['customerId']),
                                ),
                              );
                            });
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Not needed for this user",
                                      style: GoogleFonts.montserrat(),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.blueGrey,
                              ),
                            );
                          }
                        },
                        child: Text(
                          "Add Collection Entry",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // New "Collection Invoice" Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blueGrey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          minimumSize: Size(double.infinity, 0),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to CollectionInvoicePage to show collection details.
                          Navigator.push(
                            _parentContext,
                            MaterialPageRoute(
                              builder: (context) => CollectionInvoicePage(
                                customerId: customer['customerId'],
                              ),
                            ),
                          );
                        },
                        child: Text(
                          "Collection Invoice",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // "Sales Invoice" Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blueGrey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          minimumSize: Size(double.infinity, 0),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            _parentContext,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  MonthlyInvoicesPage(
                                      customerId: customer['customerId']),
                              transitionsBuilder:
                                  (context, animation, secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;
                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: Text(
                          "Sales Invoice",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Stack for background image and gradient overlay
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/back.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.0)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bills')
                  .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Group bills by customer
                final billsDocs = snapshot.data!.docs;
                final customerMap = <String, Map<String, dynamic>>{};
                for (var doc in billsDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final customerId = data['customerId'];
                  if (!customerMap.containsKey(customerId)) {
                    customerMap[customerId] = {
                      'customerId': customerId,
                      'totalAmount': 0.0,
                      'customerName': 'Loading...',
                    };
                  }
                  customerMap[customerId]!['totalAmount'] += (data['totalAmount'] ?? 0.0);
                }
                final customersList = customerMap.values.toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: customersList.length,
                  itemBuilder: (context, index) {
                    final customer = customersList[index];
                    // For dynamic user info, fetch using a FutureBuilder for each customer
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(customer['customerId'])
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return _buildBorderedCard(
                              child: ListTile(title: Text('Loading...')));
                        }
                        final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                        customer['customerName'] = userData != null ? userData['name'] ?? 'Unknown' : 'Unknown';
                        return _buildBorderedCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.blueGrey,
                                      child: Text(
                                        customer['customerName'][0].toUpperCase(),
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        customer['customerName'],
                                        style: GoogleFonts.montserrat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                      ),
                                      color: Colors.blueGrey,
                                      onPressed: () => _showActionDialog(customer),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Account details from collection entries
                                _buildAccountDetails(
                                  customer['customerId'],
                                  customer['totalAmount'],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(
          'Tally ERP - Customer List',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
    );
  }
}

class CollectionInvoicePage extends StatefulWidget {
  final String customerId;

  const CollectionInvoicePage({Key? key, required this.customerId})
      : super(key: key);

  @override
  _CollectionInvoicePageState createState() => _CollectionInvoicePageState();
}

class _CollectionInvoicePageState extends State<CollectionInvoicePage> {
  String customerName = "Loading...";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomerName();
  }

  Future<void> _fetchCustomerName() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.customerId)
          .get();
      setState(() {
        customerName = doc.exists ? (doc["name"] ?? "Unknown") : "Unknown";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        customerName = "Error";
        isLoading = false;
      });
    }
  }

  // Build a BarChart from a map of month-year to total amount.
  Widget _buildBarChart(Map<String, double> monthlyTotals) {
    // Sort keys in ascending order.
    List<String> months = monthlyTotals.keys.toList()..sort();
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < months.length; i++) {
      double total = monthlyTotals[months[i]]!;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: total,
              color: Colors.blueGrey,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
    }

    // Wrap the bar chart in a white container with padding,
    // then wrap that container in another container with the border image.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/back2.png'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8.0),
          child: AspectRatio(
            aspectRatio: 1.7,
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: GoogleFonts.montserrat(fontSize: 10, color: Colors.blueGrey),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              months[index],
                              style: GoogleFonts.montserrat(fontSize: 10, color: Colors.blueGrey),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Collection Invoice for $customerName",
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/back.png',
              fit: BoxFit.cover,
            ),
          ),
          // White fading gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.0)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection("collectionEntries")
                  .where("customerId", isEqualTo: widget.customerId)
                  .orderBy("date", descending: true)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error fetching collection entries",
                      style: GoogleFonts.montserrat(),
                    ),
                  );
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No collection entries found.",
                      style: GoogleFonts.montserrat(fontSize: 18),
                    ),
                  );
                }

                double totalCollected = 0.0;
                Map<String, double> monthlyTotals = {};
                List<Map<String, dynamic>> entries = [];
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  entries.add(data);
                  if (data.containsKey("amount")) {
                    double amt = (data["amount"] as num).toDouble();
                    totalCollected += amt;
                    DateTime date = (data["date"] as Timestamp).toDate();
                    String monthYear =
                        "${date.year}-${date.month.toString().padLeft(2, '0')}";
                    monthlyTotals.update(monthYear, (value) => value + amt,
                        ifAbsent: () => amt);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Graph Statistics: Bar Chart of monthly totals.
                      _buildBarChart(monthlyTotals),
                      const SizedBox(height: 16),
                      // Summary Header
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Total Collected: ₹${totalCollected.toStringAsFixed(2)}",
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // List of Collection Entries
                      Expanded(
                        child: ListView.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            DateTime date =
                            (entry["date"] as Timestamp).toDate();
                            String dateStr =
                                "${date.toLocal().toString().split(' ')[0]}";
                            return Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage('lib/assets/back2.png'),
                                    fit: BoxFit.fill,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Card(
                                  margin: const EdgeInsets.all(8.0),
                                  elevation: 4,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      "₹${(entry['amount'] as num).toDouble().toStringAsFixed(2)}",
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Date: $dateStr\nPayment: ${entry['paymentMethod']}\nNotes: ${entry['notes'] ?? ''}",
                                      style: GoogleFonts.montserrat(
                                          fontSize: 14),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class CollectionEntryPage extends StatefulWidget {
  final String customerId;

  const CollectionEntryPage({Key? key, required this.customerId})
      : super(key: key);

  @override
  _CollectionEntryPageState createState() => _CollectionEntryPageState();
}

class _CollectionEntryPageState extends State<CollectionEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  String _paymentMethod = 'Cash'; // default payment method
  String customerName = 'Loading...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Set default selected date to current date.
    _selectedDate = DateTime.now();
    _fetchCustomerDetails();
  }

  Future<void> _fetchCustomerDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.customerId)
          .get();
      if (doc.exists) {
        setState(() {
          customerName = doc['name'] ?? 'Unknown';
          isLoading = false;
        });
      } else {
        setState(() {
          customerName = 'Unknown';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        customerName = 'Error';
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime initialDate = _selectedDate ?? DateTime.now();
    DateTime firstDate = DateTime(initialDate.year - 1);
    DateTime lastDate = DateTime(initialDate.year + 1);
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitEntry() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      double amount = double.tryParse(_amountController.text) ?? 0.0;
      String notes = _notesController.text;
      try {
        await FirebaseFirestore.instance.collection('collectionEntries').add({
          'customerId': widget.customerId,
          'customerName': customerName,
          'amount': amount,
          'date': _selectedDate,
          'paymentMethod': _paymentMethod,
          'notes': notes,
          'ownerId': FirebaseAuth.instance.currentUser!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Collection entry saved successfully!',
                  style: GoogleFonts.montserrat(),
                ),
              ],
            ),
            backgroundColor: Colors.blueGrey,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Error saving entry: $e',
                  style: GoogleFonts.montserrat(),
                ),
              ],
            ),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    } else {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select a date',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use a Stack to provide the background image and gradient overlay.
    return Scaffold(
      appBar:AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Collection Entry',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/back.png',
              fit: BoxFit.cover,
            ),
          ),
          // White-to-transparent gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.0)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // White container for the form with rounded corners and shadow.
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                              children: [
                                // Amount Received Field
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Amount Received',
                                    labelStyle:
                                    GoogleFonts.montserrat(),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter amount';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Enter valid number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Date Picker Field
                                GestureDetector(
                                  onTap: _selectDate,
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText:
                                        'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                                        labelStyle:
                                        GoogleFonts.montserrat(),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Payment Method Dropdown
                                DropdownButtonFormField<String>(
                                  value: _paymentMethod,
                                  decoration: InputDecoration(
                                    labelText: 'Payment Method',
                                    labelStyle:
                                    GoogleFonts.montserrat(),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  items: <String>['Cash', 'Card', 'Online']
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: GoogleFonts.montserrat(),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _paymentMethod = newValue!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Notes Field (optional)
                                TextFormField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Notes (optional)',
                                    labelStyle:
                                    GoogleFonts.montserrat(),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Submit Button
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _submitEntry,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                      Colors.blueGrey,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                          vertical: 16),
                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: Text(
                                      'Submit Entry',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
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
              ),
            ),
          ),
        ],
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
      monthlyInvoices = monthlyData.entries
          .map((e) => {
        'month': e.key,
        'invoices': e.value,
      })
          .toList();
      isLoading = false;
    });
  }

  Widget _buildBorderedCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/back2.png'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        // Inset the Card so that the border image shows around it.
        child: Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 4,
          color: Colors.white, // Ensure the card content has an opaque white background.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Invoices for $customerName',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey,
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : monthlyInvoices.isEmpty
          ? Center(
        child: Text(
          "No invoices found",
          style: GoogleFonts.montserrat(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: monthlyInvoices.length,
        itemBuilder: (context, index) {
          final monthData = monthlyInvoices[index];
          final month = monthData['month'];
          final invoices = monthData['invoices'];

          return _buildBorderedCard(
            child: ExpansionTile(
              leading: Icon(Icons.calendar_month, color: Colors.blueGrey),
              title: Text(
                'Month: $month',
                style: GoogleFonts.montserrat(
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
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Total: ₹${invoice['totalAmount']}',
                    style: GoogleFonts.montserrat(
                      color: Colors.blueGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.blueGrey),
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

  const InvoiceDetailPage({Key? key, required this.invoiceData})
      : super(key: key);

  @override
  _InvoiceDetailPageState createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  Map<String, String> productNames = {}; // Store product names
  Map<String, Uint8List?> productImages = {}; // Store decoded image data
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    final orders = widget.invoiceData['orders'] as List;
    Map<String, String> names = {};
    Map<String, Uint8List?> images = {};

    for (var order in orders) {
      final productId = order['productId'];

      if (!names.containsKey(productId)) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            names[productId] = data['name'] ?? 'Unknown Product';
            if (data.containsKey('imageUrl') && data['imageUrl'] is String) {
              try {
                images[productId] = base64Decode(data['imageUrl']);
              } catch (e) {
                images[productId] = null;
              }
            } else {
              images[productId] = null;
            }
          } else {
            names[productId] = 'Unknown Product';
            images[productId] = null;
          }
        } catch (e) {
          names[productId] = 'Error fetching product';
          images[productId] = null;
        }
      }
    }

    setState(() {
      productNames = names;
      productImages = images;
      isLoading = false;
    });
  }

  Widget _buildInvoiceDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey, size: 30),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: _buildBorderedCard(
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

  // Helper method to wrap content in a card with a border image (back2.png)
  Widget _buildBorderedCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/back2.png'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        // Inset the Card so the border image appears only as a border.
        child: Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 4,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = widget.invoiceData['orders'] as List;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Invoice Details',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey,
        elevation: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildBorderedCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInvoiceDetailRow(
                    Icons.calendar_today,
                    'Bill Date',
                    '${widget.invoiceData['billDate']}',
                  ),
                  const Divider(),
                  _buildInvoiceDetailRow(
                    Icons.monetization_on,
                    'Total Amount',
                    '₹${widget.invoiceData['totalAmount']}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Products Ordered',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 10),
          if (isLoading)
            ...List.generate(3, (index) => _buildShimmerEffect())
          else
            ...orders.map((order) {
              final productId = order['productId'];
              final productName = productNames[productId] ?? 'Loading...';
              final selectedSize =
                  order['selectedSize'] as Map<String, dynamic>? ?? {};

              return _buildBorderedCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      productImages[productId] != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          productImages[productId]!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shopping_cart,
                          size: 50,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Product Name
                      Text(
                        productName,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Selected Sizes and Quantity
                      ...selectedSize.entries.map((entry) {
                        return Text(
                          'Size: ${entry.key}  |  Qty: ${entry.value}',
                          style: GoogleFonts.montserrat(
                            color: Colors.grey[700],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
