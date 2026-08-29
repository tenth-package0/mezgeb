import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../domain/models.dart';

class VaultDatabase {
  VaultDatabase(this._database);

  final Database _database;

  static Future<VaultDatabase> open(List<int> passphrase) async {
    final dbPath = p.join(await getDatabasesPath(), 'mezgeb_vault.db');
    final password = base64Encode(passphrase);
    final database = await openDatabase(
      dbPath,
      password: password,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE vault_items (
            id TEXT PRIMARY KEY,
            display_name TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            encrypted_file_name TEXT NOT NULL,
            size_bytes INTEGER NOT NULL,
            imported_at INTEGER NOT NULL,
            captured_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE albums (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE album_items (
            album_id TEXT NOT NULL,
            item_id TEXT NOT NULL,
            PRIMARY KEY (album_id, item_id),
            FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE,
            FOREIGN KEY (item_id) REFERENCES vault_items(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    return VaultDatabase(database);
  }

  Future<List<VaultItem>> loadItems() async {
    final rows = await _database.query(
      'vault_items',
      orderBy: 'captured_at DESC',
    );
    return rows.map(VaultItem.fromMap).toList();
  }

  Future<List<VaultItem>> loadItemsForAlbum(String albumId) async {
    final rows = await _database.rawQuery(
      '''
      SELECT vault_items.*
      FROM vault_items
      INNER JOIN album_items ON vault_items.id = album_items.item_id
      WHERE album_items.album_id = ?
      ORDER BY vault_items.captured_at DESC
      ''',
      [albumId],
    );
    return rows.map(VaultItem.fromMap).toList();
  }

  Future<void> insertItem(VaultItem item) async {
    await _database.insert(
      'vault_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteItem(String id) async {
    await _database.delete('vault_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Album>> loadAlbums() async {
    final rows = await _database.rawQuery('''
      SELECT albums.id, albums.name, albums.created_at, COUNT(album_items.item_id) AS item_count
      FROM albums
      LEFT JOIN album_items ON albums.id = album_items.album_id
      GROUP BY albums.id
      ORDER BY albums.created_at DESC
    ''');
    return rows.map((row) {
      return Album(
        id: row['id']! as String,
        name: row['name']! as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at']! as int,
        ),
        itemCount: row['item_count']! as int,
      );
    }).toList();
  }

  Future<List<Album>> loadAlbumsForItem(String itemId) async {
    final rows = await _database.rawQuery(
      '''
      SELECT albums.id, albums.name, albums.created_at, COUNT(album_items.item_id) AS item_count
      FROM albums
      INNER JOIN album_items selected_item ON albums.id = selected_item.album_id
      LEFT JOIN album_items ON albums.id = album_items.album_id
      WHERE selected_item.item_id = ?
      GROUP BY albums.id
      ORDER BY albums.created_at DESC
      ''',
      [itemId],
    );
    return rows.map((row) {
      return Album(
        id: row['id']! as String,
        name: row['name']! as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at']! as int,
        ),
        itemCount: row['item_count']! as int,
      );
    }).toList();
  }

  Future<void> createAlbum(Album album) async {
    await _database.insert('albums', {
      'id': album.id,
      'name': album.name,
      'created_at': album.createdAt.millisecondsSinceEpoch,
    });
  }

  Future<void> deleteAlbum(String id) async {
    await _database.delete('albums', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addItemToAlbum(String itemId, String albumId) async {
    await _database.insert('album_items', {
      'album_id': albumId,
      'item_id': itemId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> moveItemToAlbum(String itemId, String albumId) async {
    await _database.transaction((txn) async {
      await txn.delete(
        'album_items',
        where: 'item_id = ? AND album_id != ?',
        whereArgs: [itemId, albumId],
      );
      await txn.insert('album_items', {
        'album_id': albumId,
        'item_id': itemId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    });
  }
}
