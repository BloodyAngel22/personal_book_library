import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../logic/cubits/book_cubit.dart';
import '../../logic/states/book_state.dart';
import '../widgets/book_card_widget.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/shimmer_loading.dart';

/// Local library search screen with filters
class LocalSearchScreen extends StatefulWidget {
  static const String name = 'LocalSearchScreen';

  const LocalSearchScreen({super.key});

  @override
  State<LocalSearchScreen> createState() => _LocalSearchScreenState();
}

class _LocalSearchScreenState extends State<LocalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  LocalSearchFilters _filters = const LocalSearchFilters();
  bool _showFilters = false;
  List<String> _availableAuthors = [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _loadAuthors();
    // Perform initial search to show all books
    context.read<BookCubit>().searchLocalLibrary(filters: _filters);
  }

  Future<void> _loadAuthors() async {
    final authors = await context.read<BookCubit>().getAuthors();
    if (mounted) {
      setState(() => _availableAuthors = authors);
    }
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
            hintText: 'Search your library...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade500),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSearch,
          ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
            ),
            onPressed: _toggleFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter panel
          if (_showFilters) _buildFilterPanel(),
          
          // Results
          Expanded(
            child: BlocBuilder<BookCubit, BookState>(
              builder: (context, state) {
                if (state is BookLoading) {
                  return const ShimmerBookList();
                }

                if (state is LocalSearchResultsLoaded) {
                  return _buildResults(state);
                }

                if (state is BookError) {
                  return ErrorStateWidget(
                    message: state.message,
                    onRetry: () => _performSearch(),
                  );
                }

                return const EmptyStateWidget(
                  title: 'Search your library',
                  subtitle: 'Enter a title, author, or ISBN to search',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filters
          Text(
            'Filter by Status',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(AppConstants.statusToRead, 'To Read', Colors.grey),
              _buildStatusChip(AppConstants.statusReading, 'Reading', AppTheme.infoColor),
              _buildStatusChip(AppConstants.statusFinished, 'Finished', AppTheme.successColor),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Author filter
          Text(
            'Filter by Author',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _filters.author,
            decoration: InputDecoration(
              hintText: 'All Authors',
              filled: true,
              fillColor: Colors.grey.shade800,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            dropdownColor: Colors.grey.shade800,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Authors')),
              ..._availableAuthors.map((author) => DropdownMenuItem(
                value: author,
                child: Text(
                  author,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(
                  author: value,
                  clearAuthor: value == null,
                );
              });
              _performSearch();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Sort options
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sort by',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SortOption>(
                      value: _filters.sortBy,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      dropdownColor: Colors.grey.shade800,
                      items: const [
                        DropdownMenuItem(value: SortOption.updatedAt, child: Text('Recently Updated')),
                        DropdownMenuItem(value: SortOption.title, child: Text('Title')),
                        DropdownMenuItem(value: SortOption.author, child: Text('Author')),
                        DropdownMenuItem(value: SortOption.progress, child: Text('Progress')),
                        DropdownMenuItem(value: SortOption.startDate, child: Text('Start Date')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _filters = _filters.copyWith(sortBy: value);
                          });
                          _performSearch();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  _filters.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                onPressed: () {
                  setState(() {
                    _filters = _filters.copyWith(
                      sortAscending: !_filters.sortAscending,
                    );
                  });
                  _performSearch();
                },
                tooltip: _filters.sortAscending ? 'Ascending' : 'Descending',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Has progress filter
          Row(
            children: [
              Checkbox(
                value: _filters.hasProgress,
                onChanged: (value) {
                  setState(() {
                    _filters = _filters.copyWith(hasProgress: value ?? false);
                  });
                  _performSearch();
                },
              ),
              const Text('Only show books with progress'),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Reset filters button
          if (_filters.hasActiveFilters)
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Reset Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label, Color color) {
    final isSelected = _filters.statuses.contains(status);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          final newStatuses = Set<String>.from(_filters.statuses);
          if (selected) {
            newStatuses.add(status);
          } else {
            newStatuses.remove(status);
          }
          _filters = _filters.copyWith(statuses: newStatuses);
        });
        _performSearch();
      },
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade400,
      ),
    );
  }

  Widget _buildResults(LocalSearchResultsLoaded state) {
    if (!state.hasResults) {
      return EmptyStateWidget(
        title: 'No books found',
        subtitle: _searchController.text.isEmpty && !_filters.hasActiveFilters
            ? 'Your library is empty'
            : 'Try different search terms or filters',
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
            '${state.totalMatches} book${state.totalMatches == 1 ? '' : 's'} found',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade400,
                ),
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final book = state.results[index];
              return BookCard(book: book);
            },
          ),
        ),
      ],
    );
  }

  void _onSearchChanged(String query) {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text == query) {
        _performSearch();
      }
    });
  }

  void _performSearch() {
    context.read<BookCubit>().searchLocalLibrary(
      query: _searchController.text,
      filters: _filters,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch();
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
  }

  void _resetFilters() {
    setState(() {
      _filters = const LocalSearchFilters();
    });
    _performSearch();
  }
}
