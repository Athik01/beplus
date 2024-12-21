import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageStatements extends StatefulWidget {
  final String userId;

  ManageStatements({required this.userId});

  @override
  _ManageStatementsState createState() => _ManageStatementsState();
}

class _ManageStatementsState extends State<ManageStatements> {
  late Future<List<Statement>> _statements;

  @override
  void initState() {
    super.initState();
    _statements = fetchStatements(widget.userId);
  }

  Future<List<Statement>> fetchStatements(String userId) async {
    // Fetch statements from Firestore
    var querySnapshot = await FirebaseFirestore.instance
        .collection('statements')
        .where('ownerId', isEqualTo: userId)
        .get();

    return querySnapshot.docs
        .map((doc) => Statement.fromFirestore(doc.data()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Statements'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Statement>>(
        future: _statements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No statements found.'));
          }

          List<Statement> statements = snapshot.data!;

          return ListView.builder(
            itemCount: statements.length,
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title: ${statements[index].title}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Description: ${statements[index].description}',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      SizedBox(height: 10),
                      _buildStatRow('Balance', statements[index].balance),
                      _buildStatRow('Credit', statements[index].credit),
                      _buildStatRow('Debit', statements[index].debit),
                      SizedBox(height: 10),
                      SizedBox(height: 10),
                      _buildStatRow(
                        'Created At',
                        statements[index].createdAt.toDate().toLocal(),
                        isDate: true,
                      ),
                      _buildStatRow(
                        'Updated At',
                        statements[index].updatedAt.toDate().toLocal(),
                        isDate: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String title, dynamic value, {bool isDate = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          isDate ? _formatDate(value) : value.toString(),
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute}';
  }
}

class Statement {
  final String title;
  final String description;
  final double balance;
  final double credit;
  final double debit;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Statement({
    required this.title,
    required this.description,
    required this.balance,
    required this.credit,
    required this.debit,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create Statement from Firestore document
  factory Statement.fromFirestore(Map<String, dynamic> data) {
    return Statement(
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? 'No Description',
      balance: (data['balance'] != null) ? data['balance'].toDouble() : 0.0,
      credit: (data['credit'] != null) ? data['credit'].toDouble() : 0.0,
      debit: (data['debit'] != null) ? data['debit'].toDouble() : 0.0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }
}
