import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  String? userDocId;
  String fieldBeingEdited = ''; // Track the field being edited

  // Fields for editing
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController userTypeController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController gstNumberController = TextEditingController();
  TextEditingController shopNameController = TextEditingController();

  // Track original values for each field
  String? originalName,
      originalEmail,
      originalPhone,
      originalUserType,
      originalState,
      originalAddress,
      originalGstNumber,
      originalShopName;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  // Fetch user data from Firestore
  Future<void> _getUserData() async {
    User? user = FirebaseAuth.instance.currentUser; // Get the currently logged-in user

    if (user != null) {
      try {
        // Get user data from Firestore collection "users"
        DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          setState(() {
            userData = docSnapshot.data() as Map<String, dynamic>;
            userDocId = docSnapshot.id; // Store the document ID

            // Initialize controllers with current user data
            nameController.text = userData?['name'] ?? '';
            shopNameController.text = userData?['shopName'] ?? '';
            emailController.text = userData?['email'] ?? '';
            phoneController.text = userData?['mobile'] ?? '';
            userTypeController.text = userData?['userType'] ?? '';
            stateController.text = userData?['state'] ?? '';
            addressController.text = userData?['address'] ?? '';
            gstNumberController.text = userData?['gstNumber'] ?? '';

            // Save the original values for cancel functionality
            originalName = userData?['name'];
            originalShopName = userData?['shopName'];
            originalEmail = userData?['email'];
            originalPhone = userData?['mobile'];
            originalUserType = userData?['userType'];
            originalState = userData?['state'];
            originalAddress = userData?['address'];
            originalGstNumber = userData?['gstNumber'];
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    title: Text(
                      "Confirm Logout",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      "This action cannot be redone. All your data will be wiped out.",
                      style: GoogleFonts.montserrat(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false); // User cancels
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.blueGrey),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.montserrat(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true); // User confirms logout
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          "Logout",
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
              if (confirm == true) {
                // Sign out from Google
                await GoogleSignIn().signOut();
                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();
                // Clear stored app data (e.g., shared preferences)
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                // Navigate to the login screen (adjust route as needed)
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginApp()),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/back2.png',
              fit: BoxFit.cover,
            ),
          ),
          // Fading effect overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // Profile content wrapped in SafeArea to avoid overlapping the AppBar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image Section
                    _buildProfileImage(userData?['photoURL']),
                    const SizedBox(height: 20),
                    // Name Section
                    _buildUserInfoSection('Name', userData?['name'], Icons.person, 'name'),
                    const SizedBox(height: 20),
                    _buildUserInfoSection('Shop Name', userData?['shopName'], Icons.shop_2_outlined, 'shopName'),
                    const SizedBox(height: 20),
                    // Email Section
                    _buildUserInfoSection('Email', userData?['email'], Icons.email, 'email'),
                    const SizedBox(height: 20),
                    // Mobile Section
                    _buildUserInfoSection('Phone', userData?['mobile'], Icons.phone, 'mobile'),
                    const SizedBox(height: 20),
                    // Account Type Section
                    _buildUserInfoSection('Account Type', userData?['userType'], Icons.account_circle, 'userType'),
                    const SizedBox(height: 20),
                    // State Section
                    _buildUserInfoSection('State', userData?['state'], Icons.location_on, 'state'),
                    const SizedBox(height: 20),
                    // Address Section
                    _buildUserInfoSection('Address', userData?['address'], Icons.home, 'address'),
                    const SizedBox(height: 20),
                    // GST Number Section
                    _buildUserInfoSection('GST Number', userData?['gstNumber'], Icons.business, 'gstNumber'),
                    const SizedBox(height: 20),
                    // Save/Cancel Buttons
                    _buildSaveCancelButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build profile image section
  Widget _buildProfileImage(String? photoURL) {
    return CircleAvatar(
      radius: 70,
      backgroundColor: Colors.grey[200],
      backgroundImage: photoURL != null && photoURL.isNotEmpty
          ? NetworkImage(photoURL)
          : NetworkImage('https://www.w3schools.com/w3images/avatar2.png'),
    );
  }

  // Helper method to build each user info section with an optional icon
  Widget _buildUserInfoSection(String title, String? value, IconData? icon, String field) {
    bool isFieldBeingEdited = fieldBeingEdited == field;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.teal[600],
              size: 26,
            ),
            SizedBox(width: 16),
          ],
          Text(
            '$title: ',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: isFieldBeingEdited
                ? _buildEditableField(field)
                : Text(
              value ?? 'Not Available',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isFieldBeingEdited)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blueGrey),
              onPressed: () => _enableEditField(field),
            ),
        ],
      ),
    );
  }

  // Method to show the editable text field for each field
  Widget _buildEditableField(String field) {
    switch (field) {
      case 'name':
        return TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: GoogleFonts.montserrat(),
          ),
          style: GoogleFonts.montserrat(),
        );
      case 'shopName':
        return TextField(
          controller: shopNameController,
          decoration: InputDecoration(
            hintText: 'Enter Shop Name',
            hintStyle: GoogleFonts.montserrat(),
          ),
          style: GoogleFonts.montserrat(),
        );
      case 'email':
        return TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: GoogleFonts.montserrat(),
          ),
          style: GoogleFonts.montserrat(),
        );
      case 'mobile':
        return TextField(
          controller: phoneController,
          decoration: InputDecoration(
            hintText: 'Enter your phone',
            hintStyle: GoogleFonts.montserrat(),
          ),
          style: GoogleFonts.montserrat(),
        );
      case 'userType':
        return TextField(
          controller: userTypeController,
          decoration: InputDecoration(
            hintText: 'Enter your account type',
            hintStyle: GoogleFonts.montserrat(),
          ),
          style: GoogleFonts.montserrat(),
        );
      case 'state':
        return TextField(
          controller: stateController,
          decoration: InputDecoration(
            hintText: 'Enter your state',
            hintStyle: GoogleFonts.montserrat(),
          ),
          style: GoogleFonts.montserrat(),
        );
      case 'address':
        return TextField(
          controller: addressController,
          decoration: InputDecoration(
            hintText: 'Enter your address',
            hintStyle: GoogleFonts.montserrat(),
          ),
          style: GoogleFonts.montserrat(),
        );
      case 'gstNumber':
        return TextField(
          controller: gstNumberController,
          decoration: InputDecoration(
            hintText: 'Enter GST number',
            hintStyle: GoogleFonts.montserrat(),
          ),
          style: GoogleFonts.montserrat(),
        );
      default:
        return Container();
    }
  }

  // Method to show the save/cancel buttons
  Widget _buildSaveCancelButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Even spacing between buttons
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveChanges,
            icon: Icon(Icons.save, color: Colors.white),
            label: Text(
              'Save Changes',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(width: 16), // Space between buttons
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _cancelChanges,
            icon: Icon(Icons.cancel, color: Colors.white),
            label: Text(
              'Cancel Changes',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // Enable editing for a specific field
  void _enableEditField(String field) {
    setState(() {
      fieldBeingEdited = field;
    });
  }

  // Save changes to Firestore
  Future<void> _saveChanges() async {
    try {
      final updatedData = {
        'name': nameController.text,
        'shopName': shopNameController.text,
        'email': emailController.text,
        'mobile': phoneController.text,
        'userType': userTypeController.text,
        'state': stateController.text,
        'address': addressController.text,
        'gstNumber': gstNumberController.text,
      };

      await FirebaseFirestore.instance.collection('users').doc(userDocId).update(updatedData);

      // Update userData and reset fieldBeingEdited
      setState(() {
        userData = updatedData;
        fieldBeingEdited = ''; // Reset edit mode
      });
      _showSuccessDialog('Changes saved successfully.');
    } catch (e) {
      _showErrorDialog('Failed to save changes.');
    }
  }

  // Cancel changes and revert to original data
  void _cancelChanges() {
    setState(() {
      // Revert to the original values
      nameController.text = originalName ?? '';
      shopNameController.text = originalShopName ?? '';
      emailController.text = originalEmail ?? '';
      phoneController.text = originalPhone ?? '';
      userTypeController.text = originalUserType ?? '';
      stateController.text = originalState ?? '';
      addressController.text = originalAddress ?? '';
      gstNumberController.text = originalGstNumber ?? '';
      fieldBeingEdited = ''; // Reset edit mode
    });
  }

  // Show success dialog
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text(
                'Success',
                style: GoogleFonts.montserrat(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.montserrat(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: GoogleFonts.montserrat(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'Error',
                style: GoogleFonts.montserrat(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.montserrat(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: GoogleFonts.montserrat(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
