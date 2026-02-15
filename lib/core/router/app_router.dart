import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/search_screen.dart';
import '../../presentation/screens/book_detail_screen.dart';
import '../../presentation/screens/manual_entry_screen.dart';
import '../../presentation/screens/scanner_screen.dart';
import '../../data/models/book_model.dart';

part 'app_router.gr.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Screen,Route',
  routes: <AutoRoute>[
    AutoRoute(
      page: HomeScreen,
      path: '/',
      initial: true,
    ),
    AutoRoute(
      page: SearchScreen,
      path: '/search',
    ),
    AutoRoute(
      page: BookDetailScreen,
      path: '/book-detail',
    ),
    AutoRoute(
      page: ManualEntryScreen,
      path: '/manual-entry',
    ),
    AutoRoute(
      page: ScannerScreen,
      path: '/scanner',
    ),
  ],
)
class AppRouter extends _$AppRouter {}

/// Route arguments for type-safe navigation
class BookDetailArgs {
  final BookModel book;

  const BookDetailArgs({required this.book});
}
