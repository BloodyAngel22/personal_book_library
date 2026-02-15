import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/cubits/book_cubit.dart';
import '../../logic/states/book_state.dart';
import '../../data/models/book_model.dart';
import '../widgets/book_card_widget.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/shimmer_loading.dart';
import 'search_screen.dart';
import 'manual_entry_screen.dart';

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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _navigateToSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToManualEntry(context),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToSearch(context),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan ISBN'),
      ),
    );
  }

  Widget _buildBookList(List<BookModel> books, String emptyMessage) {
    if (books.isEmpty) {
      return EmptyStateWidget(
        title: emptyMessage,
        subtitle: 'Tap + to add a book manually or scan a barcode',
        icon: Icons.book_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<BookCubit>().loadBooks();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return BookCard(book: book);
        },
      ),
    );
  }

  void _navigateToSearch(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
    // Refresh books when returning from search (in case books were added)
    if (mounted) {
      context.read<BookCubit>().loadBooks();
    }
  }

  void _navigateToManualEntry(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManualEntryScreen()),
    );
    // Refresh books when returning from manual entry (in case a book was added)
    if (mounted) {
      context.read<BookCubit>().loadBooks();
    }
  }
}
