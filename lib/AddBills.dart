import 'package:beplus/ViewBillScreen.dart';
import 'package:beplus/recognizeMe.dart';
import 'package:flutter/material.dart';
import 'CustomCustomerBill.dart';
import 'AddNewCreditScreen.dart';  // Import the new credit screen
import 'package:excel/excel.dart';
class AddCustomerBills extends StatefulWidget {
  final String customerId;

  // Constructor to accept customerId as input
  AddCustomerBills({required this.customerId});

  @override
  _AddCustomerBillsState createState() => _AddCustomerBillsState();
}

class _AddCustomerBillsState extends State<AddCustomerBills> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // If Credit Note is tapped (index 2), navigate to AddNewCreditScreen
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddNewCreditScreen(userId: widget.customerId),  // Pass customerId as userId
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '            Customer Bills',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade200, Colors.teal.shade900],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
      ),
      body: Center(
        child: _selectedIndex == 0
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Choose an option to proceed',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CustomBill(customerId: widget.customerId),
                          ),
                        );
                      },
                      icon: Icon(Icons.edit, color: Colors.white),
                      label: Text(
                        'Add Manually',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                        shadowColor: Colors.teal.shade300,
                        backgroundColor: Colors.teal.shade700,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecognizeMeApp(),
                          ),
                        );
                      },
                      icon: Icon(Icons.camera_alt, color: Colors.white),
                      label: Text(
                        'Scan Document',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                        shadowColor: Colors.teal.shade300,
                        backgroundColor: Colors.teal.shade900,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        )
            : ViewBillsScreen(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade200, Colors.teal.shade900],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Add Bills',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.view_list),
              label: 'View Bills',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.currency_rupee),  // Coin icon
              label: 'Credit Note',  // Credit Note label
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
