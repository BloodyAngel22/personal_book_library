import 'package:dio/dio.dart';
import '../models/book_model.dart';
import '../../core/constants/app_constants.dart';

/// API service for fetching book data from Google Books and Open Library APIs
class BookApiService {
  final Dio _dio;

  BookApiService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );
  }

  /// Search for books by ISBN - tries Google Books first, then Open Library
  Future<BookModel?> fetchBookByIsbn(String isbn) async {
    // Clean ISBN
    final cleanIsbn = isbn.replaceAll(RegExp(r'[^0-9X]'), '');

    // Try Google Books first
    try {
      final book = await _fetchFromGoogleBooks(cleanIsbn);
      if (book != null) return book;
    } catch (e) {
      // Continue to fallback
    }

    // Fallback to Open Library
    try {
      final book = await _fetchFromOpenLibrary(cleanIsbn);
      if (book != null) return book;
    } catch (e) {
      // Return null if both fail
    }

    return null;
  }

  /// Search books by title or author
  Future<List<BookModel>> searchBooks(String query, {int maxResults = 20}) async {
    try {
      final results = await _searchGoogleBooks(query, maxResults: maxResults);
      if (results.isNotEmpty) return results;
    } catch (e) {
      // Continue to fallback
    }

    // Fallback to Open Library search
    try {
      return await _searchOpenLibrary(query, maxResults: maxResults);
    } catch (e) {
      return [];
    }
  }

  /// Fetch book from Google Books API by ISBN
  Future<BookModel?> _fetchFromGoogleBooks(String isbn) async {
    final response = await _dio.get(
      '${AppConstants.googleBooksBaseUrl}/volumes',
      queryParameters: {
        'q': 'isbn:$isbn',
        'maxResults': 1,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['totalItems'] != null && data['totalItems'] > 0) {
        final items = data['items'] as List;
        if (items.isNotEmpty) {
          return _parseGoogleBookItem(items.first, isbn);
        }
      }
    }

    return null;
  }

  /// Fetch book from Open Library API by ISBN
  Future<BookModel?> _fetchFromOpenLibrary(String isbn) async {
    final response = await _dio.get(
      '${AppConstants.openLibraryBaseUrl}/books',
      queryParameters: {
        'bibkeys': 'ISBN:$isbn',
        'format': 'json',
        'jscmd': 'data',
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final bookData = data['ISBN:$isbn'];
      if (bookData != null) {
        return _parseOpenLibraryBook(bookData, isbn);
      }
    }

    return null;
  }

  /// Search Google Books API
  Future<List<BookModel>> _searchGoogleBooks(String query, {int maxResults = 20}) async {
    final response = await _dio.get(
      '${AppConstants.googleBooksBaseUrl}/volumes',
      queryParameters: {
        'q': query,
        'maxResults': maxResults,
        'printType': 'books',
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final items = data['items'] as List? ?? [];
      return items
          .map((item) => _parseGoogleBookItem(item))
          .where((book) => book != null)
          .cast<BookModel>()
          .toList();
    }

    return [];
  }

  /// Search Open Library API
  Future<List<BookModel>> _searchOpenLibrary(String query, {int maxResults = 20}) async {
    final response = await _dio.get(
      'https://openlibrary.org/search.json',
      queryParameters: {
        'q': query,
        'limit': maxResults,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final docs = data['docs'] as List? ?? [];
      return docs
          .map((doc) => _parseOpenLibrarySearchResult(doc))
          .where((book) => book != null)
          .cast<BookModel>()
          .toList();
    }

    return [];
  }

  /// Parse Google Books API item
  BookModel? _parseGoogleBookItem(dynamic item, [String? isbn]) {
    try {
      final volumeInfo = item['volumeInfo'] as Map<String, dynamic>?;

      if (volumeInfo == null) return null;

      final title = volumeInfo['title'] as String? ?? 'Unknown Title';
      final authors = volumeInfo['authors'] as List?;
      final author = authors != null && authors.isNotEmpty
          ? authors.join(', ')
          : 'Unknown Author';

      // Get page count
      final pageCount = volumeInfo['pageCount'] as int? ?? 0;

      // Get thumbnail
      final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
      String? thumbnailUrl;
      if (imageLinks != null) {
        thumbnailUrl = (imageLinks['thumbnail'] ?? imageLinks['smallThumbnail']) as String?;
        // Upgrade to higher quality if available
        if (thumbnailUrl != null) {
          thumbnailUrl = thumbnailUrl.replaceFirst(
            'http://',
            'https://',
          );
        }
      }

      // Get ISBN
      String? bookIsbn = isbn;
      final industryIdentifiers = volumeInfo['industryIdentifiers'] as List?;
      if (industryIdentifiers != null && bookIsbn == null) {
        for (final identifier in industryIdentifiers) {
          final type = identifier['type'] as String?;
          if (type == 'ISBN_13' || type == 'ISBN_10') {
            bookIsbn = identifier['identifier'] as String;
            break;
          }
        }
      }

      return BookModel(
        title: title,
        author: author,
        description: volumeInfo['description'] as String?,
        thumbnailUrl: thumbnailUrl,
        totalPages: pageCount,
        isbn: bookIsbn,
        publisher: (volumeInfo['publisher'] as String?) ??
            (volumeInfo['publishers'] as List?)?.firstOrNull?.toString(),
        publishedDate: volumeInfo['publishedDate'] as String?,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse Open Library book data
  BookModel? _parseOpenLibraryBook(dynamic data, String isbn) {
    try {
      final title = data['title'] as String? ?? 'Unknown Title';
      final authors = data['authors'] as List?;
      final author = authors != null && authors.isNotEmpty
          ? (authors.first['name'] as String?) ?? 'Unknown Author'
          : 'Unknown Author';

      final numberOfPages = data['number_of_pages'] as int? ?? 0;

      // Get cover URL
      String? thumbnailUrl;
      final cover = data['cover'];
      if (cover != null) {
        thumbnailUrl = cover['medium'] ?? cover['small'] ?? cover['large'];
        if (thumbnailUrl is String) {
          thumbnailUrl = thumbnailUrl.replaceFirst('http://', 'https://');
        }
      }

      // Alternative cover URL format
      if (thumbnailUrl == null && isbn.isNotEmpty) {
        thumbnailUrl = 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg';
      }

      return BookModel(
        title: title,
        author: author,
        description: null, // Open Library basic API doesn't provide description
        thumbnailUrl: thumbnailUrl,
        totalPages: numberOfPages,
        isbn: isbn,
        publisher: (data['publishers'] as List?)?.firstOrNull?['name'] as String?,
        publishedDate: data['publish_date'] as String?,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse Open Library search result
  BookModel? _parseOpenLibrarySearchResult(dynamic doc) {
    try {
      final title = doc['title'] as String? ?? 'Unknown Title';
      final authorNames = doc['author_name'] as List?;
      final author = authorNames != null && authorNames.isNotEmpty
          ? authorNames.join(', ')
          : 'Unknown Author';

      final isbnList = doc['isbn'] as List?;
      final isbn = isbnList != null && isbnList.isNotEmpty
          ? isbnList.first as String
          : null;

      // Get cover URL
      String? thumbnailUrl;
      final coverId = doc['cover_i'] as int?;
      if (coverId != null) {
        thumbnailUrl = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
      } else if (isbn != null) {
        thumbnailUrl = 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg';
      }

      final numberOfPages = doc['number_of_pages_median'] as int? ?? 0;

      return BookModel(
        title: title,
        author: author,
        description: null,
        thumbnailUrl: thumbnailUrl,
        totalPages: numberOfPages,
        isbn: isbn,
        publisher: (doc['publisher'] as List?)?.firstOrNull as String?,
        publishedDate: (doc['publish_year'] as List?)?.firstOrNull?.toString(),
      );
    } catch (e) {
      return null;
    }
  }
}

/// Extension for null-safe first element
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
