import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:d_chart/d_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ChartData {
  final String itemName;
  final double itemTotal;

  // Constructor with named parameters
  ChartData({required this.itemName, required this.itemTotal});
}

// Function to get the permanent storage path (app's private directory)
Future<String> getBeplusStoragePath(String fileName) async {
  final appDocDir = await getApplicationDocumentsDirectory(); // App's private documents directory
  final beplusDir = Directory('${appDocDir.path}/BEplus'); // Dedicated folder for BEplus

  if (!await beplusDir.exists()) {
    await beplusDir.create(recursive: true);
  }

  return "${beplusDir.path}/$fileName";
}

Future<List<Map<String, dynamic>>> loadDataFromExcel(String fileName) async {
  final filePath = await getBeplusStoragePath(fileName);
  final file = File(filePath);

  if (await file.exists()) {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Sheet1'];

    final data = <Map<String, dynamic>>[];
    for (var row in sheet.rows.skip(1)) { // Skip header row
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

  for (var row in data) {
    String itemName = row['itemName'];
    double itemTotal = row['itemTotal'];
    productSales.update(itemName, (existing) => existing + itemTotal,
        ifAbsent: () => itemTotal);
  }

  return productSales.entries
      .map((entry) => ChartData(itemName: entry.key, itemTotal: entry.value))
      .toList();
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

  String _currentFilter = 'By Date'; // Default filter option

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

  // Apply selected filter option
  void _applyFilterOption(String filterOption) {
    setState(() {
      _currentFilter = filterOption;
    });
  }

  // Format the date range based on the selected filter
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

  // Get filtered sales data based on the selected filter
  List<OrdinalData> _getFilteredSalesData() {
    if (_salesByDate.isEmpty) return [];

    if (_currentFilter == 'By Date') {
      return _salesByDate
          .where((data) {
        DateTime timestamp;
        try {
          timestamp = DateTime.parse(data['timestamp']);
        } catch (e) {
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

  // Consolidate sales by month using timestamp
  List<Map<String, dynamic>> _consolidateByMonth() {
    Map<String, double> monthRevenueMap = {};
    _salesByDate.forEach((data) {
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(data['timestamp']);
      } catch (e) {
        return;
      }
      String monthKey = DateFormat('MM/yyyy').format(timestamp);
      monthRevenueMap[monthKey] = (monthRevenueMap[monthKey] ?? 0) + data['revenue'];
    });
    return monthRevenueMap.entries
        .map((entry) => {'month': entry.key, 'revenue': entry.value})
        .toList();
  }

  // Consolidate sales by year using timestamp
  List<Map<String, dynamic>> _consolidateByYear() {
    Map<String, double> yearRevenueMap = {};
    _salesByDate.forEach((data) {
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(data['timestamp']);
      } catch (e) {
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
        return {'date': dateLabel, 'revenue': revenueByDate[dateLabel] ?? 0, 'timestamp': start.add(Duration(days: index)).toIso8601String()};
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
      // Updated AppBar with a matching gradient and shader title
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            '📊 Sales Analysis',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [Colors.white, Colors.grey.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
            ),
          ),
        ),
      ),
      // Stack to include background image with a white-fading overlay
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
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          // Main content area with transparent backgrounds
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _data,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.blueGrey,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Oops! Something went wrong.',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${snapshot.error}',
                        style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: Text(
                          'Try Again',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          backgroundColor: Colors.blueGrey.shade800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                );
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
                              _applyFilter(snapshot.data!, _selectedFilter);
                            });
                          },
                          isExpanded: true,
                          style: GoogleFonts.montserrat(fontSize: 16, color: Colors.blueGrey),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.blueGrey,
                            size: 28,
                          ),
                          underline: Container(),
                          dropdownColor: Colors.white,
                          selectedItemBuilder: (BuildContext context) {
                            return ['All Time', 'Today', 'Yesterday', 'Last Week', 'Last Month']
                                .map<Widget>((filter) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.date_range, color: Colors.blueGrey, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        filter,
                                        style: GoogleFonts.montserrat(
                                            fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
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
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueGrey.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.date_range, color: Colors.blueGrey, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      filter,
                                      style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w500, fontSize: 16, color: Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        // Sales Analysis Title
                        Text("Sales Analysis",
                            style: GoogleFonts.montserrat(
                                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        const SizedBox(height: 20),
                        // Date Navigation for Sales Revenue Chart
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios, color: Colors.blueGrey),
                              onPressed: () => _changeDateRange(false),
                            ),
                            Text(
                              "${DateFormat('dd/MM').format(_currentStartDate)} - ${DateFormat('dd/MM').format(_currentStartDate.add(Duration(days: 6)))}",
                              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_forward_ios, color: Colors.blueGrey),
                              onPressed: () => _changeDateRange(true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Sales Revenue Chart
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: DChartBarO(
                            groupList: [
                              OrdinalGroup(
                                id: 'sales',
                                data: _salesByDate
                                    .map((data) => OrdinalData(domain: data['date'], measure: data['revenue']))
                                    .toList(),
                                color: Colors.blueGrey,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text("Sales Performance",
                            style: GoogleFonts.montserrat(
                                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        const SizedBox(height: 20),
                        // Bar Chart for Product Sales
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: DChartBarO(
                              groupList: [
                                OrdinalGroup(
                                  id: 'sales',
                                  data: _chartData
                                      .map((data) =>
                                      OrdinalData(domain: data.itemName, measure: data.itemTotal))
                                      .toList(),
                                  color: Colors.blueGrey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text("Best Selling Products",
                            style: GoogleFonts.montserrat(
                                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _bestSellingProducts.length,
                          itemBuilder: (context, index) {
                            var product = _bestSellingProducts[index];
                            return ListTile(
                              title: Text(product['itemName'],
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                              subtitle: Text("Quantity: ${product['totalQuantity']} | Revenue: \₹${product['totalRevenue']}",
                                  style: GoogleFonts.montserrat()),
                              leading: Icon(Icons.shopping_bag, color: Colors.blueGrey),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        Text("Sales Data",
                            style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _filteredData.isEmpty
                            ? Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[50],
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 8,
                                    color: Colors.black12,
                                    spreadRadius: 2)
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.remove_shopping_cart, color: Colors.blueGrey, size: 30),
                                const SizedBox(width: 10),
                                Text(
                                  'No Purchase on that day',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                      letterSpacing: 1.2),
                                ),
                              ],
                            ),
                          ),
                        )
                            : SingleChildScrollView(
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
                                      Icon(Icons.shopping_cart, color: Colors.blueGrey, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Item',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blueGrey)),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    children: [
                                      Text('Qty',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blueGrey)),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    children: [
                                      Icon(Icons.currency_rupee, color: Colors.blueGrey, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Total',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blueGrey)),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: Colors.blueGrey, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Date',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blueGrey)),
                                    ],
                                  ),
                                ),
                              ],
                              rows: _filteredData.map((row) {
                                bool isEvenRow = _filteredData.indexOf(row) % 2 == 0;
                                String formattedDate = '';
                                if (row['timestamp'] != null) {
                                  DateTime timestamp = DateTime.parse(row['timestamp']);
                                  formattedDate = DateFormat('dd/MM/yyyy').format(timestamp);
                                }
                                return DataRow(
                                  color: MaterialStateProperty.resolveWith<Color>(
                                          (states) => isEvenRow ? Colors.blueGrey[50]! : Colors.white),
                                  cells: [
                                    DataCell(
                                      Row(
                                        children: [
                                          Icon(Icons.shopping_bag, color: Colors.blueGrey, size: 20),
                                          const SizedBox(width: 10),
                                          Text(row['itemName'],
                                              style: GoogleFonts.montserrat(
                                                  fontSize: 14, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(row['quantity'].toString(),
                                          style: GoogleFonts.montserrat(
                                              fontSize: 14, fontWeight: FontWeight.w500)),
                                    ),
                                    DataCell(
                                      Text('\₹${row['itemTotal'].toString()}',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 14, fontWeight: FontWeight.w500)),
                                    ),
                                    DataCell(
                                      Text(formattedDate,
                                          style: GoogleFonts.montserrat(
                                              fontSize: 14, fontWeight: FontWeight.w500)),
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
                return Center(child: Text('No data available', style: GoogleFonts.montserrat()));
              }
            },
          ),
        ],
      ),
    );
  }
}
