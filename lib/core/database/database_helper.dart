import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

/// Database helper for SQLite operations
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables on first launch
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableBooks} (
        ${DatabaseConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.columnTitle} TEXT NOT NULL,
        ${DatabaseConstants.columnAuthor} TEXT NOT NULL,
        ${DatabaseConstants.columnDescription} TEXT,
        ${DatabaseConstants.columnThumbnailUrl} TEXT,
        ${DatabaseConstants.columnTotalPages} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.columnCurrentPage} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.columnStartDate} INTEGER,
        ${DatabaseConstants.columnStatus} TEXT NOT NULL DEFAULT '${AppConstants.statusToRead}',
        ${DatabaseConstants.columnIsbn} TEXT,
        ${DatabaseConstants.columnPublisher} TEXT,
        ${DatabaseConstants.columnPublishedDate} TEXT,
        ${DatabaseConstants.columnCreatedAt} INTEGER NOT NULL,
        ${DatabaseConstants.columnUpdatedAt} INTEGER NOT NULL
      )
    ''');

    // Create indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_books_status ON ${DatabaseConstants.tableBooks}(${DatabaseConstants.columnStatus})
    ''');
    await db.execute('''
      CREATE INDEX idx_books_isbn ON ${DatabaseConstants.tableBooks}(${DatabaseConstants.columnIsbn})
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Handle future schema migrations here
    }
  }

  /// Insert a new book
  Future<int> insertBook(Map<String, dynamic> book) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    book[DatabaseConstants.columnCreatedAt] = now;
    book[DatabaseConstants.columnUpdatedAt] = now;
    return await db.insert(
      DatabaseConstants.tableBooks,
      book,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all books
  Future<List<Map<String, dynamic>>> getAllBooks() async {
    final db = await database;
    return await db.query(
      DatabaseConstants.tableBooks,
      orderBy: '${DatabaseConstants.columnUpdatedAt} DESC',
    );
  }

  /// Get books by status
  Future<List<Map<String, dynamic>>> getBooksByStatus(String status) async {
    final db = await database;
    return await db.query(
      DatabaseConstants.tableBooks,
      where: '${DatabaseConstants.columnStatus} = ?',
      whereArgs: [status],
      orderBy: '${DatabaseConstants.columnUpdatedAt} DESC',
    );
  }

  /// Get a single book by ID
  Future<Map<String, dynamic>?> getBookById(int id) async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.tableBooks,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get book by ISBN
  Future<Map<String, dynamic>?> getBookByIsbn(String isbn) async {
    final db = await database;
    final results = await db.query(
      DatabaseConstants.tableBooks,
      where: '${DatabaseConstants.columnIsbn} = ?',
      whereArgs: [isbn],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Update a book
  Future<int> updateBook(int id, Map<String, dynamic> updates) async {
    final db = await database;
    updates[DatabaseConstants.columnUpdatedAt] =
        DateTime.now().millisecondsSinceEpoch;
    return await db.update(
      DatabaseConstants.tableBooks,
      updates,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Update reading progress
  Future<int> updateReadingProgress(int id, int currentPage, String status) async {
    final db = await database;
    final updates = <String, dynamic>{
      DatabaseConstants.columnCurrentPage: currentPage,
      DatabaseConstants.columnStatus: status,
      DatabaseConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
    };

    // Set start date when starting to read
    if (status == AppConstants.statusReading) {
      final book = await getBookById(id);
      if (book != null && book[DatabaseConstants.columnStartDate] == null) {
        updates[DatabaseConstants.columnStartDate] =
            DateTime.now().millisecondsSinceEpoch;
      }
    }

    return await db.update(
      DatabaseConstants.tableBooks,
      updates,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Delete a book
  Future<int> deleteBook(int id) async {
    final db = await database;
    return await db.delete(
      DatabaseConstants.tableBooks,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Get reading statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;

    // Total books count
    final totalBooks = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableBooks}',
      ),
    ) ?? 0;

    // Books by status
    final toReadCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableBooks} WHERE ${DatabaseConstants.columnStatus} = ?',
        [AppConstants.statusToRead],
      ),
    ) ?? 0;

    final readingCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableBooks} WHERE ${DatabaseConstants.columnStatus} = ?',
        [AppConstants.statusReading],
      ),
    ) ?? 0;

    final finishedCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.tableBooks} WHERE ${DatabaseConstants.columnStatus} = ?',
        [AppConstants.statusFinished],
      ),
    ) ?? 0;

    // Total pages read
    final totalPagesRead = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT SUM(${DatabaseConstants.columnCurrentPage}) FROM ${DatabaseConstants.tableBooks}',
      ),
    ) ?? 0;

    // Total pages in library
    final totalPages = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT SUM(${DatabaseConstants.columnTotalPages}) FROM ${DatabaseConstants.tableBooks}',
      ),
    ) ?? 0;

    return {
      'totalBooks': totalBooks,
      'toReadCount': toReadCount,
      'readingCount': readingCount,
      'finishedCount': finishedCount,
      'totalPagesRead': totalPagesRead,
      'totalPages': totalPages,
      'completionRate': totalPages > 0
          ? (totalPagesRead / totalPages * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  /// Search books by title or author
  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    final db = await database;
    return await db.query(
      DatabaseConstants.tableBooks,
      where: '''
        ${DatabaseConstants.columnTitle} LIKE ? OR 
        ${DatabaseConstants.columnAuthor} LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: '${DatabaseConstants.columnUpdatedAt} DESC',
    );
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
