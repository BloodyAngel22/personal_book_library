import 'package:equatable/equatable.dart';
import '../../data/models/book_model.dart';
import '../../core/constants/app_constants.dart';

/// Base state for book operations
abstract class BookState extends Equatable {
  const BookState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BookInitial extends BookState {
  const BookInitial();
}

/// Loading state
class BookLoading extends BookState {
  const BookLoading();
}

/// Books loaded successfully
class BooksLoaded extends BookState {
  final List<BookModel> toReadBooks;
  final List<BookModel> readingBooks;
  final List<BookModel> finishedBooks;
  final Map<String, dynamic>? statistics;

  const BooksLoaded({
    this.toReadBooks = const [],
    this.readingBooks = const [],
    this.finishedBooks = const [],
    this.statistics,
  });

  /// Total count of all books
  int get totalBooks => toReadBooks.length + readingBooks.length + finishedBooks.length;

  /// Create a copy with optional overrides
  BooksLoaded copyWith({
    List<BookModel>? toReadBooks,
    List<BookModel>? readingBooks,
    List<BookModel>? finishedBooks,
    Map<String, dynamic>? statistics,
  }) {
    return BooksLoaded(
      toReadBooks: toReadBooks ?? this.toReadBooks,
      readingBooks: readingBooks ?? this.readingBooks,
      finishedBooks: finishedBooks ?? this.finishedBooks,
      statistics: statistics ?? this.statistics,
    );
  }

  @override
  List<Object?> get props => [toReadBooks, readingBooks, finishedBooks, statistics];
}

/// Single book loaded
class BookDetailLoaded extends BookState {
  final BookModel book;

  const BookDetailLoaded(this.book);

  @override
  List<Object?> get props => [book];
}

/// Book operation success
class BookOperationSuccess extends BookState {
  final String message;
  final BookModel? book;

  const BookOperationSuccess(this.message, {this.book});

  @override
  List<Object?> get props => [message, book];
}

/// Error state
class BookError extends BookState {
  final String message;

  const BookError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Local search results state (for searching in library)
class LocalSearchResultsLoaded extends BookState {
  final List<BookModel> results;
  final String query;
  final LocalSearchFilters filters;
  final int totalMatches;

  const LocalSearchResultsLoaded({
    this.results = const [],
    this.query = '',
    this.filters = const LocalSearchFilters(),
    this.totalMatches = 0,
  });

  bool get hasResults => results.isNotEmpty;

  LocalSearchResultsLoaded copyWith({
    List<BookModel>? results,
    String? query,
    LocalSearchFilters? filters,
    int? totalMatches,
  }) {
    return LocalSearchResultsLoaded(
      results: results ?? this.results,
      query: query ?? this.query,
      filters: filters ?? this.filters,
      totalMatches: totalMatches ?? this.totalMatches,
    );
  }

  @override
  List<Object?> get props => [results, query, filters, totalMatches];
}

/// Filters for local book search
class LocalSearchFilters extends Equatable {
  final Set<String> statuses;
  final String? author;
  final bool hasProgress;
  final SortOption sortBy;
  final bool sortAscending;

  const LocalSearchFilters({
    this.statuses = const {
      AppConstants.statusToRead,
      AppConstants.statusReading,
      AppConstants.statusFinished,
    },
    this.author,
    this.hasProgress = false,
    this.sortBy = SortOption.updatedAt,
    this.sortAscending = false,
  });

  /// Check if any filter is active
  bool get hasActiveFilters =>
      statuses.length < 3 ||
      (author != null && author!.isNotEmpty) ||
      hasProgress;

  LocalSearchFilters copyWith({
    Set<String>? statuses,
    String? author,
    bool? hasProgress,
    SortOption? sortBy,
    bool? sortAscending,
    bool clearAuthor = false,
  }) {
    return LocalSearchFilters(
      statuses: statuses ?? this.statuses,
      author: clearAuthor ? null : (author ?? this.author),
      hasProgress: hasProgress ?? this.hasProgress,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  LocalSearchFilters reset() {
    return const LocalSearchFilters();
  }

  @override
  List<Object?> get props => [statuses, author, hasProgress, sortBy, sortAscending];
}

/// Sort options for books
enum SortOption {
  title,
  author,
  updatedAt,
  progress,
  startDate,
}

/// Online search results state (for adding new books)
class OnlineSearchResultsLoaded extends BookState {
  final List<BookModel> results;
  final String query;
  final bool isLoading;
  final Set<String> addedIsbns;

  const OnlineSearchResultsLoaded({
    this.results = const [],
    this.query = '',
    this.isLoading = false,
    this.addedIsbns = const {},
  });

  bool get hasResults => results.isNotEmpty;

  OnlineSearchResultsLoaded copyWith({
    List<BookModel>? results,
    String? query,
    bool? isLoading,
    Set<String>? addedIsbns,
  }) {
    return OnlineSearchResultsLoaded(
      results: results ?? this.results,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      addedIsbns: addedIsbns ?? this.addedIsbns,
    );
  }

  @override
  List<Object?> get props => [results, query, isLoading, addedIsbns];
}

/// Scanner state
class ScannerReady extends BookState {
  const ScannerReady();
}

/// ISBN scanned and fetching book
class IsbnScanning extends BookState {
  final String isbn;

  const IsbnScanning(this.isbn);

  @override
  List<Object?> get props => [isbn];
}

/// Book found by ISBN
class BookFoundByIsbn extends BookState {
  final BookModel book;

  const BookFoundByIsbn(this.book);

  @override
  List<Object?> get props => [book];
}

/// Book not found by ISBN
class BookNotFoundByIsbn extends BookState {
  final String isbn;

  const BookNotFoundByIsbn(this.isbn);

  @override
  List<Object?> get props => [isbn];
}
