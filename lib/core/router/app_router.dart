import 'package:flutter/material.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/local_search_screen.dart';
import '../../presentation/screens/online_search_screen.dart';
import '../../presentation/screens/book_detail_screen.dart';
import '../../presentation/screens/manual_entry_screen.dart';
import '../../presentation/screens/scanner_screen.dart';
import '../../data/models/book_model.dart';

/// Simple router configuration without code generation
class AppRouter {
  /// Generate routes for the app
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case '/local-search':
        return MaterialPageRoute(
          builder: (_) => const LocalSearchScreen(),
          settings: settings,
        );
      case '/online-search':
        return MaterialPageRoute(
          builder: (_) => const OnlineSearchScreen(),
          settings: settings,
        );
      case '/book-detail':
        final args = settings.arguments as BookDetailArgs?;
        if (args == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Error: Book not provided')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => BookDetailScreen(book: args.book),
          settings: settings,
        );
      case '/manual-entry':
        return MaterialPageRoute(
          builder: (_) => const ManualEntryScreen(),
          settings: settings,
        );
      case '/scanner':
        return MaterialPageRoute(
          builder: (_) => const ScannerScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Error: Page not found')),
          ),
        );
    }
  }
}

/// Route arguments for book detail screen
class BookDetailArgs {
  final BookModel book;

  const BookDetailArgs({required this.book});
}

/// Navigation helper class
class AppNavigator {
  /// Navigate to local search screen (search library)
  static void toLocalSearch(BuildContext context) {
    Navigator.pushNamed(context, '/local-search');
  }

  /// Navigate to online search screen (add books)
  static void toOnlineSearch(BuildContext context) {
    Navigator.pushNamed(context, '/online-search');
  }

  /// Navigate to book detail screen
  static void toBookDetail(BuildContext context, BookModel book) {
    Navigator.pushNamed(
      context,
      '/book-detail',
      arguments: BookDetailArgs(book: book),
    );
  }

  /// Navigate to manual entry screen
  static void toManualEntry(BuildContext context) {
    Navigator.pushNamed(context, '/manual-entry');
  }

  /// Navigate to scanner screen
  static void toScanner(BuildContext context) {
    Navigator.pushNamed(context, '/scanner');
  }

  /// Go back
  static void pop(BuildContext context, [Object? result]) {
    Navigator.pop(context, result);
  }
}
