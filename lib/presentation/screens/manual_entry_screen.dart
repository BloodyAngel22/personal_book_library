import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../logic/cubits/book_cubit.dart';
import '../../logic/states/book_state.dart';

/// Manual book entry screen
class ManualEntryScreen extends StatefulWidget {
  static const String name = 'ManualEntryScreen';

  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _isbnController = TextEditingController();
  final _publisherController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    _descriptionController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Book Manually'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveBook,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: BlocListener<BookCubit, BookState>(
        listener: (context, state) {
          if (state is BookOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context, true);
          }
          if (state is BookError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Required fields header
                Text(
                  'Required Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.infoColor,
                      ),
                ),
                const SizedBox(height: 16),

                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Book Title *',
                    hintText: 'Enter the book title',
                    prefixIcon: Icon(Icons.book),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a book title';
                    }
                    if (value.length < AppConstants.minBookTitleLength) {
                      return 'Title is too short';
                    }
                    if (value.length > AppConstants.maxBookTitleLength) {
                      return 'Title is too long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Author field
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Author *',
                    hintText: 'Enter the author name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an author name';
                    }
                    if (value.length > AppConstants.maxAuthorLength) {
                      return 'Author name is too long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Pages field
                TextFormField(
                  controller: _pagesController,
                  decoration: const InputDecoration(
                    labelText: 'Total Pages *',
                    hintText: 'Enter the total number of pages',
                    prefixIcon: Icon(Icons.menu_book),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the total pages';
                    }
                    final pages = int.tryParse(value);
                    if (pages == null) {
                      return 'Please enter a valid number';
                    }
                    if (pages < AppConstants.minPages) {
                      return 'Pages must be at least ${AppConstants.minPages}';
                    }
                    if (pages > AppConstants.maxPages) {
                      return 'Pages cannot exceed ${AppConstants.maxPages}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Optional fields header
                Text(
                  'Optional Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                ),
                const SizedBox(height: 16),

                // ISBN field
                TextFormField(
                  controller: _isbnController,
                  decoration: const InputDecoration(
                    labelText: 'ISBN',
                    hintText: 'Enter ISBN-10 or ISBN-13',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final cleanIsbn = value.replaceAll(RegExp(r'[-\s]'), '');
                      if (!RegExp(r'^\d{10}(\d{3})?$').hasMatch(cleanIsbn)) {
                        return 'Please enter a valid ISBN (10 or 13 digits)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Publisher field
                TextFormField(
                  controller: _publisherController,
                  decoration: const InputDecoration(
                    labelText: 'Publisher',
                    hintText: 'Enter the publisher name',
                    prefixIcon: Icon(Icons.business),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter a brief description or notes',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value != null &&
                        value.length > AppConstants.maxDescriptionLength) {
                      return 'Description is too long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Help text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.infoColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.infoColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Fields marked with * are required. You can edit these details later.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.infoColor,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveBook,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Saving...' : 'Add to Library'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final book = BookModel(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      totalPages: int.parse(_pagesController.text),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      isbn: _isbnController.text.trim().isNotEmpty
          ? _isbnController.text.trim().replaceAll(RegExp(r'[-\s]'), '')
          : null,
      publisher: _publisherController.text.trim().isNotEmpty
          ? _publisherController.text.trim()
          : null,
      status: AppConstants.statusToRead,
    );

    // Check if ISBN already exists
    if (book.isbn != null && book.isbn!.isNotEmpty) {
      final exists = await context.read<BookCubit>().isIsbnExists(book.isbn!);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A book with this ISBN already exists in your library'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
    }

    context.read<BookCubit>().addBook(book);
  }
}
