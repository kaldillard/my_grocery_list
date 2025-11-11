import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/auth/auth_event.dart';
import 'package:my_grocery_list/blocs/auth/auth_state.dart';
import 'package:my_grocery_list/services/supabase_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseService supabaseService;

  AuthBloc({required this.supabaseService}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);

    // Listen to auth state changes
    supabaseService.authStateChanges.listen((authState) {
      if (authState.session != null) {
        add(AuthCheckRequested());
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  void _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) {
    final user = supabaseService.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await supabaseService.signUp(
        event.email,
        event.password,
      );
      if (response.user != null) {
        emit(AuthAuthenticated(response.user!));
      } else {
        emit(AuthError('Sign up failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await supabaseService.signIn(
        event.email,
        event.password,
      );
      if (response.user != null) {
        emit(AuthAuthenticated(response.user!));
      } else {
        emit(AuthError('Sign in failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await supabaseService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
