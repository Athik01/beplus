import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
class ManageParties extends StatefulWidget {
  final String userId;

  ManageParties({required this.userId});

  @override
  _ManagePartiesState createState() => _ManagePartiesState();
}

class _ManagePartiesState extends State<ManageParties>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DocumentSnapshot> newRequests = [];
  List<DocumentSnapshot> customers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRequests(); // Fetch requests at initialization
  }

  Future<void> _fetchRequests() async {
    if (widget.userId.isNotEmpty) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('ownerId', isEqualTo: widget.userId)
          .get();

      setState(() {
        newRequests = snapshot.docs
            .where((doc) => doc['status'] != 'Confirmed')
            .toList();
        customers = snapshot.docs
            .where((doc) => doc['status'] == 'Confirmed')
            .toList();
      });
    }
  }

  Future<Map<String, String>> _fetchUserDetails(String customerId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(customerId)
        .get();

    if (userSnapshot.exists) {
      var userData = userSnapshot.data() as Map<String, dynamic>;
      return {
        'name': userData['name'] ?? 'No name',
        'shopName': userData['shopName'] ?? 'No shop name',
        'mobile': userData['mobile'] ?? 'No mobile number',
      };
    } else {
      return {
        'name': 'User not found',
        'shopName': 'N/A',
        'mobile': 'N/A',
      };
    }
  }

  Widget _buildRequestCard(DocumentSnapshot request, bool showAcceptButton) {
    String customerId = request['customerId'] ?? 'Unknown';

    return FutureBuilder<Map<String, String>>(
      future: _fetchUserDetails(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Error fetching user details',
              style: GoogleFonts.montserrat(fontSize: 18, color: Colors.red),
            ),
          );
        }
        var userDetails = snapshot.data;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/back2.png'),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(16.0),
            ),
            // Padding here creates the "border width" effect
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Card(
                elevation: 8.0,
                color: Colors.transparent, // Make the card background transparent
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // White background for card content
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request from Customer:',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.account_circle, color: Colors.black54),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Name: ${userDetails?['name']}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.store, color: Colors.black54),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Shop Name: ${userDetails?['shopName']}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.black54),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mobile: ${userDetails?['mobile']}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      if (showAcceptButton) ...[
                        SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('requests')
                                    .doc(request.id)
                                    .update({'status': 'Confirmed'});

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Request confirmed successfully!',
                                        style: GoogleFonts.montserrat()),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                _fetchRequests();
                              } catch (error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to confirm request: $error',
                                        style: GoogleFonts.montserrat()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: Text(
                              'Accept Request',
                              style: GoogleFonts.montserrat(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with blue-grey background and Montserrat-styled title.
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Parties',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white, size: 28),
                onPressed: _fetchRequests,
                splashRadius: 24,
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          indicatorColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          tabs: [
            _buildTab(icon: Icons.list_alt, label: 'New Requests'),
            _buildTab(icon: Icons.people_alt, label: 'Customers'),
          ],
        ),
        elevation: 6,
      ),
      // Background with white fading image.
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
          TabBarView(
            controller: _tabController,
            children: [
              newRequests.isEmpty
                  ? Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 50,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Requests Available',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please check back later.',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: newRequests.length,
                itemBuilder: (context, index) {
                  return _buildRequestCard(newRequests[index], true);
                },
              ),
              customers.isEmpty
                  ? Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 50,
                            color: Colors.blueAccent,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Customers Found',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'There are no customers at the moment.',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  return _buildRequestCard(customers[index], false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
