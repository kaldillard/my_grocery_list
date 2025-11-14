import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_grocery_list/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Test', () {
    testWidgets(
      'Complete user flow: login -> create family -> add items -> shopping mode',
      (tester) async {
        // Start the app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Skip if already logged in - look for login screen
        if (find.text('Sign In').evaluate().isNotEmpty) {
          // Test Login Flow
          await tester.enterText(
            find.byType(TextField).first,
            'test@example.com',
          );
          await tester.enterText(
            find.byType(TextField).last,
            'testpassword123',
          );
          await tester.tap(find.text('Sign In'));
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }

        // If no family exists, create one
        if (find.text('Create New Family').evaluate().isNotEmpty) {
          // Create a family
          await tester.tap(find.text('Create New Family'));
          await tester.pumpAndSettle();

          // Fill family name
          await tester.enterText(
            find.widgetWithText(TextField, 'Family Name'),
            'Test Family',
          );

          // Fill member name
          await tester.enterText(
            find.widgetWithText(TextField, 'Your Name'),
            'Test User',
          );

          await tester.tap(find.text('Create Family'));
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Close the invite code dialog if present
          if (find.text('Continue').evaluate().isNotEmpty) {
            await tester.tap(find.text('Continue'));
            await tester.pumpAndSettle();
          }
        }

        // Navigate to a list (tap first list if exists)
        if (find.byType(Card).evaluate().isNotEmpty) {
          await tester.tap(find.byType(Card).first);
          await tester.pumpAndSettle();
        }

        // Test Adding an Item
        await tester.enterText(find.byType(TextField), 'Test Milk');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify item was added
        expect(find.text('Test Milk'), findsOneWidget);

        // Test Adding Item with Details
        await tester.tap(find.byIcon(Icons.add_circle_outline));
        await tester.pumpAndSettle();

        // Should show add item dialog
        expect(find.text('Add Item'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextField, 'Item Name'),
          'Organic Bread',
        );

        // Increase quantity
        final addButtons = find.byIcon(Icons.add);
        await tester.tap(addButtons.first); // Quantity +
        await tester.pumpAndSettle();

        // Add notes
        await tester.enterText(
          find.widgetWithText(TextField, 'Notes (optional)'),
          'Whole wheat',
        );

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify item with quantity
        expect(find.text('Organic Bread'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // Quantity

        // Test Toggle Item Completion
        final checkbox = find.byType(Checkbox).first;
        await tester.tap(checkbox);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Item should move to completed section
        expect(find.text('COMPLETED'), findsOneWidget);

        // Test Shopping Mode
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Verify shopping mode opened
        expect(find.text('Shopping Mode'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // Tap an item to complete it
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Go back to list
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Test Edit Item
        final items = find.byType(Card);
        if (items.evaluate().isNotEmpty) {
          await tester.tap(items.first);
          await tester.pumpAndSettle();

          // Should show edit dialog
          expect(find.text('Edit Item'), findsOneWidget);

          // Close dialog
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
        }

        // Test Clear Completed Items
        if (find.byIcon(Icons.delete_sweep).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.delete_sweep));
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Completed section should be gone
          expect(find.text('COMPLETED'), findsNothing);
        }

        // Test Quantity Controls
        final removeButton = find.byIcon(Icons.remove);
        if (removeButton.evaluate().isNotEmpty) {
          await tester.tap(removeButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Quantity should decrease
          expect(find.text('1'), findsWidgets);
        }

        // Test Delete Item (swipe to dismiss)
        if (find.byType(Card).evaluate().isNotEmpty) {
          await tester.drag(find.byType(Card).first, const Offset(-500, 0));
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }

        print('✅ All integration tests passed!');
      },
    );
  });
}
