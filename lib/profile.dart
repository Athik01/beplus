import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  String? originalName, originalEmail, originalPhone, originalUserType, originalState, originalAddress, originalGstNumber, originalShopName;

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
        DocumentSnapshot docSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

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
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Colors.white, // Set title font color to white
          ),
        ),
        centerTitle: true, // This centers the title
        backgroundColor: Colors.blueGrey, // Set background color to black
      ),
      body:
    Container(
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [Colors.white, Colors.grey.shade800],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ),
    ),child:userData == null
          ? Center(child: CircularProgressIndicator()) // Show loading while data is being fetched
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image Section
              _buildProfileImage(userData?['photoURL']),
              SizedBox(height: 20),

              // Name Section
              _buildUserInfoSection('Name', userData?['name'], Icons.person, 'name'),
              SizedBox(height: 20),

              _buildUserInfoSection('Shop Name', userData?['shopName'], Icons.shop_2_outlined, 'shopName'),
              SizedBox(height: 20),

              // Email Section
              _buildUserInfoSection('Email', userData?['email'], Icons.email, 'email'),
              SizedBox(height: 20),

              // Mobile Section
              _buildUserInfoSection('Phone', userData?['mobile'], Icons.phone, 'mobile'),
              SizedBox(height: 20),

              // Account Type Section
              _buildUserInfoSection('Account Type', userData?['userType'], Icons.account_circle, 'userType'),
              SizedBox(height: 20),

              // State Section
              _buildUserInfoSection('State', userData?['state'], Icons.location_on, 'state'),
              SizedBox(height: 20),

              // Address Section
              _buildUserInfoSection('Address', userData?['address'], Icons.home, 'address'),
              SizedBox(height: 20),

              // GST Number Section
              _buildUserInfoSection('GST Number', userData?['gstNumber'], Icons.business, 'gstNumber'),
              SizedBox(height: 20),

              // Save/Cancel Buttons
              _buildSaveCancelButtons(),
            ],
          ),
        ),
      ),
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
          : const NetworkImage('https://www.w3schools.com/w3images/avatar2.png'),
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
              color: Colors.blueGrey[600],
              size: 26,
            ),
            SizedBox(width: 16),
          ],
          Text(
            '$title: ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey[800],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: isFieldBeingEdited
                ? _buildEditableField(field)
                : Text(
              value ?? 'Not Available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blueGrey[600],
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
          decoration: InputDecoration(hintText: 'Enter your name'),
        );
      case 'shopName':
        return TextField(
          controller: shopNameController,
          decoration: InputDecoration(hintText: 'Enter Shop Name'),
        );
      case 'email':
        return TextField(
          controller: emailController,
          decoration: InputDecoration(hintText: 'Enter your email'),
        );
      case 'mobile':
        return TextField(
          controller: phoneController,
          decoration: InputDecoration(hintText: 'Enter your phone'),
        );
      case 'userType':
        return TextField(
          controller: userTypeController,
          decoration: InputDecoration(hintText: 'Enter your account type'),
        );
      case 'state':
        return TextField(
          controller: stateController,
          decoration: InputDecoration(hintText: 'Enter your state'),
        );
      case 'address':
        return TextField(
          controller: addressController,
          decoration: InputDecoration(hintText: 'Enter your address'),
        );
      case 'gstNumber':
        return TextField(
          controller: gstNumberController,
          decoration: InputDecoration(hintText: 'Enter GST number'),
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
              style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
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
              style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)), // Rounded corners
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green), // Success icon
              SizedBox(width: 10),
              Text(
                'Success',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)), // Rounded corners
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red), // Error icon
              SizedBox(width: 10),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
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
