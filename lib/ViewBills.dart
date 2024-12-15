import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:horizontal_week_calendar/horizontal_week_calendar.dart';
class ViewBills extends StatefulWidget {
  final String customerId;
  final String ownerId;

  ViewBills({required this.customerId, required this.ownerId});

  @override
  _ViewBillsState createState() => _ViewBillsState();
}

class _ViewBillsState extends State<ViewBills> {
  String? pdfBase64;
  Uint8List? pdfBytes;
  String? localPath;
  bool isLoading = true;
  bool isError = false;
  bool isPdfVisible = false;
  String? selectedOrderDate;
  DateTime selectedDate = DateTime.now();
  bool isCalendarVisible = false; // Controls the visibility of the calendar
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
          .where('ownerId', isEqualTo: widget.ownerId)
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
        throw 'No bill founds';
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

  List<Map<String, dynamic>> billsData = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '       View & Share Bills',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
        actions: [
          Visibility(
            visible: !isPdfVisible, // Hide the icon when isPdfVisible is true
            child: IconButton(
              icon: Icon(Icons.filter_list, color: Colors.white),
              tooltip: 'Filter',
              onPressed: () {
                setState(() {
                  isCalendarVisible = !isCalendarVisible; // Toggle calendar visibility
                });
              },
            ),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade200, Colors.teal.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Horizontal Calendar, displayed on top when visible
                if (isCalendarVisible)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ), // Rounded corners for the container
                      ),
                      child: HorizontalWeekCalendar(
                        minDate: DateTime.now().subtract(Duration(days: 30)),
                        maxDate: DateTime.now().add(Duration(days: 30)),
                        initialDate: selectedDate,
                        onDateChange: (date) {
                          setState(() {
                            selectedDate = date;
                            isCalendarVisible = false;
                          });
                        },
                      ),
                    ),
                  ),
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
      ),
    );
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

      // Compare only the date part (year-month-day)
      return DateFormat('yyyy-MM-dd').format(parsedDate) == DateFormat('yyyy-MM-dd').format(selectedDate);
    }).toList();
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
              Icon(
                Icons.warning_rounded, // You can choose a different icon
                size: 40,
                color: Colors.orange,
              ),
              SizedBox(height: 15),
              Text(
                'No Bills Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'It looks like you have no bills at the moment. Try adding some!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
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
        TimeOfDay orderTime;
        // Convert Timestamp to DateTime if orderDate is a Timestamp
        DateTime parsedDate;
        if (orderDate is Timestamp) {
          parsedDate = orderDate.toDate(); // Convert Timestamp to DateTime
        } else if (orderDate is DateTime) {
          parsedDate = orderDate; // If it's already a DateTime object
        } else {
          parsedDate = DateTime.now(); // Default to current date if the type is unexpected
        }
        orderTime = TimeOfDay(
          hour: parsedDate.hour,
          minute: parsedDate.minute,
        );
        // Format the parsed DateTime
        String formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);
        String dayOfWeek = DateFormat('EEEE').format(parsedDate); // Get the day of the week

        return Card(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          color: Colors.teal.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.teal, size: 26),
                    SizedBox(width: 10),
                    Text(
                      'Order Date: $formattedDate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.today, color: Colors.teal, size: 26),
                    SizedBox(width: 10),
                    Text(
                      'Day: $dayOfWeek',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.teal, size: 26), // Icon for time
                    SizedBox(width: 10),
                    Text(
                      'Order Time: ${orderTime.format(context)}', // Display the time in a readable format
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _loadPdf(filteredBills[index]['pdfBase64']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700, // Button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.picture_as_pdf, size: 20, color: Colors.white),
                    label: Text(
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
        Text(
          'Your Bill',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 20),
        Container(
          height: 500,
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PDFView(
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
                  SnackBar(content: Text('Error loading PDF')),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _sharePdf,
          icon: Icon(Icons.share),
          label: Text('Share Bill'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.teal.shade800,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
        Icon(Icons.error, size: 60, color: Colors.red),
        SizedBox(height: 20),
        Text(
          'Something went wrong!',
          style: TextStyle(fontSize: 22, color: Colors.red),
        ),
        SizedBox(height: 10),
        Text(
          'Unable to fetch the bill. Please try again.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _retryFetchBill,
          child: Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
