import 'package:beplus/ViewBillScreen.dart';
import 'package:flutter/material.dart';

import 'CustomCustomerBill.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '          Customer Bills',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomBill(customerId: widget.customerId),
                  ),
                );
              },
              icon: Icon(
                Icons.edit,
                color: Colors.white,
              ),
              label: Text(
                '   Add Manually     ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                backgroundColor: Colors.teal.shade700,
                shadowColor: Colors.teal.shade200,
                surfaceTintColor: Colors.tealAccent,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                print("Scan the Document button pressed");
              },
              icon: Icon(
                Icons.camera_alt,
                color: Colors.white,
              ),
              label: Text(
                'Scan the Document',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                backgroundColor: Colors.teal.shade900,
                shadowColor: Colors.teal.shade300,
                surfaceTintColor: Colors.tealAccent,
              ),
            ),
            SizedBox(height: 40),
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
          elevation: 0, // Remove shadow
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Add Bills',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.view_list),
              label: 'View Bills',
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
