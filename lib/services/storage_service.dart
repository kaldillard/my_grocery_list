// lib/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/grocery_item.dart';
import '../models/family_member.dart';

/// Service for persistent storage using SharedPreferences
/// Handles saving and loading grocery items and family members
class StorageService {
  static const String _groceryItemsKey = 'grocery_items';
  static const String _familyMembersKey = 'family_members';
  static const String _selectedMemberIdKey = 'selected_member_id';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// Factory method to create StorageService with initialized SharedPreferences
  static Future<StorageService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ============ GROCERY ITEMS ============

  /// Save grocery items to storage
  Future<bool> saveGroceryItems(List<GroceryItem> items) async {
    try {
      final jsonList = items.map((item) => item.toJson()).toList();
      final jsonString = json.encode(jsonList);
      return await _prefs.setString(_groceryItemsKey, jsonString);
    } catch (e) {
      print('Error saving grocery items: $e');
      return false;
    }
  }

  /// Load grocery items from storage
  Future<List<GroceryItem>> loadGroceryItems() async {
    try {
      final jsonString = _prefs.getString(_groceryItemsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => GroceryItem.fromJson(json)).toList();
    } catch (e) {
      print('Error loading grocery items: $e');
      return [];
    }
  }

  /// Clear all grocery items
  Future<bool> clearGroceryItems() async {
    return await _prefs.remove(_groceryItemsKey);
  }

  // ============ FAMILY MEMBERS ============

  /// Save family members to storage
  Future<bool> saveFamilyMembers(List<FamilyMember> members) async {
    try {
      final jsonList = members.map((member) => member.toJson()).toList();
      final jsonString = json.encode(jsonList);
      return await _prefs.setString(_familyMembersKey, jsonString);
    } catch (e) {
      print('Error saving family members: $e');
      return false;
    }
  }

  /// Load family members from storage
  Future<List<FamilyMember>> loadFamilyMembers() async {
    try {
      final jsonString = _prefs.getString(_familyMembersKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => FamilyMember.fromJson(json)).toList();
    } catch (e) {
      print('Error loading family members: $e');
      return [];
    }
  }

  /// Clear all family members
  Future<bool> clearFamilyMembers() async {
    return await _prefs.remove(_familyMembersKey);
  }

  // ============ SELECTED MEMBER ============

  /// Save selected member ID
  Future<bool> saveSelectedMemberId(String? memberId) async {
    if (memberId == null) {
      return await _prefs.remove(_selectedMemberIdKey);
    }
    return await _prefs.setString(_selectedMemberIdKey, memberId);
  }

  /// Load selected member ID
  String? loadSelectedMemberId() {
    return _prefs.getString(_selectedMemberIdKey);
  }

  // ============ CLEAR ALL ============

  /// Clear all stored data
  Future<bool> clearAll() async {
    try {
      await _prefs.remove(_groceryItemsKey);
      await _prefs.remove(_familyMembersKey);
      await _prefs.remove(_selectedMemberIdKey);
      return true;
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }
}

// ============ MODEL EXTENSIONS FOR JSON ============

/// Extension to add JSON serialization to GroceryItem
extension GroceryItemJson on GroceryItem {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted,
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  static GroceryItem fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      addedBy: json['addedBy'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }
}

/// Extension to add JSON serialization to FamilyMember
extension FamilyMemberJson on FamilyMember {
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': color};
  }

  static FamilyMember fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
    );
  }
}
