// import necessary dependencies
import 'package:flutter/material.dart';
import '../LabelOCR/database_helper.dart'; // our local database helper class
import 'package:intl/intl.dart'; // for date and time formatting
import 'package:flutter/services.dart'; // for clipboard service
import 'package:http/http.dart' as http; // for making http requests
import 'dart:convert'; // for converting http response
import 'package:url_launcher/url_launcher.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

// StatefulWidget as it maintains mutable state
class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

// State of StatefulWidget
class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Map<String, dynamic>>>
      _data; // Future list that will store the data
  Map<int, Map<String, dynamic>> _selectedItems = {};

  // Variables for pagination
  int page = 0;
  int rowsPerPage = 9;

  // Variables for search function
  final FocusNode _focusNode = FocusNode();
  bool _showSearchBar = false;
  TextEditingController _searchController = TextEditingController();

  // Function to format timestamp
  String formattedTimestamp(String timestamp) {
    DateTime parsedTimestamp = DateTime.parse(timestamp);
    return DateFormat('dd/MM/yy HH:mm').format(parsedTimestamp);
  }

  // Initialize the state
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Function to fetch data from the database
  void _fetchData() {
    String searchQuery = _searchController.text;

    _data = DatabaseHelper.instance.queryAllRows(
      page: page,
      rowsPerPage: rowsPerPage,
      searchQuery: searchQuery,
    );
  }

  void _fetchNextPage() async {
    List<Map<String, dynamic>> nextPageData = await DatabaseHelper.instance
        .queryAllRows(page: page + 1, rowsPerPage: rowsPerPage);

    if (nextPageData.isNotEmpty) {
      setState(() {
        page++;
        _fetchData();
      });
    }
  }

  void _fetchPreviousPage() {
    if (page > 0) {
      setState(() {
        page--;
        _fetchData();
      });
    }
  }

  // Function to copy selected items to the clipboard
  void _copySelectedItems() {
    String copiedData = _selectedItems.entries
        .map((item) => item.value['text'])
        .join("\n === Next Item === \n");

    Clipboard.setData(ClipboardData(
        text: copiedData)); // setting the copied data to clipboard
    // Show a snack bar indicating that the items have been copied
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Selected items copied to clipboard")),
    );
  }

  // Function to delete selected items from the database
  void _deleteSelectedItems() async {
    List<int> selectedIds = _selectedItems.keys.toList();
    await DatabaseHelper.instance.deleteMultiple(selectedIds);

    setState(() {
      _fetchData();
      _selectedItems.clear();
    });
  }

  void _joinTelegram() async {
    String telegramLink = "https://t.me/testingdbnotif";
    Uri url = Uri.parse(telegramLink);
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _searchProductOnWeb(BuildContext context) async {
    if (_selectedItems.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select exactly one item to search"),
        ),
      );
      return;
    }

    String vendorProductNumber = '';
    String customerProductNumber = '';

    // Extract the vendor and customer product numbers from the selected item
    String selectedItemText = _selectedItems.values.first['text'];
    RegExp vendorProductNumberRegex = RegExp(r"Vendor Product Number: (.+)");
    RegExp customerProductNumberRegex =
        RegExp(r"Customer Product Number: (.+)");

    // Find the vendor product number using regex
    Match? vendorMatch = vendorProductNumberRegex.firstMatch(selectedItemText);
    if (vendorMatch != null) {
      vendorProductNumber = vendorMatch.group(1)!;
    }

    // Find the customer product number using regex
    Match? customerMatch =
        customerProductNumberRegex.firstMatch(selectedItemText);
    if (customerMatch != null) {
      customerProductNumber = customerMatch.group(1)!;
    }

    // Tiebreak by length, sometimes customer product number is the one we want which can be differentiated by length
    if (vendorProductNumber.isNotEmpty && customerProductNumber.isNotEmpty) {
      if (customerProductNumber.length > 1.5 * vendorProductNumber.length) {
        Uri url =
            Uri.parse('https://www.google.com/search?q=$customerProductNumber');
        launchUrl(url);
        return;
      }
    }

    if (vendorProductNumber.isNotEmpty) {
      Uri url =
          Uri.parse('https://www.google.com/search?q=$vendorProductNumber');
      launchUrl(url);
    } else if (customerProductNumber.isNotEmpty) {
      Uri url =
          Uri.parse('https://www.google.com/search?q=$customerProductNumber');
      launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product numbers not found"),
        ),
      );
    }
  }

  void _exportToExcel({bool exportSelected = false}) async {
    // Fetch all data from the database
    var allData = exportSelected
        ? _selectedItems.values.toList()
        : await DatabaseHelper.instance.queryAllData();

    var excel = Excel.createExcel();
    var sheet = excel.sheets.values.first;
    var headers = [
      "Id",
      "Timestamp",
      "Vendor Product Number",
      "Customer Product Number",
      "Quantity",
      "Description",
      "Uncategorized"
    ];
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = headers[i];
    }

    for (var i = 0; i < allData.length; i++) {
      var itemId = i + 1;
      var timestamp = allData[i]['timestamp'];
      var text = allData[i]['text'];

      // Split the text field into its individual parts
      var vendorProductNumber = text
          .split("Vendor Product Number:")
          .last
          .split("Customer Product Number:")
          .first
          .trim();
      var customerProductNumber = text
          .split("Customer Product Number:")
          .last
          .split("Quantity:")
          .first
          .trim();
      var quantity =
          text.split("Quantity:").last.split("Description:").first.trim();
      var description =
          text.split("Description:").last.split("Uncategorized:").first.trim();
      var uncategorized = text.split("Uncategorized:").last.trim();

      // Write the item id, timestamp, and text parts to the sheet
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          .value = itemId;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
          .value = timestamp;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
          .value = vendorProductNumber;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1))
          .value = customerProductNumber;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1))
          .value = quantity;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1))
          .value = description;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 1))
          .value = uncategorized;
    }

    // Save the Excel file
    var data = excel.encode();

    // Get the temporary directory
    final directory = (await getTemporaryDirectory()).path;

    // Create a file in the obtained directory
    final file = File('$directory/label_data.xlsx');
    await file.writeAsBytes(data!);

    // Share the file
    Share.shareFiles([
      file.path
    ], mimeTypes: [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ]);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Items exported to Excel successfully")),
    );
  }

  // Function to share selected items via http request
  void _shareSelectedItems() async {
    // Join the selected items into a single string
    String copiedData = _selectedItems.entries
        .map((item) => "\n \n=== Next Item === \n${item.value['text']}")
        .join('');

    // Create a single key-value pair for the JSON
    Map<String, String> payload = {'data': copiedData.replaceAll("\n", "<br>")};

    // Specify the request URL
    var url = Uri.parse(
        'https://maker.ifttt.com/trigger/receive_payload_data/json/with/key/bUIui2gUvqcZapi3Ve6gDG');
    // Make the POST request
    var response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload));

    // Check the response status code
    if (response.statusCode == 200) {
      // Show a snack bar indicating that the items have been shared successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Items shared successfully")),
      );
    } else {
      // Show a snack bar indicating the failure of the share operation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to share items: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus(); // dismiss keyboard
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Database'),
            actions: <Widget>[
              IconButton(
                onPressed: () {
                  // Toggle the search bar visibility
                  setState(() {
                    _showSearchBar = !_showSearchBar;
                  });
                },
                icon: const Icon(Icons.search),
              ),
              IconButton(
                onPressed: _deleteSelectedItems,
                icon: const Icon(Icons.delete),
              ),
              IconButton(
                onPressed: _copySelectedItems,
                icon: const Icon(Icons.copy),
              ),
              IconButton(
                onPressed: () {
                  _searchProductOnWeb(context);
                },
                icon: const Icon(Icons.public),
              ),
              PopupMenuButton<int>(
                icon: const Icon(Icons.share),
                onSelected: (value) {
                  switch (value) {
                    case 0:
                      _shareSelectedItems();
                      break;
                    case 2:
                      _joinTelegram();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 0,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.send,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 8.0),
                        Text('Export Telegram')
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: PopupMenuButton<int>(
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.file_download,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8.0),
                          Text('Export Excel')
                        ],
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 0:
                            _exportToExcel(exportSelected: false);
                            break;
                          case 1:
                            _exportToExcel(exportSelected: true);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 0,
                          child: Text('Export All Rows'),
                        ),
                        const PopupMenuItem(
                          value: 1,
                          child: Text('Export Selected Rows'),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 2,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.send,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 8.0),
                        Text('Join Telegram')
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (_showSearchBar)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    focusNode: _focusNode,
                    onChanged: (value) {
                      _searchController.text = value;
                      // Perform search based on the entered value
                      setState(() {
                        _fetchData();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _data,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        List<Map<String, dynamic>> sortedData =
                            List.from(snapshot.data!);

                        List<DataRow> dataRows = sortedData.map((row) {
                          final itemId = row[DatabaseHelper.columnId];
                          final itemText = row[DatabaseHelper.columnText];

                          return DataRow(
                            cells: [
                              DataCell(Checkbox(
                                value: _selectedItems.containsKey(itemId),
                                onChanged: (value) {
                                  setState(() {
                                    if (value!) {
                                      _selectedItems[itemId] = row;
                                    } else {
                                      _selectedItems.remove(itemId);
                                    }
                                  });
                                },
                              )),
                              DataCell(Text(formattedTimestamp(
                                  row[DatabaseHelper.columnTimestamp]))),
                              DataCell(
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 100),
                                  child: InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: itemText),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Text copied to clipboard")),
                                      );
                                    },
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Text(
                                        itemText,
                                        softWrap: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList();

                        return DataTable(
                          columnSpacing: 15,
                          columns: const [
                            DataColumn(label: Text('Select')),
                            DataColumn(label: Text('Timestamp')),
                            DataColumn(label: Text('Text')),
                          ],
                          rows: dataRows,
                        );
                      }
                    }
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: _fetchPreviousPage,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text('Page ${page + 1}'),
                  IconButton(
                    onPressed: _fetchNextPage,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
