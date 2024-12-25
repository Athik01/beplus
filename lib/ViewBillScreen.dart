import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:intl/intl.dart'; // For formatting dates and file sizes

class ViewBillsScreen extends StatefulWidget {
  @override
  _ViewBillsScreenState createState() => _ViewBillsScreenState();
}

class _ViewBillsScreenState extends State<ViewBillsScreen> {
  List<FileSystemEntity> billFiles = [];
  bool isLoading = true;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchBills();
  }

  Future<void> fetchBills() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final beplusDir = Directory('${appDocDir.path}/BEplus');

      if (await beplusDir.exists()) {
        final files = beplusDir.listSync();
        final filteredFiles = files.where((file) {
          final fileStat = file.statSync();
          if (selectedDate != null) {
            final fileDate = fileStat.modified;
            return fileDate != null &&
                fileDate.year == selectedDate!.year &&
                fileDate.month == selectedDate!.month &&
                fileDate.day == selectedDate!.day;
          }
          return true;
        }).toList();

        setState(() {
          billFiles = filteredFiles;
          isLoading = false;
        });
      } else {
        setState(() {
          billFiles = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching bills: $e");
      setState(() {
        billFiles = [];
        isLoading = false;
      });
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        fetchBills(); // Refresh the list after deletion
      }
    } catch (e) {
      print("Error deleting file: $e");
    }
  }

  void openFile(String path) {
    OpenFile.open(path);
  }

  void _selectDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    fetchBills();
  }

  String formatFileSize(int bytes) {
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double fileSize = bytes.toDouble();
    while (fileSize >= 1024 && i < sizes.length - 1) {
      fileSize /= 1024;
      i++;
    }
    return '${fileSize.toStringAsFixed(1)} ${sizes[i]}';
  }

  void showDeleteConfirmation(String fileName, String filePath) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade100],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.redAccent,
                size: 50,
              ),
              SizedBox(height: 15),
              Text(
                'Delete File',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Are you sure you want to delete "$fileName"?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(Icons.cancel, color: Colors.white),
                    label: Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16,color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close the bottom sheet
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(Icons.delete_forever, color: Colors.white),
                    label: Text(
                      'Delete',
                      style: TextStyle(fontSize: 16,color:Colors.white),
                    ),
                    onPressed: () {
                      deleteFile(filePath);
                      Navigator.pop(context); // Close the bottom sheet
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade200, Colors.teal.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: CalendarTimeline(
                initialDate: DateTime.now(),
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2101, 12, 31),
                onDateSelected: _selectDate,
                leftMargin: 20,
                monthColor: Colors.white,
                dayColor: Colors.white70,
                activeDayColor: Colors.white, // White text color for active day
                activeBackgroundDayColor: Colors.teal,
                dotColor: Color(0xFF333A47), // Highlight selected day with teal
                selectableDayPredicate: (date) => date.day != 0,
                locale: 'en_ISO',
              ),
            ),
            isLoading
                ? Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
                : billFiles.isEmpty
                ? Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_off,
                      size: 80,
                      color: Colors.white70,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No bills found!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: billFiles.length,
                itemBuilder: (context, index) {
                  final file = billFiles[index];
                  final fileName = file.path.split('/').last;
                  final fileStat = file.statSync();
                  final fileSize = formatFileSize(fileStat.size);
                  final modifiedDate =
                  DateFormat('dd MMM yyyy, hh:mm a')
                      .format(fileStat.modified);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        leading: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 40,
                        ),
                        title: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Size: $fileSize',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700]),
                            ),
                            Text(
                              'Modified: $modifiedDate',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.open_in_new,
                                  color: Colors.teal),
                              onPressed: () =>
                                  openFile(file.path),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () => showDeleteConfirmation(
                                  fileName, file.path),
                            ),
                          ],
                        ),
                      ),
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
