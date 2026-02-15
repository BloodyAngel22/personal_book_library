// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

part of 'app_router.dart';

class _$AppRouter extends AppRouter {
  _$AppRouter();

  @override
  final Map<String, PageFactory> pagesMap = {
    HomeScreen.name: (RouteData data) {
      return MaterialPageX(
        routeData: data,
        child: const HomeScreen(),
      );
    },
    SearchScreen.name: (RouteData data) {
      return MaterialPageX(
        routeData: data,
        child: const SearchScreen(),
      );
    },
    BookDetailScreen.name: (RouteData data) {
      final args = data.argsAs<BookDetailArgs>();
      return MaterialPageX(
        routeData: data,
        child: BookDetailScreen(book: args.book),
      );
    },
    ManualEntryScreen.name: (RouteData data) {
      return MaterialPageX(
        routeData: data,
        child: const ManualEntryScreen(),
      );
    },
    ScannerScreen.name: (RouteData data) {
      return MaterialPageX(
        routeData: data,
        child: const ScannerScreen(),
      );
    },
  };
}

/// Extended PageRouteInfo for BookDetailScreen
class BookDetailRoute extends PageRouteInfo<BookDetailArgs> {
  BookDetailRoute({required BookDetailArgs args})
      : super(
          BookDetailScreen.name,
          args: args,
          path: '/book-detail',
        );
}

/// Extended PageRouteInfo for HomeScreen
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute()
      : super(
          HomeScreen.name,
          path: '/',
        );
}

/// Extended PageRouteInfo for SearchScreen
class SearchRoute extends PageRouteInfo<void> {
  const SearchRoute()
      : super(
          SearchScreen.name,
          path: '/search',
        );
}

/// Extended PageRouteInfo for ManualEntryScreen
class ManualEntryRoute extends PageRouteInfo<void> {
  const ManualEntryRoute()
      : super(
          ManualEntryScreen.name,
          path: '/manual-entry',
        );
}

/// Extended PageRouteInfo for ScannerScreen
class ScannerRoute extends PageRouteInfo<void> {
  const ScannerRoute()
      : super(
          ScannerScreen.name,
          path: '/scanner',
        );
}
