// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/auth/auth_event.dart';
import 'package:my_grocery_list/blocs/subscription/subscription_bloc.dart';
import 'package:my_grocery_list/blocs/subscription/subscription_event.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/family_setup/family_setup_bloc.dart';
import 'services/supabase_service.dart';
import 'screens/auth_wrapper_screen.dart';
import 'utils/constants.dart';

/// The root widget of the application
/// Sets up BLoC providers, theme, and routing
class MyApp extends StatelessWidget {
  final SupabaseService supabaseService;

  const MyApp({Key? key, required this.supabaseService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: supabaseService,
      child: MultiBlocProvider(
        providers: [
          // Auth BLoC - available app-wide
          BlocProvider(
            create:
                (context) =>
                    AuthBloc(supabaseService: supabaseService)
                      ..add(AuthCheckRequested()),
          ),
          // Family Setup BLoC - for onboarding
          BlocProvider(
            create:
                (context) => FamilySetupBloc(supabaseService: supabaseService),
          ),
          // Subscription BLoC - for managing subscription state
          BlocProvider(
            create:
                (context) =>
                    SubscriptionBloc(supabaseService: supabaseService)
                      ..add(LoadSubscription()),
          ),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          home: const AppLifecycleWrapper(child: AuthWrapperScreen()),
        ),
      ),
    );
  }

  /// Builds the app theme
  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.green,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// Wrapper to detect when app comes to foreground
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - refresh subscription
      print('App resumed - refreshing subscription');
      context.read<SubscriptionBloc>().add(RefreshSubscription());
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
