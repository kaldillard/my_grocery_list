import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_grocery_list/blocs/family/family_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_event.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  group('FamilyBloc', () {
    late MockSupabaseService mockSupabaseService;
    const testFamilyId = 'test-family-id';

    setUp(() {
      mockSupabaseService = MockSupabaseService();
    });

    test('initial state is correct', () {
      final bloc = FamilyBloc(
        supabaseService: mockSupabaseService,
        familyId: testFamilyId,
      );

      expect(bloc.state, const FamilyState());
      expect(bloc.state.members, isEmpty);
      expect(bloc.state.isLoading, false);

      bloc.close();
    });

    blocTest<FamilyBloc, FamilyState>(
      'emits loading and loaded states when LoadFamilyData succeeds',
      setUp: () {
        when(
          () => mockSupabaseService.getFamilyMembers(testFamilyId),
        ).thenAnswer(
          (_) async => [
            {'id': 'member-1', 'display_name': 'John', 'color': '#FF6B6B'},
          ],
        );
        when(
          () => mockSupabaseService.getCurrentFamilyMember(testFamilyId),
        ).thenAnswer((_) async => {'id': 'member-1'});
      },
      build:
          () => FamilyBloc(
            supabaseService: mockSupabaseService,
            familyId: testFamilyId,
          ),
      act: (bloc) => bloc.add(LoadFamilyData()),
      expect:
          () => [
            const FamilyState(isLoading: true),
            predicate<FamilyState>((state) {
              return !state.isLoading &&
                  state.members.length == 1 &&
                  state.members.first.name == 'John';
            }),
          ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'updates selected member when SelectFamilyMember is added',
      build:
          () => FamilyBloc(
            supabaseService: mockSupabaseService,
            familyId: testFamilyId,
          ),
      act: (bloc) => bloc.add(SelectFamilyMember('member-1')),
      expect: () => [const FamilyState(selectedMemberId: 'member-1')],
    );

    blocTest<FamilyBloc, FamilyState>(
      'handles error gracefully when LoadFamilyData fails',
      setUp: () {
        when(
          () => mockSupabaseService.getFamilyMembers(testFamilyId),
        ).thenThrow(Exception('Network error'));
      },
      build:
          () => FamilyBloc(
            supabaseService: mockSupabaseService,
            familyId: testFamilyId,
          ),
      act: (bloc) => bloc.add(LoadFamilyData()),
      expect:
          () => [
            const FamilyState(isLoading: true),
            const FamilyState(isLoading: false),
          ],
    );
  });
}
