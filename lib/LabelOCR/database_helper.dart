import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = 'ocrText.db';
  static const _dbVersion = 1;
  static const _tableName = 'ocrTextTable';

  static const columnId = '_id';
  static const columnTimestamp = 'timestamp';
  static const columnText = 'text';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $_tableName (
            $columnId INTEGER PRIMARY KEY,
            $columnTimestamp TEXT NOT NULL,
            $columnText TEXT NOT NULL
          )
          ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(_tableName, row);
  }

  // Delete multiple rows from the database based on column IDs
  Future<void> deleteMultiple(List<int> columnIds) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: '$columnId IN (${columnIds.map((id) => '?').join(', ')})',
      whereArgs: columnIds,
    );
  }

  // Get rows for a single page
  Future<List<Map<String, dynamic>>> queryAllRows(
      {int page = 0, int rowsPerPage = 9, String searchQuery = ''}) async {
    Database db = await instance.database;
    int offset = page * rowsPerPage;
    List<Map<String, dynamic>> rows = await db.query(_tableName,
        limit: rowsPerPage,
        offset: offset,
        orderBy: '$columnTimestamp DESC',
        where: '$columnText LIKE ?',
        whereArgs: ['%$searchQuery%']);

    //To be removed (for testing purposes only)
    print('Fetched rows: $rows');

    return rows;
  }

  Future<List<Map<String, dynamic>>> queryAllData(
      {String searchQuery = ''}) async {
    Database db = await instance.database;

    List<Map<String, dynamic>> rows = await db.query(_tableName,
        orderBy: '$columnTimestamp DESC',
        where: '$columnText LIKE ?',
        whereArgs: ['%$searchQuery%']);

    return rows;
  }
}
