import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../logic/cubits/book_cubit.dart';
import '../../logic/states/book_state.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/shimmer_loading.dart';

/// Book detail screen showing full book information and reading progress
class BookDetailScreen extends StatefulWidget {
  static const String name = 'BookDetailScreen';

  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late BookModel _currentBook;
  late TextEditingController _pageController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _pageController = TextEditingController(text: _currentBook.currentPage.toString());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookCubit, BookState>(
      listener: (context, state) {
        if (state is BookDetailLoaded) {
          setState(() => _currentBook = state.book);
        }
        if (state is BookOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildProgressSection(context),
                      const SizedBox(height: 24),
                      if (_currentBook.isReading) ...[
                        _buildReadingStats(context),
                        const SizedBox(height: 24),
                      ],
                      _buildDescription(context),
                      const SizedBox(height: 24),
                      _buildBookInfo(context),
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.headerGradient,
          ),
          child: SafeArea(
            child: Center(
              child: Hero(
                tag: 'book_cover_${_currentBook.id}',
                child: _buildCoverImage(context),
              ),
            ),
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Book'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _currentBook.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: _currentBook.thumbnailUrl!,
                width: 120,
                height: 180,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerLoading(
                  width: 120,
                  height: 180,
                  borderRadius: 12,
                ),
                errorWidget: (context, url, error) => _buildPlaceholderCover(),
              )
            : _buildPlaceholderCover(),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      width: 120,
      height: 180,
      color: Colors.grey.shade800,
      child: const Icon(
        Icons.book,
        color: Colors.white54,
        size: 48,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentBook.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'by ${_currentBook.author}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade400,
              ),
        ),
        const SizedBox(height: 16),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;

    switch (_currentBook.status) {
      case AppConstants.statusReading:
        color = AppTheme.infoColor;
        label = 'Currently Reading';
        break;
      case AppConstants.statusFinished:
        color = AppTheme.successColor;
        label = 'Finished';
        break;
      default:
        color = Colors.grey.shade600;
        label = 'To Read';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    if (_currentBook.totalPages <= 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.info_outline, color: AppTheme.warningColor),
              const SizedBox(height: 8),
              Text(
                'No page count available. Tap to edit.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showEditPagesDialog(),
                icon: const Icon(Icons.edit),
                label: const Text('Add Page Count'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reading Progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_currentBook.progressPercentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.infoColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress slider
            Slider(
              value: _currentBook.currentPage.toDouble(),
              min: 0,
              max: _currentBook.totalPages.toDouble(),
              divisions: _currentBook.totalPages > 100
                  ? 100
                  : _currentBook.totalPages,
              onChanged: (value) {
                setState(() {
                  _currentBook = _currentBook.copyWith(
                    currentPage: value.round(),
                  );
                  _pageController.text = value.round().toString();
                });
              },
              onChangeEnd: (value) {
                _updateProgress(value.round());
              },
            ),
            const SizedBox(height: 8),
            // Page counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Page',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _pageController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          final page = int.tryParse(value) ?? 0;
                          _updateProgress(page);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '/ ${_currentBook.totalPages}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressBar(
              progress: _currentBook.progressPercentage / 100,
              height: 12,
              showPercentage: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingStats(BuildContext context) {
    return ReadingSpeedIndicator(
      pagesPerDay: _currentBook.pagesPerDay,
      daysRemaining: _currentBook.daysRemaining,
      estimatedFinishDate: _currentBook.estimatedFinishDate,
    );
  }

  Widget _buildDescription(BuildContext context) {
    if (_currentBook.description == null ||
        _currentBook.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _currentBook.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              if (_currentBook.isbn != null)
                _buildInfoRow(context, 'ISBN', _currentBook.isbn!),
              if (_currentBook.publisher != null)
                _buildInfoRow(context, 'Publisher', _currentBook.publisher!),
              if (_currentBook.publishedDate != null)
                _buildInfoRow(
                    context, 'Published', _currentBook.publishedDate!),
              _buildInfoRow(
                  context, 'Total Pages', '${_currentBook.totalPages}'),
              if (_currentBook.startDate != null)
                _buildInfoRow(
                  context,
                  'Started Reading',
                  _formatDate(_currentBook.startDate!),
                ),
              if (_currentBook.isFinished && _currentBook.updatedAt != null)
                _buildInfoRow(
                  context,
                  'Finished',
                  _formatDate(_currentBook.updatedAt!),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade400,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (_currentBook.isToRead) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startReading(),
              icon: const Icon(Icons.auto_stories),
              label: const Text('Start Reading'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
        if (_currentBook.isReading && _currentBook.currentPage > 0) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _markAsFinished(),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark Finished'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_currentBook.isFinished) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _readAgain(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Read Again'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "${_currentBook.title}" from your library?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BookCubit>().deleteBook(_currentBook.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _updateProgress(int currentPage) {
    if (_currentBook.id == null) return;

    final clampedPage = currentPage.clamp(0, _currentBook.totalPages);
    _pageController.text = clampedPage.toString();

    context.read<BookCubit>().updateProgress(
          bookId: _currentBook.id!,
          currentPage: clampedPage,
        );
  }

  void _startReading() {
    if (_currentBook.id == null) return;
    context.read<BookCubit>().startReading(_currentBook.id!);
  }

  void _markAsFinished() {
    if (_currentBook.id == null) return;
    context.read<BookCubit>().finishBook(_currentBook.id!);
  }

  void _readAgain() {
    if (_currentBook.id == null) return;
    context.read<BookCubit>().updateProgress(
          bookId: _currentBook.id!,
          currentPage: 0,
          status: AppConstants.statusToRead,
        );
  }

  void _showEditPagesDialog() {
    final controller = TextEditingController(
      text: _currentBook.totalPages.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Page Count'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total Pages',
            hintText: 'e.g., 320',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pages = int.tryParse(controller.text) ?? 0;
              if (pages > 0) {
                Navigator.pop(context);
                final updatedBook = _currentBook.copyWith(totalPages: pages);
                context.read<BookCubit>().updateBook(updatedBook);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
