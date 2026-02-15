import 'package:equatable/equatable.dart';
import '../../data/models/book_model.dart';

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

/// Search results state
class SearchResultsLoaded extends BookState {
  final List<BookModel> onlineResults;
  final List<BookModel> localResults;
  final String query;

  const SearchResultsLoaded({
    this.onlineResults = const [],
    this.localResults = const [],
    this.query = '',
  });

  bool get hasResults => onlineResults.isNotEmpty || localResults.isNotEmpty;

  @override
  List<Object?> get props => [onlineResults, localResults, query];
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
