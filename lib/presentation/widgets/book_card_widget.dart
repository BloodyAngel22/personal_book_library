import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/book_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/cubits/book_cubit.dart';
import '../../logic/states/book_state.dart';
import '../screens/book_detail_screen.dart';
import 'shimmer_loading.dart';

/// Book card widget displaying book information with progress bar
class BookCard extends StatelessWidget {
  final BookModel book;
  final bool showProgress;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BookCard({
    super.key,
    required this.book,
    this.showProgress = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => _navigateToDetail(context),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover with Hero animation
              Hero(
                tag: 'book_cover_${book.id}',
                child: _buildCover(),
              ),
              const SizedBox(width: 12),
              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Author
                    Text(
                      book.author,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showProgress && book.totalPages > 0) ...[
                      const SizedBox(height: 12),
                      // Progress bar
                      _buildProgressBar(context),
                      const SizedBox(height: 4),
                      // Page count
                      Text(
                        '${book.currentPage} / ${book.totalPages} pages',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                      ),
                    ],
                    if (book.isReading && book.daysRemaining != null) ...[
                      const SizedBox(height: 8),
                      // Estimated days remaining
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppTheme.infoColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '~${book.daysRemaining} days left',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.infoColor,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Status indicator
              _buildStatusIndicator(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: book.thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: book.thumbnailUrl!,
              width: 60,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (context, url) => const ShimmerLoading(
                width: 60,
                height: 90,
                borderRadius: 8,
              ),
              errorWidget: (context, url, error) => _buildPlaceholderCover(),
            )
          : _buildPlaceholderCover(),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.book,
        color: Colors.white54,
        size: 30,
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Stack(
      children: [
        // Background
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        // Progress
        FractionallySizedBox(
          widthFactor: book.progressPercentage / 100,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: AppTheme.progressGradient,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    Color color;
    IconData icon;

    switch (book.status) {
      case AppConstants.statusReading:
        color = AppTheme.infoColor;
        icon = Icons.auto_stories;
        break;
      case AppConstants.statusFinished:
        color = AppTheme.successColor;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey.shade600;
        icon = Icons.bookmark_border;
    }

    return Icon(icon, color: color, size: 20);
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(book: book),
      ),
    );
  }
}

/// Compact book card for grid view
class BookCardCompact extends StatelessWidget {
  final BookModel book;
  final VoidCallback? onTap;

  const BookCardCompact({
    super.key,
    required this.book,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover with Hero
            Expanded(
              child: Hero(
                tag: 'book_cover_${book.id}',
                child: _buildCover(),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    return book.thumbnailUrl != null
        ? CachedNetworkImage(
            imageUrl: book.thumbnailUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => const ShimmerLoading(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade800,
              child: const Icon(
                Icons.book,
                color: Colors.white54,
                size: 40,
              ),
            ),
          )
        : Container(
            color: Colors.grey.shade800,
            child: const Icon(
              Icons.book,
              color: Colors.white54,
              size: 40,
            ),
          );
  }
}

/// Search result book card with add button
class SearchResultCard extends StatelessWidget {
  final BookModel book;
  final bool isAdded;
  final VoidCallback? onAdd;

  const SearchResultCard({
    super.key,
    required this.book,
    this.isAdded = false,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: book.thumbnailUrl!,
                      width: 50,
                      height: 75,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ShimmerLoading(
                        width: 50,
                        height: 75,
                        borderRadius: 8,
                      ),
                      errorWidget: (context, url, error) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade400,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.totalPages > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${book.totalPages} pages',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Add button
            if (onAdd != null)
              IconButton(
                icon: Icon(
                  isAdded ? Icons.check : Icons.add_circle_outline,
                  color: isAdded ? AppTheme.successColor : AppTheme.infoColor,
                ),
                onPressed: isAdded ? null : onAdd,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 50,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.book,
        color: Colors.white54,
        size: 24,
      ),
    );
  }
}
