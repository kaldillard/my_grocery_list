import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_grocery_list/blocs/auth/auth_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/subscription/subscription_bloc.dart';
import 'package:my_grocery_list/services/supabase_service.dart';
import 'package:my_grocery_list/models/category.dart';
import 'package:my_grocery_list/models/grocery_item.dart';
import 'package:my_grocery_list/models/family_member.dart';

// Mock classes
class MockSupabaseService extends Mock implements SupabaseService {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockFamilyBloc extends Mock implements FamilyBloc {}

class MockGroceryBloc extends Mock implements GroceryBloc {}

class MockSubscriptionBloc extends Mock implements SubscriptionBloc {}

// Test data factories
class TestData {
  static GroceryItem createGroceryItem({
    String id = 'test-id-1',
    String name = 'Test Item',
    bool isCompleted = false,
    String addedBy = 'Test User',
    DateTime? addedAt,
    int quantity = 1,
    GroceryCategory category = GroceryCategory.other,
    String? notes,
  }) {
    return GroceryItem(
      id: id,
      name: name,
      isCompleted: isCompleted,
      addedBy: addedBy,
      addedAt: addedAt ?? DateTime.now(),
      quantity: quantity,
      category: category,
      notes: notes,
    );
  }

  static FamilyMember createFamilyMember({
    String id = 'member-1',
    String name = 'Test Member',
    String color = '#FF6B6B',
  }) {
    return FamilyMember(id: id, name: name, color: color);
  }

  static List<GroceryItem> createGroceryList({int count = 5}) {
    return List.generate(
      count,
      (i) => createGroceryItem(
        id: 'item-$i',
        name: 'Item ${i + 1}',
        isCompleted: i % 2 == 0, // Every other item completed
      ),
    );
  }
}

// Widget test helpers
class WidgetTestHelper {
  static Widget wrapWithMaterialApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  static Widget wrapWithBlocs(
    Widget child, {
    required SupabaseService supabaseService,
    AuthBloc? authBloc,
    FamilyBloc? familyBloc,
    GroceryBloc? groceryBloc,
    SubscriptionBloc? subscriptionBloc,
  }) {
    return MultiBlocProvider(
      providers: [
        if (authBloc != null) BlocProvider<AuthBloc>.value(value: authBloc),
        if (familyBloc != null)
          BlocProvider<FamilyBloc>.value(value: familyBloc),
        if (groceryBloc != null)
          BlocProvider<GroceryBloc>.value(value: groceryBloc),
        if (subscriptionBloc != null)
          BlocProvider<SubscriptionBloc>.value(value: subscriptionBloc),
      ],
      child: RepositoryProvider.value(
        value: supabaseService,
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }
}

// Pump and settle with longer timeout for animations
extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpAndSettleWithTimeout([
    Duration timeout = const Duration(seconds: 5),
  ]) async {
    await pumpAndSettle(timeout);
  }
}
