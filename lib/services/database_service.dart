import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Singleton pattern
  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Access to database reference
  DatabaseReference ref(String path) {
    return _database.ref(path);
  }
}