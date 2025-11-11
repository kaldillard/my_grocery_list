import '../models/grocery_item.dart';
import '../services/storage_service.dart';

/// Repository for managing grocery items
/// Acts as a mediator between the BLoC and storage service
class GroceryRepository {
  final StorageService _storageService;

  GroceryRepository({required StorageService storageService})
    : _storageService = storageService;

  /// Get all grocery items
  Future<List<GroceryItem>> getItems() async {
    return await _storageService.loadGroceryItems();
  }

  /// Add a new grocery item
  Future<bool> addItem(GroceryItem item) async {
    final items = await getItems();
    items.add(item);
    return await _storageService.saveGroceryItems(items);
  }

  /// Update an existing grocery item
  Future<bool> updateItem(GroceryItem updatedItem) async {
    final items = await getItems();
    final index = items.indexWhere((item) => item.id == updatedItem.id);

    if (index == -1) return false;

    items[index] = updatedItem;
    return await _storageService.saveGroceryItems(items);
  }

  /// Delete a grocery item
  Future<bool> deleteItem(String itemId) async {
    final items = await getItems();
    items.removeWhere((item) => item.id == itemId);
    return await _storageService.saveGroceryItems(items);
  }

  /// Toggle item completion status
  Future<bool> toggleItem(String itemId) async {
    final items = await getItems();
    final index = items.indexWhere((item) => item.id == itemId);

    if (index == -1) return false;

    items[index] = items[index].copyWith(
      isCompleted: !items[index].isCompleted,
    );
    return await _storageService.saveGroceryItems(items);
  }

  /// Clear completed items
  Future<bool> clearCompleted() async {
    final items = await getItems();
    final activeItems = items.where((item) => !item.isCompleted).toList();
    return await _storageService.saveGroceryItems(activeItems);
  }

  /// Get items by user
  Future<List<GroceryItem>> getItemsByUser(String userName) async {
    final items = await getItems();
    return items.where((item) => item.addedBy == userName).toList();
  }

  /// Get active (not completed) items
  Future<List<GroceryItem>> getActiveItems() async {
    final items = await getItems();
    return items.where((item) => !item.isCompleted).toList();
  }

  /// Get completed items
  Future<List<GroceryItem>> getCompletedItems() async {
    final items = await getItems();
    return items.where((item) => item.isCompleted).toList();
  }

  /// Clear all grocery items
  Future<bool> clearAll() async {
    return await _storageService.clearGroceryItems();
  }

  /// Save all items (batch operation)
  Future<bool> saveItems(List<GroceryItem> items) async {
    return await _storageService.saveGroceryItems(items);
  }
}
