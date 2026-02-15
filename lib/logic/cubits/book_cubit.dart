import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/book_model.dart';
import '../../data/repositories/book_repository.dart';
import '../../core/constants/app_constants.dart';
import '../states/book_state.dart';

/// Cubit for managing book state and operations
class BookCubit extends Cubit<BookState> {
  final BookRepository _repository;

  BookCubit({BookRepository? repository})
      : _repository = repository ?? BookRepository(),
        super(const BookInitial());

  /// Load all books grouped by status
  Future<void> loadBooks() async {
    emit(const BookLoading());
    try {
      final toReadBooks = await _repository.getToReadBooks();
      final readingBooks = await _repository.getReadingBooks();
      final finishedBooks = await _repository.getFinishedBooks();
      final statistics = await _repository.getStatistics();

      emit(BooksLoaded(
        toReadBooks: toReadBooks,
        readingBooks: readingBooks,
        finishedBooks: finishedBooks,
        statistics: statistics,
      ));
    } catch (e) {
      emit(BookError('Failed to load books: ${e.toString()}'));
    }
  }

  /// Load a single book by ID
  Future<void> loadBookById(int id) async {
    emit(const BookLoading());
    try {
      final book = await _repository.getBookById(id);
      if (book != null) {
        emit(BookDetailLoaded(book));
      } else {
        emit(const BookError('Book not found'));
      }
    } catch (e) {
      emit(BookError('Failed to load book: ${e.toString()}'));
    }
  }

  /// Add a new book to the library
  Future<void> addBook(BookModel book) async {
    try {
      final addedBook = await _repository.addBook(book);
      emit(BookOperationSuccess('Book added successfully', book: addedBook));
      await loadBooks();
    } catch (e) {
      emit(BookError('Failed to add book: ${e.toString()}'));
    }
  }

  /// Update an existing book
  Future<void> updateBook(BookModel book) async {
    try {
      await _repository.updateBook(book);
      emit(BookOperationSuccess('Book updated successfully', book: book));
      await loadBooks();
    } catch (e) {
      emit(BookError('Failed to update book: ${e.toString()}'));
    }
  }

  /// Delete a book
  Future<void> deleteBook(int id) async {
    try {
      await _repository.deleteBook(id);
      emit(const BookOperationSuccess('Book deleted successfully'));
      await loadBooks();
    } catch (e) {
      emit(BookError('Failed to delete book: ${e.toString()}'));
    }
  }

  /// Update reading progress
  Future<void> updateProgress({
    required int bookId,
    required int currentPage,
    String? status,
  }) async {
    try {
      final updatedBook = await _repository.updateReadingProgress(
        bookId: bookId,
        currentPage: currentPage,
        status: status,
      );
      emit(BookDetailLoaded(updatedBook));
    } catch (e) {
      emit(BookError('Failed to update progress: ${e.toString()}'));
    }
  }

  /// Start reading a book
  Future<void> startReading(int bookId) async {
    try {
      final book = await _repository.startReading(bookId);
      emit(BookDetailLoaded(book));
      await loadBooks();
    } catch (e) {
      emit(BookError('Failed to start reading: ${e.toString()}'));
    }
  }

  /// Finish reading a book
  Future<void> finishBook(int bookId) async {
    try {
      final book = await _repository.finishBook(bookId);
      emit(BookDetailLoaded(book));
      await loadBooks();
    } catch (e) {
      emit(BookError('Failed to finish book: ${e.toString()}'));
    }
  }

  /// Search books online
  Future<void> searchOnline(String query) async {
    if (query.trim().isEmpty) {
      emit(const SearchResultsLoaded());
      return;
    }

    emit(const BookLoading());
    try {
      final onlineResults = await _repository.searchOnline(query);
      final localResults = await _repository.searchLocal(query);
      emit(SearchResultsLoaded(
        onlineResults: onlineResults,
        localResults: localResults,
        query: query,
      ));
    } catch (e) {
      emit(BookError('Search failed: ${e.toString()}'));
    }
  }

  /// Search local books only
  Future<void> searchLocal(String query) async {
    if (query.trim().isEmpty) {
      emit(const SearchResultsLoaded());
      return;
    }

    try {
      final localResults = await _repository.searchLocal(query);
      emit(SearchResultsLoaded(
        localResults: localResults,
        query: query,
      ));
    } catch (e) {
      emit(BookError('Local search failed: ${e.toString()}'));
    }
  }

  /// Fetch book by ISBN (for scanner)
  Future<void> fetchBookByIsbn(String isbn) async {
    emit(IsbnScanning(isbn));
    try {
      final book = await _repository.fetchBookByIsbn(isbn);
      if (book != null) {
        emit(BookFoundByIsbn(book));
      } else {
        emit(BookNotFoundByIsbn(isbn));
      }
    } catch (e) {
      emit(BookError('Failed to fetch book by ISBN: ${e.toString()}'));
    }
  }

  /// Add book found by ISBN scanner
  Future<void> addScannedBook(BookModel book, int totalPages) async {
    try {
      final bookWithPages = book.copyWith(totalPages: totalPages);
      await addBook(bookWithPages);
    } catch (e) {
      emit(BookError('Failed to add scanned book: ${e.toString()}'));
    }
  }

  /// Clear search results
  void clearSearch() {
    emit(const SearchResultsLoaded());
  }

  /// Reset to initial state
  void reset() {
    emit(const BookInitial());
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    return await _repository.getStatistics();
  }

  /// Check if ISBN exists in library
  Future<bool> isIsbnExists(String isbn) async {
    return await _repository.isIsbnExists(isbn);
  }
}
