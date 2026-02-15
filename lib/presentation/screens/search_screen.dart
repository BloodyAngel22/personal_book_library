import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../logic/cubits/book_cubit.dart';
import '../../logic/states/book_state.dart';
import '../widgets/book_card_widget.dart';
import '../widgets/shimmer_loading.dart';
import 'scanner_screen.dart';

/// Search screen for finding books online and locally
class SearchScreen extends StatefulWidget {
  static const String name = 'SearchScreen';

  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Set<String> _addedIsbns = {};

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
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
            hintText: 'Search books by title, author, or ISBN...',
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
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is BookFoundByIsbn) {
            _showIsbnBookDialog(state.book);
          }
          if (state is BookNotFoundByIsbn) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Book not found for ISBN: ${state.isbn}')),
            );
          }
        },
        builder: (context, state) {
          if (state is BookLoading || state is IsbnScanning) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SearchResultsLoaded) {
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
              Icons.search,
              size: 80,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 24),
            Text(
              'Search for Books',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a book title, author name, or ISBN to search',
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

  Widget _buildSearchResults(SearchResultsLoaded state) {
    if (!state.hasResults) {
      return EmptyStateWidget(
        title: 'No results found',
        subtitle: 'Try a different search term',
        icon: Icons.search_off,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Local results section
          if (state.localResults.isNotEmpty) ...[
            _buildSectionHeader('In Your Library', state.localResults.length),
            ...state.localResults.map((book) => BookCard(book: book)),
          ],
          // Online results section
          if (state.onlineResults.isNotEmpty) ...[
            _buildSectionHeader('Online Results', state.onlineResults.length),
            ...state.onlineResults.map((book) => _buildOnlineResultCard(book)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.infoColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineResultCard(BookModel book) {
    final isAdded = _addedIsbns.contains(book.isbn);

    return SearchResultCard(
      book: book,
      isAdded: isAdded,
      onAdd: isAdded
          ? null
          : () => _addBookToLibrary(book),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);
    context.read<BookCubit>().searchOnline(query);
  }

  void _clearSearch() {
    _searchController.clear();
    _addedIsbns.clear();
    context.read<BookCubit>().clearSearch();
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
      context.read<BookCubit>().addBook(book);
      if (book.isbn != null) {
        setState(() => _addedIsbns.add(book.isbn!));
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
            onPressed: () {
              final pages = int.tryParse(pagesController.text) ?? 0;
              if (pages > 0) {
                Navigator.pop(context);
                final updatedBook = book.copyWith(totalPages: pages);
                context.read<BookCubit>().addBook(updatedBook);
                if (book.isbn != null) {
                  setState(() => _addedIsbns.add(book.isbn!));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showIsbnBookDialog(BookModel book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Found!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              book.author,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (book.totalPages > 0) ...[
              const SizedBox(height: 8),
              Text('${book.totalPages} pages'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addBookToLibrary(book);
            },
            child: const Text('Add to Library'),
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
