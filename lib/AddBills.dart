import 'package:flutter/material.dart';
import 'package:beplus/ViewBillScreen.dart';
import 'package:beplus/recognizeMe.dart';
import 'CustomCustomerBill.dart';
import 'AddNewCreditScreen.dart';
import 'dart:ui';

class AddCustomerBills extends StatefulWidget {
  final String customerId;

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
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Customer Bills',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 5)
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004D40), Color(0xFF26A69A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _selectedIndex == 0
            ? _buildAddOptions()
            : ViewBillsScreen(),
      ),
      bottomNavigationBar: _buildFloatingTabBar(),
    );
  }

  Widget _buildAddOptions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Choose an option to proceed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.teal,
              fontStyle: FontStyle.italic,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          _customAnimatedButton(
            icon: Icons.edit,
            label: 'Add Manually',
            color: Colors.teal.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CustomBill(customerId: widget.customerId),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          _customAnimatedButton(
            icon: Icons.camera_alt,
            label: 'Scan Document',
            color: Colors.teal.shade900,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecognizeMeApp()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _customAnimatedButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      splashColor: Colors.tealAccent.withOpacity(0.4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFloatingTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      // Added a scale animation to the whole tab bar for an engaging entrance
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.shade800.withOpacity(0.85),
                    Colors.teal.shade400.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                // Enhanced the shadow for a deeper premium look
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white60,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 10,
                ),
                type: BottomNavigationBarType.fixed,
                onTap: _onItemTapped,
                items: [
                  BottomNavigationBarItem(
                    icon: _buildTabIcon(Icons.add, _selectedIndex == 0),
                    label: 'Add Bills',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildTabIcon(Icons.view_list, _selectedIndex == 1),
                    label: 'View Bills',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, bool isSelected) {
    // Added a scaling animation to each icon for a dynamic effect
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
          begin: isSelected ? 0.8 : 1.0, end: isSelected ? 1.0 : 0.8),
      duration: const Duration(milliseconds: 250),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.all(isSelected ? 6 : 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: Colors.tealAccent.withOpacity(0.4),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ]
                  : [],
            ),
            child: Icon(
              icon,
              size: isSelected ? 24 : 20,
              color: isSelected ? Colors.tealAccent : Colors.white70,
            ),
          ),
        );
      },
    );
  }

}
