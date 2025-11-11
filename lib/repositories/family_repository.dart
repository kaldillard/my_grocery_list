import '../models/family_member.dart';
import '../services/storage_service.dart';

/// Repository for managing family members
/// Acts as a mediator between the BLoC and storage service
class FamilyRepository {
  final StorageService _storageService;

  FamilyRepository({required StorageService storageService})
    : _storageService = storageService;

  /// Get all family members
  Future<List<FamilyMember>> getMembers() async {
    return await _storageService.loadFamilyMembers();
  }

  /// Add a new family member
  Future<bool> addMember(FamilyMember member) async {
    final members = await getMembers();
    members.add(member);
    return await _storageService.saveFamilyMembers(members);
  }

  /// Update an existing family member
  Future<bool> updateMember(FamilyMember updatedMember) async {
    final members = await getMembers();
    final index = members.indexWhere((m) => m.id == updatedMember.id);

    if (index == -1) return false;

    members[index] = updatedMember;
    return await _storageService.saveFamilyMembers(members);
  }

  /// Delete a family member
  Future<bool> deleteMember(String memberId) async {
    final members = await getMembers();
    members.removeWhere((m) => m.id == memberId);
    return await _storageService.saveFamilyMembers(members);
  }

  /// Get a specific family member by ID
  Future<FamilyMember?> getMemberById(String memberId) async {
    final members = await getMembers();
    try {
      return members.firstWhere((m) => m.id == memberId);
    } catch (e) {
      return null;
    }
  }

  /// Get a family member by name
  Future<FamilyMember?> getMemberByName(String name) async {
    final members = await getMembers();
    try {
      return members.firstWhere((m) => m.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Check if a member name already exists
  Future<bool> memberExists(String name) async {
    final members = await getMembers();
    return members.any((m) => m.name.toLowerCase() == name.toLowerCase());
  }

  /// Get the currently selected member ID
  String? getSelectedMemberId() {
    return _storageService.loadSelectedMemberId();
  }

  /// Save the selected member ID
  Future<bool> saveSelectedMemberId(String? memberId) async {
    return await _storageService.saveSelectedMemberId(memberId);
  }

  /// Clear all family members
  Future<bool> clearAll() async {
    return await _storageService.clearFamilyMembers();
  }

  /// Save all members (batch operation)
  Future<bool> saveMembers(List<FamilyMember> members) async {
    return await _storageService.saveFamilyMembers(members);
  }

  /// Get member count
  Future<int> getMemberCount() async {
    final members = await getMembers();
    return members.length;
  }
}
