// lib/screens/auth_wrapper_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/auth/auth_state.dart';
import 'package:my_grocery_list/screens/family_list_screen.dart';
import 'package:my_grocery_list/screens/login_screen.dart';
import 'package:my_grocery_list/screens/list_selection_screen.dart';
import '../blocs/auth/auth_bloc.dart';
import '../services/supabase_service.dart';

/// Wrapper screen that decides which screen to show based on auth state
class AuthWrapperScreen extends StatefulWidget {
  const AuthWrapperScreen({Key? key}) : super(key: key);

  @override
  State<AuthWrapperScreen> createState() => _AuthWrapperScreenState();
}

class _AuthWrapperScreenState extends State<AuthWrapperScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        print('AuthWrapperScreen - Auth state: ${authState.runtimeType}');

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
          return _FamilyCheckWidget(user: authState.user);
        }

        // Fallback
        return const LoginScreen();
      },
    );
  }
}

/// Separate widget that rebuilds when needed
class _FamilyCheckWidget extends StatefulWidget {
  final user;

  const _FamilyCheckWidget({required this.user});

  @override
  State<_FamilyCheckWidget> createState() => _FamilyCheckWidgetState();
}

class _FamilyCheckWidgetState extends State<_FamilyCheckWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      // Add a key to force rebuild - use timestamp or user id
      key: ValueKey('family_check_${DateTime.now().millisecondsSinceEpoch}'),
      future: _checkUserFamily(context),
      builder: (context, snapshot) {
        print('Family check state: ${snapshot.connectionState}');
        print('Family data: ${snapshot.data}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('Error checking family: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Force rebuild
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // No family selected - show family list screen
        if (snapshot.data == null || snapshot.data!['family_id'] == null) {
          print('No family selected - showing family list');
          return const FamilyListScreen();
        }

        // Has family - show list selection screen for that family
        final familyId = snapshot.data!['family_id'] as String;
        final familyName = snapshot.data!['family_name'] as String;
        print('Family found: $familyId - showing list selection');

        return ListSelectionScreen(familyId: familyId, familyName: familyName);
      },
    );
  }

  /// Check if current user belongs to a family
  Future<Map<String, dynamic>?> _checkUserFamily(BuildContext context) async {
    final supabaseService = context.read<SupabaseService>();

    print('Checking family for user: ${supabaseService.currentUser?.id}');

    if (supabaseService.currentUser == null) {
      print('No current user found');
      return null;
    }

    try {
      // Check if there's a selected family
      final selectedFamilyId = supabaseService.getSelectedFamilyId();

      if (selectedFamilyId != null) {
        print('Using selected family: $selectedFamilyId');

        // Get the family name
        final family = await supabaseService.getFamilyById(selectedFamilyId);

        if (family != null) {
          return {
            'family_id': selectedFamilyId,
            'family_name': family['name'] as String,
          };
        }
      }

      // No selected family, return null to show family list
      print('No selected family - showing family list');
      return null;
    } catch (e) {
      print('Error in _checkUserFamily: $e');
      rethrow;
    }
  }
}
