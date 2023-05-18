// import necessary dependencies
import 'package:flutter/material.dart';
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
    _data = DatabaseHelper.instance.queryAllRows();
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
            onPressed:
                _copySelectedItems, // set the on pressed to the copy function
            icon: const Icon(Icons.copy), // icon for the button
          ),
          IconButton(
            onPressed:
                _shareSelectedItems, // set the on pressed to the share function
            icon: const Icon(Icons.share), // icon for the button
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _data, // the future object for the FutureBuilder
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a circular progress indicator while waiting for the future to complete
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.hasError) {
              // Show an error if the future completed with an error
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              // If the future completed with a result
              List<Map<String, dynamic>> sortedData = List.from(snapshot.data!);
              // Sort the data based on id
              sortedData.sort((a, b) => b[DatabaseHelper.columnId]
                  .compareTo(a[DatabaseHelper.columnId]));

              // Create data rows from the sorted data
              List<DataRow> dataRows = sortedData.map((row) {
                final itemId = row[
                    DatabaseHelper.columnId]; // get the id of the current row
                final itemText = row[DatabaseHelper
                    .columnText]; // get the text of the current row

                // Return a DataRow for the current row
                return DataRow(
                  cells: [
                    // CheckBox cell to select the item
                    DataCell(Checkbox(
                      value: _selectedItems.containsKey(
                          itemId), // check if this item is selected
                      onChanged: (value) {
                        setState(() {
                          // call setState to update the UI
                          if (value!) {
                            _selectedItems[itemId] =
                                itemText; // add the item to the selected items
                          } else {
                            _selectedItems.remove(
                                itemId); // remove the item from the selected items
                          }
                        });
                      },
                    )),
                    // Display the timestamp of the item in a cell
                    DataCell(Text(formattedTimestamp(
                        row[DatabaseHelper.columnTimestamp]))),
                    // Display the item text in a cell
                    DataCell(
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 100),
                        child: InkWell(
                          onTap: () {
                            // Copy the text to the clipboard when tapped
                            Clipboard.setData(
                              ClipboardData(text: itemText),
                            );
                            // Show a snack bar indicating the text has been copied
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Text copied to clipboard")),
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
              // Return a DataTable with the data rows
              return DataTable(
                columnSpacing: 15, // space between columns
                columns: [
                  DataColumn(
                      label: Text('Select')), // column for selecting items
                  DataColumn(label: Text('Timestamp')), // column for timestamps
                  DataColumn(
                      label: Text('Text')), // column for the text of items
                ],
                rows: dataRows, // the rows of the table
              );
            }
          }
        },
      ),
    );
  }
}
