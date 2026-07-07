import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'pending_occurrence.dart';

/// Persistencia local da fila de sincronizacao offline (Etapa 5). Usa
/// `sqflite` (SQL cru) em vez de Drift de proposito — ver justificativa em
/// mobile/pubspec.yaml (evitar codegen que este sandbox de desenvolvimento
/// nao tem como rodar/validar). E a unica classe que sabe SQL; o resto do
/// app fala com `PendingOccurrence` (modelo de dominio simples).
class OfflineDatabase {
  static const _dbName = 'goodroads_offline.db';
  static const _table = 'pending_occurrences';

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, _dbName),
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE $_table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          address TEXT,
          categoryId TEXT,
          photoPaths TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          retryCount INTEGER NOT NULL DEFAULT 0,
          lastError TEXT
        )
      '''),
    );
    return _db!;
  }

  Future<int> insert(PendingOccurrence occurrence) async {
    final db = await _open();
    return db.insert(_table, _toRow(occurrence));
  }

  Future<List<PendingOccurrence>> listAll() async {
    final db = await _open();
    final rows = await db.query(_table, orderBy: 'createdAt ASC');
    return rows.map(_fromRow).toList();
  }

  Future<void> remove(int id) async {
    final db = await _open();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markFailedAttempt(int id, {required String error}) async {
    final db = await _open();
    await db.rawUpdate(
      'UPDATE $_table SET retryCount = retryCount + 1, lastError = ? WHERE id = ?',
      [error, id],
    );
  }

  Map<String, Object?> _toRow(PendingOccurrence o) => {
        'description': o.description,
        'latitude': o.latitude,
        'longitude': o.longitude,
        'address': o.address,
        'categoryId': o.categoryId,
        'photoPaths': jsonEncode(o.photoPaths),
        'createdAt': o.createdAt.toIso8601String(),
        'retryCount': o.retryCount,
        'lastError': o.lastError,
      };

  PendingOccurrence _fromRow(Map<String, Object?> row) => PendingOccurrence(
        id: row['id'] as int,
        description: row['description'] as String,
        latitude: row['latitude'] as double,
        longitude: row['longitude'] as double,
        address: row['address'] as String?,
        categoryId: row['categoryId'] as String?,
        photoPaths: (jsonDecode(row['photoPaths'] as String) as List<dynamic>).cast<String>(),
        createdAt: DateTime.parse(row['createdAt'] as String),
        retryCount: row['retryCount'] as int,
        lastError: row['lastError'] as String?,
      );
}
