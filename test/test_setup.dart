import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/blocs/family/family_event.dart';
import 'package:my_grocery_list/blocs/auth/auth_event.dart';
import 'package:my_grocery_list/blocs/subscription/subscription_event.dart';
import 'package:my_grocery_list/models/category.dart';

/// Call this in the main() function of each test file
void setupTestFallbackValues() {
  // Register fallback values for all event types
  registerFallbackValue(LoadGroceryData());
  registerFallbackValue(AddGroceryItem('test', 'test-id'));
  registerFallbackValue(ToggleGroceryItem('test-id'));
  registerFallbackValue(DeleteGroceryItem('test-id'));
  registerFallbackValue(UpdateGroceryItemQuantity('test-id', 1));
  registerFallbackValue(UpdateGroceryItem('test-id'));
  registerFallbackValue(ClearCompletedItems());
  registerFallbackValue(GroceryItemsUpdated([]));

  registerFallbackValue(LoadFamilyData());
  registerFallbackValue(AddFamilyMember('test'));
  registerFallbackValue(RemoveFamilyMember('test-id'));
  registerFallbackValue(SelectFamilyMember('test-id'));

  registerFallbackValue(AuthCheckRequested());
  registerFallbackValue(AuthSignUpRequested('test@test.com', 'password'));
  registerFallbackValue(AuthSignInRequested('test@test.com', 'password'));
  registerFallbackValue(AuthSignOutRequested());

  registerFallbackValue(LoadSubscription());
  registerFallbackValue(RefreshSubscription());
  registerFallbackValue(StartListeningToSubscription());
  registerFallbackValue(StopListeningToSubscription());
  registerFallbackValue(ResetSubscription());

  // Register category fallback
  registerFallbackValue(GroceryCategory.other);
}
