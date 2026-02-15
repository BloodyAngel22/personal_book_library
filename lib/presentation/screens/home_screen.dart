import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/cubits/book_cubit.dart';
import '../../logic/states/book_state.dart';
import '../../data/models/book_model.dart';
import '../widgets/book_card_widget.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/shimmer_loading.dart';
import 'local_search_screen.dart';
import 'online_search_screen.dart';
import 'manual_entry_screen.dart';
import 'scanner_screen.dart';

/// Home screen with tabs for different book lists
class HomeScreen extends StatefulWidget {
  static const String name = 'HomeScreen';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    // Load books on init
    context.read<BookCubit>().loadBooks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh books when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      context.read<BookCubit>().loadBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        actions: [
          // Search button - searches LOCAL library
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search your library',
            onPressed: () => _navigateToLocalSearch(context),
          ),
          // Add button - shows menu to add books
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add book',
            onPressed: () => _showAddBookMenu(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'To Read'),
            Tab(text: 'Reading'),
            Tab(text: 'Finished'),
          ],
        ),
      ),
      body: BlocConsumer<BookCubit, BookState>(
        listener: (context, state) {
          // Handle operation success messages
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
          // Show loading only on initial load
          if (state is BookLoading) {
            return const ShimmerBookList();
          }

          if (state is BookError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<BookCubit>().loadBooks(),
            );
          }

          // Show books list for BooksLoaded state
          if (state is BooksLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildBookList(state.toReadBooks, 'No books to read'),
                _buildBookList(state.readingBooks, 'No books in progress'),
                _buildBookList(state.finishedBooks, 'No finished books'),
              ],
            );
          }

          // For other states (like BookDetailLoaded, BookOperationSuccess),
          // try to show the cached books from the cubit
          final lastState = context.read<BookCubit>().lastLoadedState;
          if (lastState != null) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildBookList(lastState.toReadBooks, 'No books to read'),
                _buildBookList(lastState.readingBooks, 'No books in progress'),
                _buildBookList(lastState.finishedBooks, 'No finished books'),
              ],
            );
          }

          return const EmptyStateWidget(
            title: 'Your library is empty',
            subtitle: 'Add books to get started',
          );
        },
      ),
    );
  }

  Widget _buildBookList(List<BookModel> books, String emptyMessage) {
    if (books.isEmpty) {
      return EmptyStateWidget(
        title: emptyMessage,
        subtitle: 'Tap + to add a book',
        icon: Icons.book_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<BookCubit>().loadBooks();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return BookCard(book: book);
        },
      ),
    );
  }

  /// Navigate to local library search (from magnifying glass)
  void _navigateToLocalSearch(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocalSearchScreen()),
    );
    // Refresh books when returning from search
    if (mounted) {
      context.read<BookCubit>().loadBooks();
    }
  }

  /// Show bottom sheet menu for adding books
  void _showAddBookMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Book',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to add a book',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade400,
                  ),
            ),
            const SizedBox(height: 24),
            
            // Search Online option
            _buildMenuOption(
              icon: Icons.travel_explore,
              title: 'Search Online',
              subtitle: 'Find books by title, author, or ISBN',
              onTap: () => _navigateToOnlineSearch(context),
            ),
            
            const Divider(height: 1, indent: 72),
            
            // Scan Barcode option
            _buildMenuOption(
              icon: Icons.qr_code_scanner,
              title: 'Scan Barcode',
              subtitle: 'Scan book ISBN with camera',
              onTap: () => _navigateToScanner(context),
            ),
            
            const Divider(height: 1, indent: 72),
            
            // Manual Entry option
            _buildMenuOption(
              icon: Icons.edit,
              title: 'Manual Entry',
              subtitle: 'Enter book details yourself',
              onTap: () => _navigateToManualEntry(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.infoColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.infoColor),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade500),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  /// Navigate to online search (for adding books)
  void _navigateToOnlineSearch(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OnlineSearchScreen()),
    );
    // Refresh books when returning
    if (mounted) {
      context.read<BookCubit>().loadBooks();
    }
  }

  /// Navigate to manual entry
  void _navigateToManualEntry(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManualEntryScreen()),
    );
    // Refresh books when returning
    if (mounted) {
      context.read<BookCubit>().loadBooks();
    }
  }

  /// Navigate to barcode scanner
  void _navigateToScanner(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
    // Refresh books when returning
    if (mounted) {
      context.read<BookCubit>().loadBooks();
    }
  }
}
