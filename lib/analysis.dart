import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:d_chart/d_chart.dart';
import 'package:intl/intl.dart';
class ChartData {
  final String itemName;
  final double itemTotal;

  // Constructor should be named parameters
  ChartData({required this.itemName, required this.itemTotal});
}
// Function to get the permanent storage path (app's private directory)
Future<String> getBeplusStoragePath(String fileName) async {
  final appDocDir = await getApplicationDocumentsDirectory(); // App's private documents directory
  final beplusDir = Directory('${appDocDir.path}/BEplus'); // Create a dedicated folder for BEplus

  if (!await beplusDir.exists()) {
    await beplusDir.create(recursive: true); // Ensure the folder exists
  }

  return "${beplusDir.path}/$fileName"; // Return the full file path
}
Future<List<Map<String, dynamic>>> loadDataFromExcel(String fileName) async {
  final filePath = await getBeplusStoragePath(fileName); // Use private storage path
  final file = File(filePath);

  if (await file.exists()) {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Sheet1']; // Ensure correct sheet is loaded.

    final data = <Map<String, dynamic>>[];
    for (var row in sheet.rows.skip(1)) { // Skipping header row
      if (row.isNotEmpty) {
        String itemName = (row[0]?.value ?? '').toString();
        int size = int.tryParse(row[1]?.value.toString() ?? '0') ?? 0;
        int quantity = int.tryParse(row[2]?.value.toString() ?? '0') ?? 0;
        double itemTotal = double.tryParse(row[3]?.value.toString() ?? '0.0') ?? 0.0;
        String custName = (row[4]?.value ?? '').toString();
        String custMobile = (row[5]?.value ?? '').toString();
        String custAddr = (row[6]?.value ?? '').toString();
        String custShop = (row[7]?.value ?? '').toString();
        String timestamp = (row[8]?.value ?? DateTime.now().toString()).toString();

        data.add({
          'itemName': itemName,
          'size': size,
          'quantity': quantity,
          'itemTotal': itemTotal,
          'custName': custName,
          'custMobile': custMobile,
          'custAddr': custAddr,
          'custShop': custShop,
          'timestamp': timestamp,
        });
      }
    }
    return data;
  } else {
    throw Exception('Excel file not found in app storage');
  }
}
List<ChartData> prepareDataForChart(List<Map<String, dynamic>> data) {
  Map<String, double> productSales = {};
  // Aggregate sales data by product
  for (var row in data) {
    String itemName = row['itemName'];
    double itemTotal = row['itemTotal'];
    // Aggregate sales totals by item
    if (productSales.containsKey(itemName)) {
      productSales[itemName] = productSales[itemName]! + itemTotal;
    } else {
      productSales[itemName] = itemTotal;
    }
  }
  // Convert the aggregated sales data into chart-friendly format
  return productSales.entries.map((entry) {
    // Ensure that itemName and itemTotal are passed correctly to ChartData
    return ChartData(itemName: entry.key, itemTotal: entry.value);
  }).toList();
}
class AnalysisScreen extends StatefulWidget {
  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}
class _AnalysisScreenState extends State<AnalysisScreen> {
  late Future<List<Map<String, dynamic>>> _data;
  List<Map<String, dynamic>> _filteredData = [];
  late List<ChartData> _chartData;
  List<Map<String, dynamic>> _bestSellingProducts = [];
  String _selectedFilter = 'All Time';

  DateTime _currentStartDate = DateTime.now().subtract(Duration(days: 6));
  List<Map<String, dynamic>> _salesByDate = [];

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
    _data = loadDataFromExcel('analysis.xlsx');
  }

  Future<void> _requestStoragePermission() async {
    var status = await Permission.storage.request();
    if (status.isDenied) {
      throw Exception("Storage permission is required to access Excel files.");
    }
  }
  String _currentFilter = 'By Date';  // Default filter option

// Method to apply selected filter
  void _applyFilterOption(String filterOption) {
    setState(() {
      // Ensure the filterOption is non-null before setting
      if (filterOption != null) {
        _currentFilter = filterOption;
      }
    });
  }

// Method to format the date range for the selected filter
  String _getFormattedDateRange() {
    if (_currentFilter == 'By Date') {
      return "${DateFormat('dd/MM').format(_currentStartDate)} - ${DateFormat('dd/MM').format(_currentStartDate.add(Duration(days: 6)))}";
    } else if (_currentFilter == 'By Month') {
      return "${DateFormat('MM/yyyy').format(_currentStartDate)}";
    } else if (_currentFilter == 'By Year') {
      return "${DateFormat('yyyy').format(_currentStartDate)}";
    }
    return '';
  }

// Method to get filtered sales data based on the selected filter
  List<OrdinalData> _getFilteredSalesData() {
    // Ensure _salesByDate is not null
    if (_salesByDate == null) return [];

    if (_currentFilter == 'By Date') {
      return _salesByDate
          .where((data) {
        DateTime timestamp;
        try {
          timestamp = DateTime.parse(data['timestamp']);
        } catch (e) {
          // Handle invalid timestamp or missing data
          return false;
        }
        return timestamp.isAfter(_currentStartDate) && timestamp.isBefore(_currentStartDate.add(Duration(days: 7)));
      })
          .map((data) => OrdinalData(
        domain: DateFormat('dd/MM').format(DateTime.parse(data['timestamp'])),
        measure: data['revenue'],
      ))
          .toList();
    } else if (_currentFilter == 'By Month') {
      var monthlyData = _consolidateByMonth();
      return monthlyData
          .map((data) => OrdinalData(domain: data['month'], measure: data['revenue']))
          .toList();
    } else if (_currentFilter == 'By Year') {
      var yearlyData = _consolidateByYear();
      return yearlyData
          .map((data) => OrdinalData(domain: data['year'], measure: data['revenue']))
          .toList();
    }
    return [];
  }

// Method to consolidate sales by month using timestamp
  List<Map<String, dynamic>> _consolidateByMonth() {
    Map<String, double> monthRevenueMap = {};

    // Ensure _salesByDate is not null
    if (_salesByDate == null) return [];

    _salesByDate.forEach((data) {
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(data['timestamp']);
      } catch (e) {
        // Handle invalid timestamp or missing data
        return;
      }

      String monthKey = DateFormat('MM/yyyy').format(timestamp);
      monthRevenueMap[monthKey] = (monthRevenueMap[monthKey] ?? 0) + data['revenue'];
    });

    return monthRevenueMap.entries
        .map((entry) => {'month': entry.key, 'revenue': entry.value})
        .toList();
  }

// Method to consolidate sales by year using timestamp
  List<Map<String, dynamic>> _consolidateByYear() {
    Map<String, double> yearRevenueMap = {};

    // Ensure _salesByDate is not null
    if (_salesByDate == null) return [];

    _salesByDate.forEach((data) {
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(data['timestamp']);
      } catch (e) {
        // Handle invalid timestamp or missing data
        return;
      }

      String yearKey = DateFormat('yyyy').format(timestamp);
      yearRevenueMap[yearKey] = (yearRevenueMap[yearKey] ?? 0) + data['revenue'];
    });

    return yearRevenueMap.entries
        .map((entry) => {'year': entry.key, 'revenue': entry.value})
        .toList();
  }

  void _applyFilter(List<Map<String, dynamic>> data, String filter) {
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (filter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(Duration(days: 1)).subtract(Duration(seconds: 1));
        break;
      case 'Yesterday':
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 1));
        endDate = startDate.add(Duration(days: 1)).subtract(Duration(seconds: 1));
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: 7));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      default:
        startDate = DateTime(2000);
        break;
    }

    setState(() {
      _filteredData = data.where((row) {
        DateTime rowDate = DateFormat('yyyy-MM-dd').parse(row['timestamp']);
        return rowDate.isAfter(startDate.subtract(Duration(seconds: 1))) &&
            rowDate.isBefore(endDate.add(Duration(seconds: 1)));
      }).toList();

      _chartData = prepareDataForChart(_filteredData);
      _bestSellingProducts = _calculateBestSellingProducts(_filteredData);
      _updateChartDataForDateRange();
    });
  }

  List<Map<String, dynamic>> _calculateBestSellingProducts(List<Map<String, dynamic>> data) {
    Map<String, Map<String, dynamic>> productMap = {};

    for (var row in data) {
      String itemName = row['itemName'];
      double totalRevenue = double.parse(row['itemTotal'].toString());
      int quantitySold = int.parse(row['quantity'].toString());

      if (productMap.containsKey(itemName)) {
        productMap[itemName]!['totalRevenue'] += totalRevenue;
        productMap[itemName]!['totalQuantity'] += quantitySold;
      } else {
        productMap[itemName] = {
          'itemName': itemName,
          'totalRevenue': totalRevenue,
          'totalQuantity': quantitySold,
        };
      }
    }

    List<Map<String, dynamic>> sortedProducts = productMap.values.toList();
    sortedProducts.sort((a, b) => b['totalRevenue'].compareTo(a['totalRevenue']));

    return sortedProducts;
  }

  void _updateChartDataForDateRange() {
    DateTime start = _currentStartDate;
    DateTime end = _currentStartDate.add(Duration(days: 6));

    Map<String, double> revenueByDate = {};

    for (var row in _filteredData) {
      DateTime rowDate = DateFormat('yyyy-MM-dd').parse(row['timestamp']);
      String formattedDate = DateFormat('dd/MM').format(rowDate);

      if (rowDate.isAfter(start.subtract(Duration(days: 1))) && rowDate.isBefore(end.add(Duration(days: 1)))) {
        revenueByDate.update(formattedDate, (value) => value + double.parse(row['itemTotal'].toString()),
            ifAbsent: () => double.parse(row['itemTotal'].toString()));
      }
    }

    setState(() {
      _salesByDate = List.generate(7, (index) {
        String dateLabel = DateFormat('dd/MM').format(start.add(Duration(days: index)));
        return {'date': dateLabel, 'revenue': revenueByDate[dateLabel] ?? 0};
      });
    });
  }

  void _changeDateRange(bool forward) {
    setState(() {
      _currentStartDate = _currentStartDate.add(Duration(days: forward ? 7 : -7));
      _updateChartDataForDateRange();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            if (_filteredData.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _applyFilter(snapshot.data!, _selectedFilter);
              });
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Dropdown
                  DropdownButton<String>(
                  value: _selectedFilter,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedFilter = newValue!;
                      _applyFilter(snapshot.data!, _selectedFilter);  // Reapply the filter when selection changes
                    });
                  },
                  isExpanded: true,
                  style: TextStyle(fontSize: 16, color: Colors.teal),  // Text style for dropdown items
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.teal,  // Custom arrow icon
                    size: 28,
                  ),
                  underline: Container(),  // Remove the default underline
                  dropdownColor: Colors.white,  // Background color for the dropdown when opened
                  selectedItemBuilder: (BuildContext context) {
                    return ['All Time', 'Today', 'Yesterday', 'Last Week', 'Last Month']
                        .map<Widget>((filter) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          child: Row(
                            children: [
                              Icon(Icons.date_range, color: Colors.teal, size: 20),  // Icon for each filter
                              SizedBox(width: 12),
                              Text(
                                filter,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),  // Enhanced font styling
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList();
                  },
                  items: ['All Time', 'Today', 'Yesterday', 'Last Week', 'Last Month']
                      .map((filter) {
                    return DropdownMenuItem<String>(
                      value: filter,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),  // Padding for the items
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),  // Rounded corners for each item
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.date_range, color: Colors.teal, size: 20),  // Icon for each filter
                            SizedBox(width: 12),
                            Text(
                              filter,
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.teal),  // Enhanced font styling
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                  SizedBox(height: 20),

                    // Sales Performance
                    Text("Sales Analysis", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),

                    SizedBox(height: 20),

                    // Sales Analysis with Date Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: Colors.teal),
                          onPressed: () => _changeDateRange(false),
                        ),
                        Text(
                          "${DateFormat('dd/MM').format(_currentStartDate)} - ${DateFormat('dd/MM').format(_currentStartDate.add(Duration(days: 6)))}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                          onPressed: () => _changeDateRange(true),
                        ),
                      ],
                    ),

                    SizedBox(height: 10),

                    // Sales Revenue Chart
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: DChartBarO(
                        groupList: [
                          OrdinalGroup(
                            id: 'sales',
                            // Display all data in _salesByDate without any filter applied
                            data: _salesByDate
                                .map((data) => OrdinalData(domain: data['date'], measure: data['revenue']))
                                .toList(),
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),

                    Text("Sales Performance", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),

                    SizedBox(height: 20),

                    // Chart Widget
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: DChartBarO(
                          groupList: [
                            OrdinalGroup(
                              id: 'sales',
                              data: _chartData
                                  .map((data) => OrdinalData(domain: data.itemName, measure: data.itemTotal))
                                  .toList(),
                              color: Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 30),
                    Text("Best Selling Products", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _bestSellingProducts.length,
                      itemBuilder: (context, index) {
                        var product = _bestSellingProducts[index];
                        return ListTile(
                          title: Text(product['itemName'], style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Quantity: ${product['totalQuantity']} | Revenue: \₹${product['totalRevenue']}"),
                          leading: Icon(Icons.shopping_bag, color: Colors.teal),
                        );
                      },
                    ),

                    SizedBox(height: 30),

                    // Sales Data Table or No Purchase message
                    Text("Sales Data", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    _filteredData.isEmpty
                        ? Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                        decoration: BoxDecoration(
                          color: Colors.teal[50], // Light background color
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12, spreadRadius: 2)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // To ensure the content takes minimal space
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.remove_shopping_cart, color: Colors.teal, size: 30),
                            SizedBox(width: 10),
                            Text(
                              'No Purchase on that day',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                                letterSpacing: 1.2, // Add slight spacing between letters for a cleaner look
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        :
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowHeight: 56,
                          columns: [
                            DataColumn(
                              label: Row(
                                children: [
                                  Icon(Icons.shopping_cart, color: Colors.teal, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Item',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal),
                                  ),
                                ],
                              ),
                            ),
                            DataColumn(
                              label: Row(
                                children: [
                                  Text(
                                    'Qty',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal),
                                  ),
                                ],
                              ),
                            ),
                            DataColumn(
                              label: Row(
                                children: [
                                  Icon(Icons.currency_rupee, color: Colors.teal, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Total',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal),
                                  ),
                                ],
                              ),
                            ),
                            DataColumn(
                              label: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.teal, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Date',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          rows: _filteredData.map((row) {
                            bool isEvenRow = _filteredData.indexOf(row) % 2 == 0;
                            String formattedDate = '';
                            if (row['timestamp'] != null) {
                              DateTime timestamp = DateTime.parse(row['timestamp']); // Assuming it's a valid ISO date string
                              formattedDate = DateFormat('dd/MM/yyyy').format(timestamp); // Adjust to your desired format
                            }

                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color>(
                                    (states) => isEvenRow ? Colors.teal[50]! : Colors.white,
                              ),
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      Icon(Icons.shopping_bag, color: Colors.teal, size: 20),
                                      SizedBox(width: 10),
                                      Text(row['itemName'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(row['quantity'].toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ),
                                DataCell(
                                  Text('\₹${row['itemTotal'].toString()}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ),
                                DataCell(
                                  Text(formattedDate, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}




