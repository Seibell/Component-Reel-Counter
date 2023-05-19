// import necessary dependencies
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../LabelOCR/database_helper.dart'; // our local database helper class
import 'package:intl/intl.dart'; // for date and time formatting
import 'package:flutter/services.dart'; // for clipboard service
import 'package:http/http.dart' as http; // for making http requests
import 'dart:convert'; // for converting http response

// StatefulWidget as it maintains mutable state
class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

// State of StatefulWidget
class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Map<String, dynamic>>>
      _data; // Future list that will store the data
  Map<int, String> _selectedItems =
      {}; // Map to store the selected items from the list

  // Variables for pagination
  int page = 0;
  int rowsPerPage = 9;

  // Function to format timestamp
  String formattedTimestamp(String timestamp) {
    DateTime parsedTimestamp = DateTime.parse(timestamp);
    return DateFormat('dd/MM/yy HH:mm').format(parsedTimestamp);
  }

  // Initialize the state
  @override
  void initState() {
    super.initState();
    _fetchData(); // call the function to fetch data
  }

  // Function to fetch data from the database
  void _fetchData() {
    _data = DatabaseHelper.instance
        .queryAllRows(page: page, rowsPerPage: rowsPerPage);
  }

  // Function to fetch the next page of data
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

  // Function to fetch the previous page of data
  void _fetchPreviousPage() {
    if (page > 0) {
      setState(() {
        page--; // decrement the page number
        _fetchData(); // fetch the data for the previous page
      });
    }
  }

  // Function to copy selected items to the clipboard
  void _copySelectedItems() {
    String copiedData = _selectedItems.entries
        .map((item) => item.value)
        .join("\n === Next Item === \n");

    Clipboard.setData(ClipboardData(
        text: copiedData)); // setting the copied data to clipboard
    // Show a snack bar indicating that the items have been copied
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Selected items copied to clipboard")),
    );
  }

  // Function to share selected items via http request
  void _shareSelectedItems() async {
    // Join the selected items into a single string
    String copiedData = _selectedItems.entries
        .map((item) => "\n \n=== Next Item === \n${item.value}")
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

  // Build the widget tree for this screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search OCR Text'),
        actions: <Widget>[
          IconButton(
            onPressed: _copySelectedItems,
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            onPressed: _shareSelectedItems,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Column(
        children: [
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
                    sortedData.sort((a, b) => b[DatabaseHelper.columnId]
                        .compareTo(a[DatabaseHelper.columnId]));

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
                                  _selectedItems[itemId] = itemText;
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
                              constraints: BoxConstraints(maxHeight: 100),
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: itemText),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Text copied to clipboard")),
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
                      columns: [
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
                icon: Icon(Icons.arrow_back),
              ),
              Text('Page ${page + 1}'),
              IconButton(
                onPressed: _fetchNextPage,
                icon: Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
