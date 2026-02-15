import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/book_model.dart';
import '../../data/repositories/book_repository.dart';
import '../../core/constants/app_constants.dart';
import '../states/book_state.dart';

/// Cubit for managing book state and operations
class BookCubit extends Cubit<BookState> {
  final BookRepository _repository;

  /// Cache the last loaded books to avoid unnecessary reloading
  BooksLoaded? _lastLoadedState;

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

      _lastLoadedState = BooksLoaded(
        toReadBooks: toReadBooks,
        readingBooks: readingBooks,
        finishedBooks: finishedBooks,
        statistics: statistics,
      );

      emit(_lastLoadedState!);
    } catch (e) {
      emit(BookError('Failed to load books: ${e.toString()}'));
    }
  }

  /// Refresh books list silently (without showing loading)
  Future<void> _refreshBooksSilently() async {
    try {
      final toReadBooks = await _repository.getToReadBooks();
      final readingBooks = await _repository.getReadingBooks();
      final finishedBooks = await _repository.getFinishedBooks();
      final statistics = await _repository.getStatistics();

      _lastLoadedState = BooksLoaded(
        toReadBooks: toReadBooks,
        readingBooks: readingBooks,
        finishedBooks: finishedBooks,
        statistics: statistics,
      );

      emit(_lastLoadedState!);
    } catch (e) {
      // Don't emit error for silent refresh
    }
  }

  /// Load a single book by ID
  Future<void> loadBookById(int id) async {
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

  /// Update reading progress - properly refreshes the book list
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
      
      // Emit the updated book detail
      emit(BookDetailLoaded(updatedBook));
      
      // Refresh the books list silently to update the tabs
      await _refreshBooksSilently();
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

  // ==================== LOCAL SEARCH (Library Search) ====================

  /// Search books in local library with filters
  Future<void> searchLocalLibrary({
    String query = '',
    LocalSearchFilters? filters,
  }) async {
    final currentFilters = filters ?? const LocalSearchFilters();
    
    try {
      // Get all books first
      final allBooks = await _repository.getAllBooks();
      
      // Apply filters
      var filteredBooks = allBooks.where((book) {
        // Status filter
        if (!currentFilters.statuses.contains(book.status)) {
          return false;
        }
        
        // Query filter (search in title and author)
        if (query.isNotEmpty) {
          final queryLower = query.toLowerCase();
          final titleMatch = book.title.toLowerCase().contains(queryLower);
          final authorMatch = book.author.toLowerCase().contains(queryLower);
          final isbnMatch = book.isbn?.contains(query) ?? false;
          if (!titleMatch && !authorMatch && !isbnMatch) {
            return false;
          }
        }
        
        // Author filter
        if (currentFilters.author != null && currentFilters.author!.isNotEmpty) {
          if (!book.author.toLowerCase().contains(currentFilters.author!.toLowerCase())) {
            return false;
          }
        }
        
        // Has progress filter
        if (currentFilters.hasProgress && book.currentPage <= 0) {
          return false;
        }
        
        return true;
      }).toList();
      
      // Apply sorting
      filteredBooks.sort((a, b) {
        int result;
        switch (currentFilters.sortBy) {
          case SortOption.title:
            result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
            break;
          case SortOption.author:
            result = a.author.toLowerCase().compareTo(b.author.toLowerCase());
            break;
          case SortOption.progress:
            result = a.progressPercentage.compareTo(b.progressPercentage);
            break;
          case SortOption.startDate:
            final dateA = a.startDate ?? DateTime(1970);
            final dateB = b.startDate ?? DateTime(1970);
            result = dateA.compareTo(dateB);
            break;
          case SortOption.updatedAt:
          default:
            final dateA = a.updatedAt ?? DateTime(1970);
            final dateB = b.updatedAt ?? DateTime(1970);
            result = dateA.compareTo(dateB);
        }
        return currentFilters.sortAscending ? result : -result;
      });
      
      emit(LocalSearchResultsLoaded(
        results: filteredBooks,
        query: query,
        filters: currentFilters,
        totalMatches: filteredBooks.length,
      ));
    } catch (e) {
      emit(BookError('Search failed: ${e.toString()}'));
    }
  }

  /// Update filters for local search
  Future<void> updateLocalSearchFilters(LocalSearchFilters filters) async {
    final currentState = state;
    String query = '';
    if (currentState is LocalSearchResultsLoaded) {
      query = currentState.query;
    }
    await searchLocalLibrary(query: query, filters: filters);
  }

  /// Clear local search and return to books list
  void clearLocalSearch() {
    if (_lastLoadedState != null) {
      emit(_lastLoadedState!);
    } else {
      emit(const BooksLoaded());
    }
  }

  // ==================== ONLINE SEARCH (Add Books) ====================

  /// Search for books online (for adding new books)
  Future<void> searchOnline(String query, {Set<String>? addedIsbns}) async {
    if (query.trim().isEmpty) {
      emit(OnlineSearchResultsLoaded(
        addedIsbns: addedIsbns ?? {},
      ));
      return;
    }

    emit(OnlineSearchResultsLoaded(
      query: query,
      isLoading: true,
      addedIsbns: addedIsbns ?? {},
    ));
    
    try {
      final results = await _repository.searchOnline(query);
      emit(OnlineSearchResultsLoaded(
        results: results,
        query: query,
        isLoading: false,
        addedIsbns: addedIsbns ?? {},
      ));
    } catch (e) {
      emit(BookError('Online search failed: ${e.toString()}'));
    }
  }

  /// Mark a book as added in online search results
  void markBookAsAdded(String isbn) {
    final currentState = state;
    if (currentState is OnlineSearchResultsLoaded) {
      final newAddedIsbns = Set<String>.from(currentState.addedIsbns);
      newAddedIsbns.add(isbn);
      emit(currentState.copyWith(addedIsbns: newAddedIsbns));
    }
  }

  /// Clear online search results
  void clearOnlineSearch() {
    emit(const OnlineSearchResultsLoaded());
  }

  // ==================== SCANNER ====================

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

  // ==================== UTILITIES ====================

  /// Reset to initial state
  void reset() {
    _lastLoadedState = null;
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

  /// Get the last loaded books state (useful for navigation)
  BooksLoaded? get lastLoadedState => _lastLoadedState;
  
  /// Get all unique authors from library (for filter dropdown)
  Future<List<String>> getAuthors() async {
    final books = await _repository.getAllBooks();
    final authors = <String>{};
    for (final book in books) {
      authors.add(book.author);
    }
    final authorList = authors.toList();
    authorList.sort();
    return authorList;
  }
}
