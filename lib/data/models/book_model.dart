import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// Book model representing a book in the library
class BookModel extends Equatable {
  final int? id;
  final String title;
  final String author;
  final String? description;
  final String? thumbnailUrl;
  final int totalPages;
  final int currentPage;
  final DateTime? startDate;
  final String status;
  final String? isbn;
  final String? publisher;
  final String? publishedDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookModel({
    this.id,
    required this.title,
    required this.author,
    this.description,
    this.thumbnailUrl,
    this.totalPages = 0,
    this.currentPage = 0,
    this.startDate,
    this.status = AppConstants.statusToRead,
    this.isbn,
    this.publisher,
    this.publishedDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Create a copy with optional field overrides
  BookModel copyWith({
    int? id,
    String? title,
    String? author,
    String? description,
    String? thumbnailUrl,
    int? totalPages,
    int? currentPage,
    DateTime? startDate,
    String? status,
    String? isbn,
    String? publisher,
    String? publishedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      isbn: isbn ?? this.isbn,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'total_pages': totalPages,
      'current_page': currentPage,
      'start_date': startDate?.millisecondsSinceEpoch,
      'status': status,
      'isbn': isbn,
      'publisher': publisher,
      'published_date': publishedDate,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from database map
  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String,
      description: map['description'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      totalPages: map['total_pages'] as int? ?? 0,
      currentPage: map['current_page'] as int? ?? 0,
      startDate: map['start_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int)
          : null,
      status: map['status'] as String? ?? AppConstants.statusToRead,
      isbn: map['isbn'] as String?,
      publisher: map['publisher'] as String?,
      publishedDate: map['published_date'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }

  /// Calculate reading progress percentage
  double get progressPercentage {
    if (totalPages <= 0) return 0;
    return (currentPage / totalPages * 100).clamp(0, 100);
  }

  /// Check if book is finished
  bool get isFinished => status == AppConstants.statusFinished;

  /// Check if book is currently being read
  bool get isReading => status == AppConstants.statusReading;

  /// Check if book is in "to read" list
  bool get isToRead => status == AppConstants.statusToRead;

  /// Calculate average pages read per day
  double get pagesPerDay {
    if (startDate == null || currentPage <= 0) return 0;
    final daysElapsed = DateTime.now().difference(startDate!).inDays + 1;
    return currentPage / daysElapsed;
  }

  /// Calculate estimated finish date
  DateTime? get estimatedFinishDate {
    if (startDate == null || totalPages <= 0 || currentPage <= 0) return null;
    if (currentPage >= totalPages) return DateTime.now();
    
    final daysElapsed = DateTime.now().difference(startDate!).inDays + 1;
    final averagePerPage = currentPage / daysElapsed;
    
    if (averagePerPage <= 0) return null;
    
    final remainingPages = totalPages - currentPage;
    final daysRemaining = (remainingPages / averagePerPage).ceil();
    
    return DateTime.now().add(Duration(days: daysRemaining));
  }

  /// Calculate days remaining to finish
  int? get daysRemaining {
    final estimated = estimatedFinishDate;
    if (estimated == null) return null;
    return estimated.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        description,
        thumbnailUrl,
        totalPages,
        currentPage,
        startDate,
        status,
        isbn,
        publisher,
        publishedDate,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'BookModel(id: $id, title: $title, author: $author, status: $status, progress: $progressPercentage%)';
  }
}
