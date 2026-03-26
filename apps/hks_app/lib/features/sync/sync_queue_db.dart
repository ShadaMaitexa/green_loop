import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class SyncQueueItem {
  final String id;
  final String pickupId;
  final String qrToken;
  final String photoPath;
  final String classification;
  final double confidence;
  final double? weight;
  final double latitude;
  final double longitude;
  final String? overrideNote;
  final int timestamp;

  SyncQueueItem({
    required this.id,
    required this.pickupId,
    required this.qrToken,
    required this.photoPath,
    required this.classification,
    required this.confidence,
    this.weight,
    required this.latitude,
    required this.longitude,
    this.overrideNote,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pickup_id': pickupId,
      'qr_token': qrToken,
      'photo_path': photoPath,
      'classification': classification,
      'confidence': confidence,
      'weight': weight,
      'latitude': latitude,
      'longitude': longitude,
      'override_note': overrideNote,
      'timestamp': timestamp,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'],
      pickupId: map['pickup_id'],
      qrToken: map['qr_token'],
      photoPath: map['photo_path'],
      classification: map['classification'],
      confidence: map['confidence'],
      weight: map['weight'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      overrideNote: map['override_note'],
      timestamp: map['timestamp'],
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'client_id': id,
      'pickup_id': pickupId,
      'qr_token': qrToken,
      // photo_url will be injected after upload
      'classification': classification,
      'confidence_score': confidence,
      'weight': weight,
      'latitude': latitude,
      'longitude': longitude,
      'override_note': overrideNote,
      'timestamp': timestamp,
    };
  }
}

class SyncQueueDb {
  static final SyncQueueDb _instance = SyncQueueDb._internal();
  factory SyncQueueDb() => _instance;
  SyncQueueDb._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sync_queue.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sync_queue(
            id TEXT PRIMARY KEY,
            pickup_id TEXT,
            qr_token TEXT,
            photo_path TEXT,
            classification TEXT,
            confidence REAL,
            weight REAL,
            latitude REAL,
            longitude REAL,
            override_note TEXT,
            timestamp INTEGER
          )
        ''');
      },
    );
  }

  Future<void> insertItem(SyncQueueItem item) async {
    final db = await database;
    await db.insert('sync_queue', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SyncQueueItem>> getPendingItems() async {
    final db = await database;
    final maps = await db.query('sync_queue', orderBy: 'timestamp ASC');
    return maps.map((e) => SyncQueueItem.fromMap(e)).toList();
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM sync_queue'));
    return count ?? 0;
  }
}
