import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OwnerDetailsPage extends StatefulWidget {
  final String ownerId;

  const OwnerDetailsPage({Key? key, required this.ownerId}) : super(key: key);

  @override
  _OwnerDetailsPageState createState() => _OwnerDetailsPageState();
}

class _OwnerDetailsPageState extends State<OwnerDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Owner Details',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.info_outline, color: Colors.white, size: 23),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blueGrey),
                            SizedBox(width: 10),
                            Text(
                              'Owner Information',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.blueGrey.shade800,
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'Here, you will find a brief overview of the owner\'s details and background.',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'CLOSE',
                              style: GoogleFonts.montserrat(color: Colors.white),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      );
                    });
              }),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.ownerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading owner details',
                style: GoogleFonts.montserrat(color: Colors.red, fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Owner details not found',
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }
          final ownerData = snapshot.data!.data() as Map<String, dynamic>;
          final name = ownerData['name'] ?? 'N/A';
          final shopName = ownerData['shopName'] ?? 'N/A';
          final profilePicUrl = ownerData['photoURL'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Picture & Name Section
                Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profilePicUrl != null
                          ? NetworkImage(profilePicUrl)
                          : NetworkImage('https://www.w3schools.com/howto/img_avatar.png'),
                      backgroundColor: Colors.grey[300],
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Owner',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Shop Name Section with Border Image
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage('lib/assets/back2.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.store, color: Colors.blueGrey, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Shop Name: $shopName',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // TabBar
                TabBar(
                  controller: _tabController,
                  labelStyle: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 16),
                  indicatorColor: Colors.blueGrey.shade800,
                  tabs: [
                    Tab(text: 'Contact Info'),
                    Tab(text: 'Products'),
                  ],
                ),
                SizedBox(height: 16),
                // TabBarView
                Container(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Contact Information Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: AssetImage('lib/assets/back2.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.94),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.blueGrey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Contact Information',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.phone, color: Colors.blueGrey.shade700, size: 24),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Phone: ${ownerData['mobile'] ?? 'N/A'}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.email, color: Colors.blueGrey.shade700, size: 24),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Email: ${ownerData['email'] ?? 'N/A'}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.my_location, color: Colors.blueGrey, size: 24),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Location: ${ownerData['address'] ?? 'N/A'}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.place, color: Colors.blueGrey, size: 24),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'State: ${ownerData['state'] ?? 'N/A'}',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Products Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(19.0),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('products').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
                            final products = snapshot.data!.docs
                                .where((doc) =>
                            doc['userId'] == widget.ownerId &&
                                (doc['visibility'] as List).contains(currentUserId))
                                .toList();
                            if (products.isEmpty) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: AssetImage('lib/assets/back2.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.94),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'No products available for you at the moment.',
                                      style: GoogleFonts.montserrat(fontSize: 16, color: Colors.black54),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Column(
                              children: products.map((product) {
                                final data = product.data() as Map<String, dynamic>;
                                final imageBytes = base64Decode(data['imageUrl'] ?? "");
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    image: DecorationImage(
                                      image: AssetImage('lib/assets/back2.png'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.94),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.memory(
                                              imageBytes,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  data['name'] ?? 'No Name',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.blueGrey.shade900,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  data['description'] ?? 'No Description',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 14,
                                                    color: Colors.black54,
                                                    height: 1.5,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blueGrey.shade100.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'Category: ${data['category'] ?? 'N/A'}',
                                                    style: GoogleFonts.montserrat(
                                                      fontSize: 12,
                                                      color: Colors.blueGrey,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
