import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../logic/cubits/book_cubit.dart';
import '../../logic/states/book_state.dart';

/// Barcode scanner screen for ISBN scanning
class ScannerScreen extends StatefulWidget {
  static const String name = 'ScannerScreen';

  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  bool _isScanning = true;
  bool _hasScanned = false;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan ISBN Barcode'),
        actions: [
          IconButton(
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: BlocConsumer<BookCubit, BookState>(
        listener: (context, state) {
          if (state is BookFoundByIsbn) {
            _showBookFoundDialog(state.book);
          }
          if (state is BookNotFoundByIsbn) {
            _showNotFoundDialog(state.isbn);
          }
          if (state is BookOperationSuccess) {
            Navigator.pop(context, true);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Scanner view
              MobileScanner(
                controller: _controller!,
                onDetect: _onBarcodeDetected,
              ),
              // Scanner overlay
              _buildScannerOverlay(),
              // Loading indicator
              if (state is IsbnScanning)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Looking up book...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.7;
        final top = (constraints.maxHeight - scanAreaSize) / 2;
        final left = (constraints.maxWidth - scanAreaSize) / 2;

        return Stack(
          children: [
            // Darkened background
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    top: top,
                    left: left,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scan area border
            Positioned(
              top: top,
              left: left,
              child: Container(
                width: scanAreaSize,
                height: scanAreaSize,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.infoColor, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Corner markers
            Positioned(
              top: top,
              left: left,
              child: _buildCornerMarkers(scanAreaSize),
            ),
            // Instructions
            Positioned(
              bottom: constraints.maxHeight * 0.2,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 48,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Position the ISBN barcode within the frame',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The scanner will automatically detect the barcode',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCornerMarkers(double size) {
    const markerSize = 24.0;
    const markerWidth = 3.0;
    final color = AppTheme.infoColor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Top left
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: markerSize,
              height: markerSize,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: markerWidth),
                  left: BorderSide(color: color, width: markerWidth),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                ),
              ),
            ),
          ),
          // Top right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: markerSize,
              height: markerSize,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: markerWidth),
                  right: BorderSide(color: color, width: markerWidth),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                ),
              ),
            ),
          ),
          // Bottom left
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: markerSize,
              height: markerSize,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: markerWidth),
                  left: BorderSide(color: color, width: markerWidth),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),
          // Bottom right
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: markerSize,
              height: markerSize,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: markerWidth),
                  right: BorderSide(color: color, width: markerWidth),
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final value = barcode.rawValue;
      if (value != null && _isValidIsbn(value)) {
        _hasScanned = true;
        _controller?.stop();
        context.read<BookCubit>().fetchBookByIsbn(value);
        break;
      }
    }
  }

  bool _isValidIsbn(String value) {
    // Remove any hyphens or spaces
    final cleanValue = value.replaceAll(RegExp(r'[-\s]'), '');
    // Check if it's a valid ISBN (10 or 13 digits)
    return RegExp(r'^\d{10}(\d{3})?$').hasMatch(cleanValue);
  }

  void _toggleTorch() {
    _controller?.toggleTorch();
    setState(() => _torchEnabled = !_torchEnabled);
  }

  void _showBookFoundDialog(BookModel book) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor),
            const SizedBox(width: 8),
            const Text('Book Found!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'by ${book.author}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade400,
                    ),
              ),
              if (book.publisher != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Publisher: ${book.publisher}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (book.totalPages > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Pages: ${book.totalPages}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Scan Another'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _addBookToLibrary(book);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add to Library'),
          ),
        ],
      ),
    );
  }

  void _showNotFoundDialog(String isbn) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.warningColor),
            const SizedBox(width: 8),
            const Text('Book Not Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Could not find book information for ISBN:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isbn,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can add this book manually or try scanning again.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade400,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Scan Again'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // Navigate to manual entry with ISBN pre-filled
              // This would need to be implemented with route arguments
            },
            icon: const Icon(Icons.edit),
            label: const Text('Add Manually'),
          ),
        ],
      ),
    );
  }

  Future<void> _addBookToLibrary(BookModel book) async {
    // Check if already exists
    if (book.isbn != null) {
      final exists = await context.read<BookCubit>().isIsbnExists(book.isbn!);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This book is already in your library')),
        );
        Navigator.pop(context);
        return;
      }
    }

    // If book has no page count, show dialog to enter it
    if (book.totalPages <= 0) {
      _showPageCountDialog(book);
    } else {
      context.read<BookCubit>().addBook(book);
    }
  }

  void _showPageCountDialog(BookModel book) {
    final pagesController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Page Count'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter the total number of pages for "${book.title}"',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pages = int.tryParse(pagesController.text) ?? 0;
              if (pages > 0) {
                Navigator.pop(context);
                final updatedBook = book.copyWith(totalPages: pages);
                context.read<BookCubit>().addBook(updatedBook);
              }
            },
            child: const Text('Add Book'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _isScanning = true;
    });
    _controller?.start();
  }
}
