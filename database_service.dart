import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sensor_reading.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gasox_readings.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE ${SensorReadingFields.tableName} (
        ${SensorReadingFields.id} $idType,
        ${SensorReadingFields.timestamp} $textType,
        ${SensorReadingFields.mq4Value} $integerType,
        ${SensorReadingFields.mq7Value} $integerType,
        ${SensorReadingFields.isHighReading} $boolType
      )
    ''');
  }

  Future<int> insertReading(SensorReading reading) async {
    final db = await instance.database;
    return await db.insert(SensorReadingFields.tableName, reading.toJson());
  }

  Future<List<SensorReading>> getAllReadings() async {
    final db = await instance.database;
    const orderBy = '${SensorReadingFields.timestamp} DESC';
    
    final result = await db.query(
      SensorReadingFields.tableName,
      orderBy: orderBy,
    );

    return result.map((json) => SensorReading.fromJson(json)).toList();
  }

  Future<List<SensorReading>> getHighReadings() async {
    final db = await instance.database;
    const orderBy = '${SensorReadingFields.timestamp} DESC';
    
    final result = await db.query(
      SensorReadingFields.tableName,
      where: '${SensorReadingFields.isHighReading} = ?',
      whereArgs
