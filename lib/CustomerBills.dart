import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:horizontal_week_calendar/horizontal_week_calendar.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewCustomerBills extends StatefulWidget {
  final String customerId;

  ViewCustomerBills({required this.customerId});

  @override
  _ViewBillsState createState() => _ViewBillsState();
}

class _ViewBillsState extends State<ViewCustomerBills> {
  String? pdfBase64;
  Uint8List? pdfBytes;
  String? localPath;
  bool isLoading = true;
  bool isError = false;
  bool isPdfVisible = false;
  String? selectedOrderDate;
  DateTime selectedDate = DateTime.now();
  bool isCalendarVisible = false; // Controls the visibility of the calendar
  List<Map<String, dynamic>> billsData = [];

  @override
  void initState() {
    super.initState();
    _fetchBillData();
  }

  Future<void> _fetchBillData() async {
    try {
      var billQuery = await FirebaseFirestore.instance
          .collection('bills')
          .where('customerId', isEqualTo: widget.customerId)
          .get();

      if (billQuery.docs.isNotEmpty) {
        List<Map<String, dynamic>> bills = [];
        for (var bill in billQuery.docs) {
          var billData = bill.data();
          if (billData['pdfBase64'] != null) {
            bills.add({
              'orderDate': billData['billDate'], // Assuming there's an 'orderDate' field
              'pdfBase64': billData['pdfBase64']
            });
          }
        }

        if (bills.isNotEmpty) {
          setState(() {
            isLoading = false;
            billsData = bills;
          });
        } else {
          throw 'PDF data is empty';
        }
      } else {
        throw 'No bills found';
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _loadPdf(String base64Data) async {
    pdfBase64 = base64Data;
    pdfBytes = base64Decode(pdfBase64!);
    final path = await _savePdfToFile(pdfBytes!);
    setState(() {
      localPath = path;
      isPdfVisible = true;
    });
  }

  Future<String> _savePdfToFile(Uint8List pdfData) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/bill.pdf');
    await file.writeAsBytes(pdfData);
    return file.path;
  }

  void _retryFetchBill() {
    setState(() {
      isLoading = true;
      isError = false;
    });
    _fetchBillData();
  }

  Future<void> _sharePdf() async {
    if (localPath != null) {
      await Share.shareXFiles([XFile(localPath!)], text: 'Here is your bill!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file available to share.')),
      );
    }
  }

  List _getFilteredBills() {
    return billsData.where((bill) {
      var orderDate = bill['orderDate'];
      DateTime parsedDate;

      // Handle possible timestamp or DateTime
      if (orderDate is Timestamp) {
        parsedDate = orderDate.toDate();
      } else if (orderDate is DateTime) {
        parsedDate = orderDate;
      } else {
        parsedDate = DateTime.now();
      }
      // Compare only the date part
      return DateFormat('yyyy-MM-dd').format(parsedDate) ==
          DateFormat('yyyy-MM-dd').format(selectedDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
          ),
          elevation: 0,
          title: Center(
            child: Text(
              'View & Share Bills',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Visibility(
              visible: !isPdfVisible,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  splashColor: Colors.blueGrey.withOpacity(0.3),
                  onTap: () {
                    setState(() {
                      isCalendarVisible = !isCalendarVisible;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade800,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background Image (if bill-specific, else you can change to a common asset)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/back2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // BlueGrey Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blueGrey.shade900.withOpacity(0.9),
                  Colors.blueGrey.shade700.withOpacity(0.7),
                  Colors.blueGrey.shade500.withOpacity(0.7),
                  Colors.blueGrey.shade900.withOpacity(0.9),
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Calendar Section
                  if (isCalendarVisible)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: HorizontalWeekCalendar(
                        minDate: DateTime.now().subtract(const Duration(days: 30)),
                        maxDate: DateTime.now().add(const Duration(days: 30)),
                        initialDate: selectedDate,
                        onDateChange: (date) {
                          setState(() {
                            selectedDate = date;
                            isCalendarVisible = false;
                          });
                        },
                      ),
                    ),
                  // Main Content Display
                  Expanded(
                    child: Center(
                      child: isLoading
                          ? _buildLoadingState()
                          : isError
                          ? _buildErrorState()
                          : isPdfVisible
                          ? _buildEnhancedPdfView()
                          : _buildOrderList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    List filteredBills = _getFilteredBills();
    if (filteredBills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_rounded,
                size: 40,
                color: Colors.orange,
              ),
              const SizedBox(height: 15),
              Text(
                'No Bills Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'It looks like you have no bills at the moment. Try adding some!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: filteredBills.length,
      itemBuilder: (context, index) {
        var orderDate = filteredBills[index]['orderDate'];
        DateTime parsedDate;
        if (orderDate is Timestamp) {
          parsedDate = orderDate.toDate();
        } else if (orderDate is DateTime) {
          parsedDate = orderDate;
        } else {
          parsedDate = DateTime.now();
        }
        String formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);
        String dayOfWeek = DateFormat('EEEE').format(parsedDate);
        TimeOfDay orderTime = TimeOfDay(hour: parsedDate.hour, minute: parsedDate.minute);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          color: Colors.blueGrey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blueGrey, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'Order Date: $formattedDate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.today, color: Colors.blueGrey, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'Day: $dayOfWeek',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blueGrey, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'Order Time: ${orderTime.format(context)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _loadPdf(filteredBills[index]['pdfBase64']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.white),
                    label: const Text(
                      'View Bill',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedPdfView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Glassmorphism-style PDF Container
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Semi-transparent background
              Container(
                height: 620,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              ),
              // Apply the blur effect
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 620,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: localPath == null
                        ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.blueGrey),
                      ),
                    )
                        : PDFView(
                      filePath: localPath!,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: true,
                      pageFling: true,
                      onError: (error) {
                        setState(() {
                          isError = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error loading PDF')),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        // Enhanced Share Button with Gradient and Shadow
        ElevatedButton.icon(
          onPressed: _sharePdf,
          icon: const Icon(Icons.share, size: 24, color: Colors.blueGrey),
          label: const Text(
            'Share Bill',
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 10,
            shadowColor: Colors.black54,
            backgroundColor: Colors.transparent,
          ).copyWith(
            backgroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.pressed)) {
                return Colors.blueGrey.shade700;
              }
              return null;
            }),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          'Fetching your bill...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error, size: 60, color: Colors.red),
        const SizedBox(height: 20),
        const Text(
          'Something went wrong!',
          style: TextStyle(fontSize: 22, color: Colors.red),
        ),
        const SizedBox(height: 10),
        const Text(
          'Unable to fetch the bill. Please try again.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _retryFetchBill,
          child: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
