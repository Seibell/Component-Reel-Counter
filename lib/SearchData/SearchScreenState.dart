import 'package:flutter/material.dart';
import '../LabelOCR/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Map<String, dynamic>>> _data;
  Map<int, String> _selectedItems = {};

  String formattedTimestamp(String timestamp) {
    DateTime parsedTimestamp = DateTime.parse(timestamp);
    return DateFormat('dd/MM/yy HH:mm').format(parsedTimestamp);
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _data = DatabaseHelper.instance.queryAllRows();
  }

  void _copySelectedItems() {
    String copiedData = _selectedItems.entries
        .map((item) => item.value)
        .join("\n === Next Item === \n");

    Clipboard.setData(ClipboardData(text: copiedData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Selected items copied to clipboard")),
    );
  }

  void _shareSelectedItems() async {
    // Join the selected items into a single string
    String copiedData = _selectedItems.entries
        .map((item) => "\n \n=== Next Item === \n${item.value}")
        .join('');

    // Create a single key-value pair for the JSON
    Map<String, String> payload = {'data': copiedData.replaceAll("\n", "<br>")};

    var url = Uri.parse(
        'https://maker.ifttt.com/trigger/receive_payload_data/json/with/key/bUIui2gUvqcZapi3Ve6gDG');
    var response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload));

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Items shared successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to share items: ${response.body}")),
      );
    }
  }

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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _data,
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              List<Map<String, dynamic>> sortedData = List.from(snapshot.data!);
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
              return DataTable(
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
    );
  }
}
