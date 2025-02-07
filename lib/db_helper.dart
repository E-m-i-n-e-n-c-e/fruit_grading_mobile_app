import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

extension StringExtension on String {
  String get capitalizeFirst {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mydatabase.db');
    return _database!;
  }

  Future<Database> _initDB(String dbName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    return await openDatabase(
      path,
      version: 1, // Updated version
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {

    await db.execute('''
      CREATE TABLE currentUser (
        id INTEGER PRIMARY KEY,
        authToken TEXT NOT NULL,
        email TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        predictionIds TEXT,
        photoPath TEXT,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE prediction (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fruit TEXT NOT NULL,
        grade TEXT NOT NULL,
        gradeVal FLOAT,
        colorAndShape FLOAT,
        blemish FLOAT,
        coords TEXT
      )
    ''');
  }

  // Insert currentUser
  Future<int> insertCurrentUser(int id, String authToken, String email) async {
    final db = await database;
    return await db.insert('currentUser', {
      'id': id,
      'authToken': authToken,
      'email': email,
    });
  }

  Future<List<Map<String, dynamic>>> getCurrentUser() async {
    final db = await database;
    return await db.query('currentUser', limit: 1);
  }

  Future<void> clearCurrentUser() async {
    final db = await database;
    await db.delete('currentUser');
  }

  // INSERT USER
  Future<int> insertUser(String name, String email, String password) async {
    final db = await database;
    return await db.insert('users', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  // UPDATE DATA
  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update('users', user, where: 'id = ?', whereArgs: [id]);
  }
  
  // DELETE DATA
  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // CHECK LOGIN
  Future<int> checkUserLogin(String email, String password) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if(result.isNotEmpty){
      return result.first['id'];
    }else{
      return 0;
    }
  }

  Future<int> insertPrediction(String fruit, String grade, double gradeVal, double colorandshape, double blemish, List<double> coordsList) async {
    final db = await database;
    String coordsString = coordsList.map((coord) => coord.toString()).join(","); // Convert list to comma-separated string
    
    return await db.insert(
      'prediction',
      {
        'fruit': fruit,
        'grade': grade,
        'gradeVal': gradeVal,
        'colorAndShape': colorandshape,
        'blemish': blemish,
        'coords': coordsString
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> insertPredictions(List<Map<String, dynamic>> predictions) async {
    final db = await database;
    // DatabaseHelper helper = DatabaseHelper.instance;
    List<int> insertedIds = [];
    for (var prediction in predictions) {
      prediction['fruit'] = prediction['fruit'].toString().capitalizeFirst;
      String coordsString = prediction['coordsList'].map((coord) => coord.toString()).join(","); // Convert list to comma-separated string
      Map<String, dynamic> insertData = { 'fruit': prediction['fruit'],'grade': prediction['grade'],'gradeVal': prediction['gradeVal'],'colorAndShape': prediction['colorandshape'],'blemish': prediction['blemish'],'coords': coordsString};
      int id = await db.insert('prediction', insertData);
      
      // int id = await helper.insertPrediction(prediction['fruit'], prediction['grade'], prediction['gradeVal'], prediction['colorandshape'], prediction['blemish'], prediction['coordsList']);
      insertedIds.add(id);
    }
    return insertedIds;
  }

  // INSERT HISTORY RECORD
  Future<int> insertHistory(int userId, List<int> predictionIds, String photoPath) async {
    final db = await database;
    String predictionIdsStr = predictionIds.join(","); // Convert list to comma-separated string

    return await db.insert(
      'history',
      {
        'userId': userId,
        'predictionIds': predictionIdsStr,
        'photoPath': photoPath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> addHistoryWithPredictions(String photoPath, int userId, List<Map<String, dynamic>> predictions) async {
    DatabaseHelper helper = DatabaseHelper.instance;

    // Step 1: Insert predictions and get their IDs
    List<int> insertedIds = await helper.insertPredictions(predictions);

    // Step 2: Insert history with the obtained prediction IDs
    int historyId = await helper.insertHistory(userId, insertedIds, photoPath);

    return historyId; // Ensure the transaction returns a meaningful value
  }

  Future<void> deleteHistoryWithPredictions(int historyId) async {
    final db = await database;

    // Step 1: Get the history record by ID to fetch the prediction IDs
    List<Map<String, dynamic>> historyData = await db.query(
      "history",
      where: "id = ?",
      whereArgs: [historyId],
    );

    if (historyData.isEmpty) {
      print("No history found for this ID.");
      return; // No history entry to delete
    }

    Map<String, dynamic> history = historyData.first;
    String predictionIdsString = history['predictionIds'];
    List<int> predictionIds = predictionIdsString.split(",").map((e) => int.parse(e)).toList();

    // Step 2: Delete predictions associated with this history entry
    await db.delete(
      "prediction",
      where: "id IN (${predictionIds.join(",")})",
    );

    // Step 3: Delete the history entry
    await db.delete(
      "history",
      where: "id = ?",
      whereArgs: [historyId],
    );

    print("History and associated predictions deleted successfully.");
  }

  Future<List<Map<String, dynamic>>> getPredictionsByIds(String predictionIds) async {
    if(predictionIds.isEmpty){
      return [];
    }
    final db = await database;
    return await db.rawQuery("SELECT * FROM prediction WHERE id IN ($predictionIds)");
  }

  Future<Map<String, dynamic>?> getHistoryById(int historyId) async {
    final db = await DatabaseHelper.instance.database; // Get database instance

    List<Map<String, dynamic>> result = await db.query(
      'history',
      where: 'id = ?',
      whereArgs: [historyId],
    );


    if (result.isNotEmpty) {
      Map<String, dynamic> returnData = {'id': result.first['id'],'imagePath': result.first['photoPath'], 'data': []};
      List<Map<String, dynamic>> predictionData = await DatabaseHelper.instance.getPredictionsByIds(result.first['predictionIds']);
      if(predictionData.isEmpty){
        return null;
      }
    //   print(predictionData);
	//   predictionData.map((d) {d['coords'] = d['coords'].split(",").map((e) => double.parse(e)).toList();});
	//   print(predictionData);
      returnData['data'] = predictionData;
      return returnData; // Return first match
    } else {
      return null; // No record found
    }
  }

  Future<List<Map<String, dynamic>>> getAllHistoryByUser(int userId) async {
    final db = await DatabaseHelper.instance.database; // Get database instance

    List<Map<String, dynamic>> result = await db.query(
      'history',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if(result.isEmpty){
      return [];
    }
    List<Map<String, dynamic>> returnData = [];
    for(var singleHistory in result){
      Map<String, dynamic>? historyData = await DatabaseHelper.instance.getHistoryById(singleHistory['id']);
      if(historyData != null){
        returnData.add(historyData);
      }
    }
    return returnData; // Return all matching records as a list
  }
}




  // Future<List<Map<String, dynamic>>> getAllPredictions() async {
  //   final db = await database;
  //   return await db.query('prediction');
  // }


  // Future<Map<String, dynamic>?> getPrediction(int id) async {
  //   final db = await database;
  //   List<Map<String, dynamic>> result = await db.query('prediction', where: 'id = ?', whereArgs: [id]);

  //   return result.isNotEmpty ? result.first : null;
  // }


  // Future<int> updatePrediction(int id, String fruit, String grade, double gradeVal, double colorandshape, double blemish, List<double> coordsList) async {
  //   final db = await database;

  //   String coordsString = coordsList.map((coord) => coord.toString()).join(","); // Convert list to comma-separated string

  //   return await db.update(
  //     'prediction',
  //     {
  //       'fruit': fruit,
  //       'grade': grade,
  //       'grade_val': gradeVal,
  //       'colorandshape': colorandshape,
  //       'blemish': blemish,
  //       'coords': coordsString
  //     },
  //     where: 'id = ?',
  //     whereArgs: [id],
  //   );
  // }


  // Future<int> deletePrediction(int id) async {
  //   final db = await database;
  //   return await db.delete('prediction', where: 'id = ?', whereArgs: [id]);
  // }

  // Future<List<Map<String, dynamic>>> getAllHistory() async {
  //   final db = await database;
  //   return await db.query('history');
  // }

  // Future<List<Map<String, dynamic>>> getPredictionsByIds(List<int> predictionIds) async {
  //   final db = await database;
  //   if (predictionIds.isEmpty) return []; // Return empty list if no IDs provided
  //   String idsString = predictionIds.map((id) => id.toString()).join(","); // Convert list to comma-separated string
  //   return await db.rawQuery("SELECT * FROM prediction WHERE id IN ($idsString)");
  // }

  // Future<int> deletePredictionsByIds(List<int> predictionIds) async {
  //   final db = await database;
  //   if (predictionIds.isEmpty) return 0; // No deletion needed if list is empty
  //   String idsString = predictionIds.map((id) => id.toString()).join(",");
  //   return await db.rawDelete("DELETE FROM prediction WHERE id IN ($idsString)");
  // }
