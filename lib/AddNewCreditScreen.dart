import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

// Add New Credit Screen
class AddNewCreditScreen extends StatefulWidget {
  final String userId;
  AddNewCreditScreen({required this.userId});

  @override
  _AddNewCreditScreenState createState() => _AddNewCreditScreenState();
}

class _AddNewCreditScreenState extends State<AddNewCreditScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _creditController = TextEditingController();

  Future<void> _submitCredit() async {
    String username = _usernameController.text;
    String credit = _creditController.text;

    if (username.isEmpty || credit.isEmpty) {
      _showSnackbar('Please enter both username and credit', Colors.redAccent);
      return;
    }

    try {
      // Check if a document with the same username exists in the 'credit' collection
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('credit')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Username exists; update credit
        DocumentSnapshot doc = snapshot.docs.first;
        int existingCredit = doc['credit'] ?? 0;
        int newCredit = int.parse(credit);
        int updatedCredit = existingCredit + newCredit;

        await FirebaseFirestore.instance.collection('credit').doc(doc.id).update({
          'credit': updatedCredit,
        });

        _showSnackbar('Credit updated successfully', Colors.green);
      } else {
        // Create new document
        await FirebaseFirestore.instance.collection('credit').add({
          'userId': widget.userId,
          'username': username,
          'credit': int.parse(credit),
          'timestamp': FieldValue.serverTimestamp(),
        });
        _showSnackbar('Credit added successfully', Colors.green);
      }

      _usernameController.clear();
      _creditController.clear();
    } catch (e) {
      _showSnackbar('Failed to add/update credit: $e', Colors.redAccent);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueGrey.shade700),
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.shade700, width: 2),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitCredit,
      child: Text('Submit Credit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey.shade700,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: Text('Add New Credit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              // Glass container effect
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View Credit Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ViewCreditScreen(userId: widget.userId)),
                          ),
                          icon: Icon(Icons.credit_card, color: Colors.blueGrey.shade700),
                          label: Text('View Credit', style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade700)),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            side: BorderSide(color: Colors.blueGrey.shade700, width: 2),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildTextField(_usernameController, 'Enter Username', Icons.person),
                      SizedBox(height: 20),
                      _buildTextField(_creditController, 'Enter Credit', Icons.currency_rupee, isNumeric: true),
                      SizedBox(height: 30),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// View Credit Screen
class ViewCreditScreen extends StatefulWidget {
  final String userId;
  ViewCreditScreen({required this.userId});

  @override
  _ViewCreditScreenState createState() => _ViewCreditScreenState();
}

class _ViewCreditScreenState extends State<ViewCreditScreen> {
  List<Map<String, dynamic>> _credits = [];
  List<Map<String, dynamic>> _filteredCredits = [];
  TextEditingController _searchController = TextEditingController();
  double? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _viewCredits();
  }

  Future<void> _viewCredits() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('credit')
          .where('userId', isEqualTo: widget.userId)
          .get();

      setState(() {
        _credits = snapshot.docs.map((doc) => {
          'creditId': doc.id,
          'username': doc['username'],
          'credit': double.tryParse(doc['credit'].toString()) ?? 0.0,
        }).toList();
        _filteredCredits = List.from(_credits);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load credits: $e')),
      );
    }
  }

  void _filterCredits() {
    setState(() {
      _filteredCredits = _credits.where((credit) {
        bool matchesSearch = credit['username']
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
        bool matchesFilter = _selectedFilter == null || credit['credit'] >= _selectedFilter!;
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: Text('View Credit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Username',
                prefixIcon: Icon(Icons.search, color: Colors.blueGrey.shade700),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (value) => _filterCredits(),
            ),
            SizedBox(height: 10),
            // Filter Dropdown
            DropdownButton<double>(
              value: _selectedFilter,
              hint: Text("Filter by Credit Amount"),
              isExpanded: true,
              items: [100, 500, 1000].map((value) => value.toDouble()).map((value) {
                return DropdownMenuItem<double>(
                  value: value,
                  child: Text("Credits >= $value"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value;
                  _filterCredits();
                });
              },
            ),
            SizedBox(height: 10),
            // Credit List
            Expanded(
              child: _filteredCredits.isEmpty
                  ? Center(child: Text('No credit information available.', style: TextStyle(fontSize: 18)))
                  : ListView.builder(
                itemCount: _filteredCredits.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.person, color: Colors.blueGrey.shade700),
                      title: Text(_filteredCredits[index]['username'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Credit: ${_filteredCredits[index]['credit']}', style: TextStyle(fontSize: 16)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreditDetailScreen(
                              creditId: _filteredCredits[index]['creditId'],
                              username: _filteredCredits[index]['username'],
                              credit: _filteredCredits[index]['credit'],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Credit Detail Screen
class CreditDetailScreen extends StatefulWidget {
  final String creditId;
  final String username;
  final double credit;

  CreditDetailScreen({
    required this.creditId,
    required this.username,
    required this.credit,
  });

  @override
  _CreditDetailScreenState createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends State<CreditDetailScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  List<String> _descriptions = [];
  List<String> _selectedDescriptions = [];
  bool _isInDeleteMode = false;

  @override
  void initState() {
    super.initState();
    _fetchDescriptions();
  }

  Future<void> _fetchDescriptions() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('credit')
          .doc(widget.creditId)
          .get();

      if (doc.exists) {
        List<dynamic> descriptions = doc['descriptions'] ?? [];
        setState(() {
          _descriptions = descriptions.cast<String>();
        });
      }
    } catch (e) {
      // Handle error if necessary
    }
  }

  Future<void> _addDescription() async {
    String description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('credit').doc(widget.creditId).update({
        'descriptions': FieldValue.arrayUnion([description]),
      });

      setState(() {
        _descriptions.add(description);
        _descriptionController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Description added successfully!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 6,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add description: $e')),
      );
    }
  }

  void _toggleDeleteMode() {
    setState(() {
      _isInDeleteMode = !_isInDeleteMode;
      if (!_isInDeleteMode) {
        _selectedDescriptions.clear();
      }
    });
  }

  void _toggleDescriptionSelection(String description) {
    setState(() {
      if (_selectedDescriptions.contains(description)) {
        _selectedDescriptions.remove(description);
      } else {
        _selectedDescriptions.add(description);
      }
    });
  }

  Future<void> _deleteSelectedDescriptions() async {
    try {
      await FirebaseFirestore.instance.collection('credit').doc(widget.creditId).update({
        'descriptions': FieldValue.arrayRemove(_selectedDescriptions),
      });

      setState(() {
        _descriptions.removeWhere((description) => _selectedDescriptions.contains(description));
        _selectedDescriptions.clear();
      });

      _toggleDeleteMode();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Selected descriptions deleted!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 6,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete descriptions: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: Text('Credit Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
            SizedBox(height: 5),
            Text(widget.username, style: TextStyle(fontSize: 18)),
            SizedBox(height: 15),
            Text('Credit Amount:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
            SizedBox(height: 5),
            Text(widget.credit.toString(), style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text('Descriptions:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
            SizedBox(height: 5),
            Expanded(
              child: _descriptions.isEmpty
                  ? Center(child: Text('No descriptions available.', style: TextStyle(fontSize: 16)))
                  : ListView.builder(
                itemCount: _descriptions.length,
                itemBuilder: (context, index) {
                  String description = _descriptions[index];
                  bool isSelected = _selectedDescriptions.contains(description);
                  return GestureDetector(
                    onLongPress: _toggleDeleteMode,
                    onTap: _isInDeleteMode ? () => _toggleDescriptionSelection(description) : null,
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(Icons.note, color: Colors.blueGrey.shade700),
                        title: Text(description, style: TextStyle(fontSize: 16)),
                        trailing: _isInDeleteMode
                            ? CircleAvatar(
                          radius: 15,
                          backgroundColor: isSelected ? Colors.red : Colors.grey.shade300,
                          child: isSelected ? Icon(Icons.check, color: Colors.white, size: 18) : null,
                        )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            if (_isInDeleteMode) ...[
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    child: ElevatedButton.icon(
                      onPressed: _deleteSelectedDescriptions,
                      icon: Icon(Icons.delete, color: Colors.white),
                      label: Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 6,
                        shadowColor: Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    child: ElevatedButton.icon(
                      onPressed: _toggleDeleteMode,
                      icon: Icon(Icons.cancel, color: Colors.white),
                      label: Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 6,
                        shadowColor: Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Enter a new description...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: _addDescription,
                child: Text('Add Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade700,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
