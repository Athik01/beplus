import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Widget _buildRequestCard(
      DocumentSnapshot request, bool showAcceptButton) {
    String customerId = request['customerId'] ?? 'Unknown';

    return FutureBuilder<Map<String, String>>(
      future: _fetchUserDetails(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Error fetching user details',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          );
        }

        var userDetails = snapshot.data;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff004d40), Color(0xff008080), Color(0xffF5F5F5)], // Dark teal → Teal → Light gray
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
                padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request from Customer:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffF5F5F5),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.account_circle, color: Color(0xffF5F5F5)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Name: ${userDetails?['name']}',
                          style: TextStyle(
                              fontSize: 16, color: Color(0xffF5F5F5)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.store, color: Color(0xffF5F5F5)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Shop Name: ${userDetails?['shopName']}',
                          style: TextStyle(
                              fontSize: 16, color: Color(0xffF5F5F5)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Color(0xffF5F5F5)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mobile: ${userDetails?['mobile']}',
                          style: TextStyle(
                              fontSize: 16, color: Color(0xffF5F5F5)),
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
                                content:
                                Text('Request confirmed successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            _fetchRequests();
                          } catch (error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Failed to confirm request: $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff282828),  // Dark gray for button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          'Accept Request',
                          style: TextStyle(fontSize: 16, color: Color(0xffF5F5F5)),  // Light gray text for button
                        ),
                      ),
                      ),
                  ],
                ],
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
          Icon(icon, size: 20, color: Colors.teal.shade300),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade300,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Parties',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 0.5, // Better text spacing
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white, size: 28), // Slightly larger icon
                onPressed: _fetchRequests,
                splashRadius: 24, // Better touch target
              ),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12), // Rounded edges for active tab
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          indicatorColor: Colors.transparent, // Hide default indicator
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white.withOpacity(0.8),
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          tabs: [
            _buildTab(icon: Icons.list_alt, label: 'New Requests'),
            _buildTab(icon: Icons.people_alt, label: 'Customers'),
          ],
        ),
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          newRequests.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded, // Icon for "No Requests"
                  size: 50,
                  color: Colors.orange,
                ),
                SizedBox(height: 16),
                Text(
                  'No Requests Available',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please check back later.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline_rounded, // Icon for "No Customers"
                  size: 50,
                  color: Colors.blueAccent,
                ),
                SizedBox(height: 16),
                Text(
                  'No Customers Found',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'There are no customers at the moment.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
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
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
