import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mydiplom/login/user.dart';

class DBHelper {
  static Database? _db;
  static const String DB_NAME = 'db.db';
  static const String USER_TABLE = 'users';

  DBHelper._internal();

  static final DBHelper instance = DBHelper._internal();

  factory DBHelper() => instance;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await _initDb();
    return _db!;
  }

  _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, DB_NAME);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $USER_TABLE (
            id INTEGER PRIMARY KEY,
            email TEXT,
            password TEXT
          )
          ''');
  }

  Future<int> saveUser(User user) async {
    var dbClient = await db;
    return await dbClient.insert(USER_TABLE, user.toMap());
  }

  Future<User?> getUser(String email, String password) async {
    var dbClient = await db;
    var result = await dbClient.rawQuery('SELECT * FROM $USER_TABLE WHERE email = ? AND password = ?', [email, password]);
    if (result.length > 0) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<void> close() async {
    var dbClient = await db;
    dbClient.close();
    _db = null;
  }
}
