import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../logic/cubits/book_cubit.dart';
import '../../logic/states/book_state.dart';
import '../widgets/book_card_widget.dart';
import '../widgets/progress_indicator_widget.dart';
import 'scanner_screen.dart';

/// Online search screen for adding new books to the library
class OnlineSearchScreen extends StatefulWidget {
  static const String name = 'OnlineSearchScreen';

  const OnlineSearchScreen({super.key});

  @override
  State<OnlineSearchScreen> createState() => _OnlineSearchScreenState();
}

class _OnlineSearchScreenState extends State<OnlineSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    // Clear any previous online search results
    context.read<BookCubit>().clearOnlineSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search for books to add...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade500),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: _performSearch,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSearch,
          ),
        ],
      ),
      body: BlocConsumer<BookCubit, BookState>(
        listener: (context, state) {
          if (state is BookOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BookLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OnlineSearchResultsLoaded) {
            return _buildSearchResults(state);
          }

          if (state is BookError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => _performSearch(_searchController.text),
            );
          }

          return _buildInitialContent();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToScanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan ISBN'),
      ),
    );
  }

  Widget _buildInitialContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore,
              size: 80,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 24),
            Text(
              'Find Books to Add',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Search by title, author, or ISBN to find books online',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade400,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Quick actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(
                  'Search Online',
                  Icons.travel_explore,
                  () => _performSearch(_searchController.text),
                ),
                _buildQuickAction(
                  'Scan Barcode',
                  Icons.qr_code_scanner,
                  _navigateToScanner,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade700),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.infoColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(OnlineSearchResultsLoaded state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching...'),
          ],
        ),
      );
    }

    if (!state.hasResults) {
      return EmptyStateWidget(
        title: 'No books found',
        subtitle: 'Try a different search term',
        icon: Icons.search_off,
      );
    }

    return Column(
      children: [
        // Results count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade900,
          child: Text(
            '${state.results.length} result${state.results.length == 1 ? '' : 's'} found',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade400,
                ),
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final book = state.results[index];
              final isAdded = state.addedIsbns.contains(book.isbn);
              return _buildOnlineResultCard(book, isAdded);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineResultCard(BookModel book, bool isAdded) {
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
                  ? Image.network(
                      book.thumbnailUrl!,
                      width: 50,
                      height: 75,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
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
            IconButton(
              icon: Icon(
                isAdded ? Icons.check : Icons.add_circle_outline,
                color: isAdded ? AppTheme.successColor : AppTheme.infoColor,
              ),
              onPressed: isAdded ? null : () => _addBookToLibrary(book),
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

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);
    context.read<BookCubit>().searchOnline(query).then((_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<BookCubit>().clearOnlineSearch();
  }

  Future<void> _addBookToLibrary(BookModel book) async {
    // Check if already exists
    if (book.isbn != null) {
      final exists = await context.read<BookCubit>().isIsbnExists(book.isbn!);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This book is already in your library')),
        );
        return;
      }
    }

    // If book has no page count, show dialog to enter it
    if (book.totalPages <= 0) {
      _showPageCountDialog(book);
    } else {
      await context.read<BookCubit>().addBook(book);
      // Mark as added in search results
      if (book.isbn != null) {
        context.read<BookCubit>().markBookAsAdded(book.isbn!);
      }
    }
  }

  void _showPageCountDialog(BookModel book) {
    final pagesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Page Count'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please enter the total number of pages for "${book.title}"'),
            const SizedBox(height: 16),
            TextField(
              controller: pagesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Pages',
                hintText: 'e.g., 320',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pages = int.tryParse(pagesController.text) ?? 0;
              if (pages > 0) {
                Navigator.pop(context);
                final updatedBook = book.copyWith(totalPages: pages);
                await context.read<BookCubit>().addBook(updatedBook);
                // Mark as added in search results
                if (book.isbn != null) {
                  context.read<BookCubit>().markBookAsAdded(book.isbn!);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _navigateToScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScannerScreen(),
      ),
    );
  }
}
