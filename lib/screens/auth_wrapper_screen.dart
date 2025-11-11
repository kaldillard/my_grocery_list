// lib/screens/auth_wrapper_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/auth/auth_state.dart';
import 'package:my_grocery_list/blocs/family/family_event.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/screens/family_setup_screen.dart';
import 'package:my_grocery_list/screens/login_screen.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/grocery/grocery_bloc.dart';
import '../blocs/family/family_bloc.dart';
import '../services/supabase_service.dart';
import 'grocery_list_screen.dart';

/// Wrapper screen that decides which screen to show based on auth state
class AuthWrapperScreen extends StatelessWidget {
  const AuthWrapperScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Show loading while checking auth
        if (authState is AuthInitial || authState is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show login if not authenticated
        if (authState is AuthUnauthenticated || authState is AuthError) {
          return const LoginScreen();
        }

        // User is authenticated, check if they have a family
        if (authState is AuthAuthenticated) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _checkUserFamily(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // No family - show family setup
              if (snapshot.data == null) {
                return const FamilySetupScreen();
              }

              // Has family - show grocery list with proper BLoCs
              final familyId = snapshot.data!['family_id'] as String;
              return _buildGroceryListWithBLoCs(context, familyId);
            },
          );
        }

        // Fallback
        return const LoginScreen();
      },
    );
  }

  /// Check if current user belongs to a family
  Future<Map<String, dynamic>?> _checkUserFamily(BuildContext context) async {
    final supabaseService = context.read<SupabaseService>();
    try {
      // Get user's family membership
      final families =
          await supabaseService.getFamilyMembershipForCurrentUser();

      return families;
    } catch (e) {
      return null;
    }
  }

  /// Build the grocery list screen with the necessary BLoCs
  Widget _buildGroceryListWithBLoCs(BuildContext context, String familyId) {
    final supabaseService = context.read<SupabaseService>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (context) => FamilyBloc(
                supabaseService: supabaseService,
                familyId: familyId,
              )..add(LoadFamilyData()),
        ),
        BlocProvider(
          create:
              (context) => GroceryBloc(
                supabaseService: supabaseService,
                familyId: familyId,
              )..add(LoadGroceryData()),
        ),
      ],
      child: const GroceryListScreen(),
    );
  }
}
