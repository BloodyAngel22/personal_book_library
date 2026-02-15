import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'logic/cubits/book_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PersonalBookLibraryApp());
}

/// Main application widget
class PersonalBookLibraryApp extends StatelessWidget {
  const PersonalBookLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BookCubit>(
          create: (context) => BookCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'Personal Book Library',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
