import '../models/book_model.dart';
import '../providers/book_api_service.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/app_constants.dart';

/// Repository for book operations combining local database and API
class BookRepository {
  final DatabaseHelper _dbHelper;
  final BookApiService _apiService;

  BookRepository({
    DatabaseHelper? dbHelper,
    BookApiService? apiService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _apiService = apiService ?? BookApiService();

  /// Get all books from local database
  Future<List<BookModel>> getAllBooks() async {
    final maps = await _dbHelper.getAllBooks();
    return maps.map((map) => BookModel.fromMap(map)).toList();
  }

  /// Get books by status
  Future<List<BookModel>> getBooksByStatus(String status) async {
    final maps = await _dbHelper.getBooksByStatus(status);
    return maps.map((map) => BookModel.fromMap(map)).toList();
  }

  /// Get a single book by ID
  Future<BookModel?> getBookById(int id) async {
    final map = await _dbHelper.getBookById(id);
    return map != null ? BookModel.fromMap(map) : null;
  }

  /// Add a book to the library
  Future<BookModel> addBook(BookModel book) async {
    // Check if book with same ISBN already exists
    if (book.isbn != null && book.isbn!.isNotEmpty) {
      final existing = await _dbHelper.getBookByIsbn(book.isbn!);
      if (existing != null) {
        return BookModel.fromMap(existing);
      }
    }

    final id = await _dbHelper.insertBook(book.toMap());
    return book.copyWith(id: id);
  }

  /// Update an existing book
  Future<BookModel> updateBook(BookModel book) async {
    if (book.id == null) throw ArgumentError('Book ID is required for update');

    await _dbHelper.updateBook(book.id!, book.toMap());
    return book;
  }

  /// Update reading progress
  Future<BookModel> updateReadingProgress({
    required int bookId,
    required int currentPage,
    String? status,
  }) async {
    final book = await getBookById(bookId);
    if (book == null) throw ArgumentError('Book not found');

    // Determine new status
    String newStatus = status ?? book.status;
    if (currentPage >= book.totalPages && book.totalPages > 0) {
      newStatus = AppConstants.statusFinished;
    } else if (currentPage > 0 && book.status == AppConstants.statusToRead) {
      newStatus = AppConstants.statusReading;
    }

    await _dbHelper.updateReadingProgress(bookId, currentPage, newStatus);

    return book.copyWith(
      currentPage: currentPage,
      status: newStatus,
      startDate: newStatus == AppConstants.statusReading && book.startDate == null
          ? DateTime.now()
          : book.startDate,
    );
  }

  /// Delete a book from the library
  Future<void> deleteBook(int id) async {
    await _dbHelper.deleteBook(id);
  }

  /// Search for books online
  Future<List<BookModel>> searchOnline(String query) async {
    return await _apiService.searchBooks(query);
  }

  /// Fetch book by ISBN (online)
  Future<BookModel?> fetchBookByIsbn(String isbn) async {
    return await _apiService.fetchBookByIsbn(isbn);
  }

  /// Search local books
  Future<List<BookModel>> searchLocal(String query) async {
    final maps = await _dbHelper.searchBooks(query);
    return maps.map((map) => BookModel.fromMap(map)).toList();
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    return await _dbHelper.getStatistics();
  }

  /// Get all "To Read" books
  Future<List<BookModel>> getToReadBooks() async {
    return await getBooksByStatus(AppConstants.statusToRead);
  }

  /// Get all "Reading" books
  Future<List<BookModel>> getReadingBooks() async {
    return await getBooksByStatus(AppConstants.statusReading);
  }

  /// Get all "Finished" books
  Future<List<BookModel>> getFinishedBooks() async {
    return await getBooksByStatus(AppConstants.statusFinished);
  }

  /// Move book to "Reading" status
  Future<BookModel> startReading(int bookId) async {
    final book = await getBookById(bookId);
    if (book == null) throw ArgumentError('Book not found');

    return await updateBook(book.copyWith(
      status: AppConstants.statusReading,
      startDate: DateTime.now(),
    ));
  }

  /// Move book to "Finished" status
  Future<BookModel> finishBook(int bookId) async {
    final book = await getBookById(bookId);
    if (book == null) throw ArgumentError('Book not found');

    return await updateBook(book.copyWith(
      status: AppConstants.statusFinished,
      currentPage: book.totalPages,
    ));
  }

  /// Get count of books by status
  Future<int> getBookCount(String status) async {
    final books = await getBooksByStatus(status);
    return books.length;
  }

  /// Check if ISBN already exists in library
  Future<bool> isIsbnExists(String isbn) async {
    final existing = await _dbHelper.getBookByIsbn(isbn);
    return existing != null;
  }
}
