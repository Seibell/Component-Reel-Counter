import 'package:flutter/material.dart';
import '../LabelOCR/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Map<String, dynamic>>> _data;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search OCR Text'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.queryAllRows(),
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

              List<DataRow> dataRows = sortedData
                  .map((row) => DataRow(cells: [
                        DataCell(Text(row[DatabaseHelper.columnId].toString())),
                        DataCell(Text(formattedTimestamp(
                            row[DatabaseHelper.columnTimestamp]))),
                        DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 100),
                            child: InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(
                                      text: row[DatabaseHelper.columnText]),
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
                                  row[DatabaseHelper.columnText],
                                  softWrap: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]))
                  .toList();

              return DataTable(
                columns: [
                  DataColumn(label: Text('ID')),
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
