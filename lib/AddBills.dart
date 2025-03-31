import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:beplus/ViewBillScreen.dart';
import 'package:beplus/recognizeMe.dart';
import 'CustomCustomerBill.dart';
import 'AddNewCreditScreen.dart';
import 'package:google_fonts/google_fonts.dart';

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
      // Wrap the body in a Stack to include the background image and a white-fading overlay
      body: Stack(
        children: [
          // Background image from assets
          Positioned.fill(
            child: Image.asset(
              'lib/assets/back.png',
              fit: BoxFit.cover,
            ),
          ),
          // White fading overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Main content area with the animated switcher
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _selectedIndex == 0
                      ? _buildGlassAddOptions()  // Updated method with glass container
                      : ViewBillsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildFloatingTabBar(),
    );
  }

  // Custom AppBar with gradient background and shader title
  Widget _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Customer Bills',
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 1.2,
          foreground: Paint()
            ..shader = LinearGradient(
              colors: [Colors.white, Colors.grey.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
          shadows: [
            Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 5)
          ],
        ),
      ),
      backgroundColor: Colors.blueGrey, // Set solid blueGrey background
    );
  }

  // New method that wraps the add options in a glass container (frosted glass effect)
  Widget _buildGlassAddOptions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose an option to proceed',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1,
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _customAnimatedButton(
                    icon: Icons.edit,
                    label: 'Add Manually',
                    color: Colors.blueGrey.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomBill(customerId: widget.customerId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _customAnimatedButton(
                    icon: Icons.camera_alt,
                    label: 'Scan Document',
                    color: Colors.blueGrey.shade900,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RecognizeMeApp()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
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
      splashColor: Colors.white.withOpacity(0.4),
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
              style: GoogleFonts.montserrat(
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
                    Colors.blueGrey.shade800.withOpacity(0.85),
                    Colors.blueGrey.shade400.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
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
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ]
                  : [],
            ),
            child: Icon(
              icon,
              size: isSelected ? 24 : 20,
              color: isSelected ? Colors.black : Colors.white70,
            ),
          ),
        );
      },
    );
  }
}
