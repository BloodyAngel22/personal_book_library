/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Personal Book Library';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'book_library.db';
  static const int databaseVersion = 1;

  // API Keys and Endpoints
  static const String googleBooksBaseUrl = 'https://www.googleapis.com/books/v1';
  static const String openLibraryBaseUrl = 'https://openlibrary.org/api';

  // Book Status
  static const String statusToRead = 'to_read';
  static const String statusReading = 'reading';
  static const String statusFinished = 'finished';

  // Date Format
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration heroAnimationDuration = Duration(milliseconds: 400);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxSearchResults = 40;

  // Validation
  static const int minBookTitleLength = 1;
  static const int maxBookTitleLength = 200;
  static const int maxAuthorLength = 100;
  static const int maxDescriptionLength = 5000;
  static const int minPages = 1;
  static const int maxPages = 10000;

  // Placeholder
  static const String placeholderCoverUrl =
      'https://via.placeholder.com/128x192?text=No+Cover';
}

/// Database table and column names
class DatabaseConstants {
  DatabaseConstants._();

  // Table name
  static const String tableBooks = 'books';

  // Column names
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnAuthor = 'author';
  static const String columnDescription = 'description';
  static const String columnThumbnailUrl = 'thumbnail_url';
  static const String columnTotalPages = 'total_pages';
  static const String columnCurrentPage = 'current_page';
  static const String columnStartDate = 'start_date';
  static const String columnStatus = 'status';
  static const String columnIsbn = 'isbn';
  static const String columnPublisher = 'publisher';
  static const String columnPublishedDate = 'published_date';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
}

/// Route names for navigation
class RouteConstants {
  RouteConstants._();

  static const String home = '/';
  static const String search = '/search';
  static const String bookDetail = '/book-detail';
  static const String manualEntry = '/manual-entry';
  static const String scanner = '/scanner';
}
