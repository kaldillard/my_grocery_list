import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_grocery_list/blocs/auth/auth_bloc.dart';
import 'package:my_grocery_list/blocs/auth/auth_event.dart';
import 'package:my_grocery_list/blocs/auth/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../mocks/mock_factories.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() {
    setupTestFallbackValues();
  });

  group('AuthBloc', () {
    late MockSupabaseService mockSupabaseService;
    late User mockUser;

    setUp(() {
      mockSupabaseService = MockSupabaseService();
      mockUser = MockFactory.createMockUser();

      // Default auth state stream
      when(
        () => mockSupabaseService.authStateChanges,
      ).thenAnswer((_) => const Stream.empty());
    });

    test('initial state is AuthInitial', () {
      final bloc = AuthBloc(supabaseService: mockSupabaseService);
      expect(bloc.state, isA<AuthInitial>());
      bloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] when user is logged in',
      setUp: () {
        when(() => mockSupabaseService.currentUser).thenReturn(mockUser);
      },
      build: () => AuthBloc(supabaseService: mockSupabaseService),
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when user is not logged in',
      setUp: () {
        when(() => mockSupabaseService.currentUser).thenReturn(null);
      },
      build: () => AuthBloc(supabaseService: mockSupabaseService),
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [isA<AuthUnauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on successful sign in',
      setUp: () {
        when(() => mockSupabaseService.signIn(any(), any())).thenAnswer(
          (_) async => AuthResponse(
            user: mockUser,
            session: Session(
              accessToken: 'token',
              tokenType: 'bearer',
              user: mockUser,
            ),
          ),
        );
      },
      build: () => AuthBloc(supabaseService: mockSupabaseService),
      act: (bloc) => bloc.add(AuthSignInRequested('test@test.com', 'password')),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on failed sign in',
      setUp: () {
        when(
          () => mockSupabaseService.signIn(any(), any()),
        ).thenThrow(Exception('Invalid credentials'));
      },
      build: () => AuthBloc(supabaseService: mockSupabaseService),
      act: (bloc) => bloc.add(AuthSignInRequested('test@test.com', 'wrong')),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] on sign out',
      setUp: () {
        when(() => mockSupabaseService.signOut()).thenAnswer((_) async {});
      },
      build: () => AuthBloc(supabaseService: mockSupabaseService),
      act: (bloc) => bloc.add(AuthSignOutRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );
  });
}
