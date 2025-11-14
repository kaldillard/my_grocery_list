import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_state.dart';
import 'package:my_grocery_list/models/category.dart';
import 'package:my_grocery_list/models/grocery_item.dart';
import 'package:my_grocery_list/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

void main() {
  setUpAll(() {
    registerFallbackValue(GroceryCategory.other);
  });

  group('GroceryBloc', () {
    late MockSupabaseService mockSupabaseService;
    late MockRealtimeChannel mockChannel;
    const testListId = 'test-list-id';

    setUp(() {
      mockSupabaseService = MockSupabaseService();
      mockChannel = MockRealtimeChannel();

      // CRITICAL: Mock unsubscribe to return Future<String>
      when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');

      // Setup default mock responses
      when(
        () => mockSupabaseService.subscribeToGroceryItemsInList(any(), any()),
      ).thenReturn(mockChannel);
    });

    test('initial state is correct', () {
      final bloc = GroceryBloc(
        supabaseService: mockSupabaseService,
        listId: testListId,
      );

      expect(bloc.state, const GroceryState());
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.isLoading, false);

      bloc.close();
    });

    blocTest<GroceryBloc, GroceryState>(
      'emits loading and loaded states when LoadGroceryData succeeds',
      setUp: () {
        when(
          () => mockSupabaseService.getGroceryItemsForList(testListId),
        ).thenAnswer(
          (_) async => [
            {
              'id': '1',
              'name': 'Milk',
              'is_completed': false,
              'added_at': DateTime.now().toIso8601String(),
              'quantity': 1,
              'category': 'dairy',
              'notes': null,
              'family_members': {'display_name': 'John'},
            },
          ],
        );
      },
      build:
          () => GroceryBloc(
            supabaseService: mockSupabaseService,
            listId: testListId,
          ),
      act: (bloc) => bloc.add(LoadGroceryData()),
      expect:
          () => [
            const GroceryState(isLoading: true),
            predicate<GroceryState>((state) {
              return !state.isLoading &&
                  state.items.length == 1 &&
                  state.items.first.name == 'Milk';
            }),
          ],
      verify: (_) {
        verify(
          () => mockSupabaseService.getGroceryItemsForList(testListId),
        ).called(1);
      },
    );

    blocTest<GroceryBloc, GroceryState>(
      'calls service when AddGroceryItem is added',
      setUp: () {
        when(
          () => mockSupabaseService.addGroceryItemToList(
            listId: any(named: 'listId'),
            name: any(named: 'name'),
            addedById: any(named: 'addedById'),
            quantity: any(named: 'quantity'),
            category: any(named: 'category'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer((_) async {});
      },
      build:
          () => GroceryBloc(
            supabaseService: mockSupabaseService,
            listId: testListId,
          ),
      act:
          (bloc) => bloc.add(
            AddGroceryItem(
              'Bread',
              'member-1',
              quantity: 2,
              category: GroceryCategory.bakery,
              notes: 'Whole wheat',
            ),
          ),
      verify: (_) {
        verify(
          () => mockSupabaseService.addGroceryItemToList(
            listId: testListId,
            name: 'Bread',
            addedById: 'member-1',
            quantity: 2,
            category: GroceryCategory.bakery,
            notes: 'Whole wheat',
          ),
        ).called(1);
      },
    );

    blocTest<GroceryBloc, GroceryState>(
      'calls service when UpdateGroceryItemQuantity is added',
      setUp: () {
        when(
          () => mockSupabaseService.updateGroceryItemQuantity(any(), any()),
        ).thenAnswer((_) async {});
      },
      build:
          () => GroceryBloc(
            supabaseService: mockSupabaseService,
            listId: testListId,
          ),
      act: (bloc) => bloc.add(UpdateGroceryItemQuantity('item-1', 3)),
      verify: (_) {
        verify(
          () => mockSupabaseService.updateGroceryItemQuantity('item-1', 3),
        ).called(1);
      },
    );

    blocTest<GroceryBloc, GroceryState>(
      'toggles item completion when ToggleGroceryItem is added',
      setUp: () {
        when(
          () => mockSupabaseService.getGroceryItemsForList(testListId),
        ).thenAnswer((_) async => []);
        when(
          () => mockSupabaseService.updateGroceryItem(any(), any()),
        ).thenAnswer((_) async {});
      },
      build:
          () => GroceryBloc(
            supabaseService: mockSupabaseService,
            listId: testListId,
          ),
      seed:
          () => GroceryState(
            items: [
              GroceryItem(
                id: 'item-1',
                name: 'Milk',
                addedBy: 'John',
                addedAt: DateTime.now(),
                isCompleted: false,
              ),
            ],
          ),
      act: (bloc) => bloc.add(ToggleGroceryItem('item-1')),
      verify: (_) {
        verify(
          () => mockSupabaseService.updateGroceryItem('item-1', true),
        ).called(1);
      },
    );

    blocTest<GroceryBloc, GroceryState>(
      'calls service when DeleteGroceryItem is added',
      setUp: () {
        when(
          () => mockSupabaseService.deleteGroceryItem(any()),
        ).thenAnswer((_) async {});
      },
      build:
          () => GroceryBloc(
            supabaseService: mockSupabaseService,
            listId: testListId,
          ),
      act: (bloc) => bloc.add(DeleteGroceryItem('item-1')),
      verify: (_) {
        verify(() => mockSupabaseService.deleteGroceryItem('item-1')).called(1);
      },
    );

    blocTest<GroceryBloc, GroceryState>(
      'calls service when UpdateGroceryItem is added',
      setUp: () {
        when(
          () => mockSupabaseService.updateGroceryItemDetails(
            any(),
            name: any(named: 'name'),
            category: any(named: 'category'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer((_) async {});
      },
      build:
          () => GroceryBloc(
            supabaseService: mockSupabaseService,
            listId: testListId,
          ),
      act:
          (bloc) => bloc.add(
            UpdateGroceryItem(
              'item-1',
              name: 'New Name',
              category: GroceryCategory.produce,
              notes: 'Fresh',
            ),
          ),
      verify: (_) {
        verify(
          () => mockSupabaseService.updateGroceryItemDetails(
            'item-1',
            name: 'New Name',
            category: GroceryCategory.produce,
            notes: 'Fresh',
          ),
        ).called(1);
      },
    );

    blocTest<GroceryBloc, GroceryState>(
      'updates state when GroceryItemsUpdated is added',
      build:
          () => GroceryBloc(
            supabaseService: mockSupabaseService,
            listId: testListId,
          ),
      act:
          (bloc) => bloc.add(
            GroceryItemsUpdated([
              {
                'id': '1',
                'name': 'Updated Item',
                'is_completed': false,
                'added_at': DateTime.now().toIso8601String(),
                'quantity': 1,
                'category': 'other',
                'family_members': {'display_name': 'Jane'},
              },
            ]),
          ),
      expect:
          () => [
            predicate<GroceryState>((state) {
              return state.items.length == 1 &&
                  state.items.first.name == 'Updated Item';
            }),
          ],
    );

    test('unsubscribes from realtime on close', () async {
      final bloc = GroceryBloc(
        supabaseService: mockSupabaseService,
        listId: testListId,
      );

      await bloc.close();

      verify(() => mockChannel.unsubscribe()).called(1);
    });
  });
}
