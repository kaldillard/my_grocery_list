// lib/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  static Future<SupabaseService> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    return SupabaseService(Supabase.instance.client);
  }

  // Auth methods
  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Family methods
  Future<Map<String, dynamic>?> createFamily(String familyName) async {
    final response =
        await _client
            .from('families')
            .insert({'name': familyName, 'created_by': currentUser!.id})
            .select()
            .single();
    return response;
  }

  Future<Map<String, dynamic>?> joinFamilyByCode(String inviteCode) async {
    final family =
        await _client
            .from('families')
            .select()
            .eq('invite_code', inviteCode)
            .single();
    return family;
  }

  Future<void> addFamilyMember({
    required String familyId,
    required String displayName,
    required String color,
  }) async {
    await _client.from('family_members').insert({
      'family_id': familyId,
      'user_id': currentUser!.id,
      'display_name': displayName,
      'color': color,
    });
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers(String familyId) async {
    return await _client
        .from('family_members')
        .select()
        .eq('family_id', familyId);
  }

  Future<Map<String, dynamic>?> getCurrentFamilyMember(String familyId) async {
    final result =
        await _client
            .from('family_members')
            .select()
            .eq('family_id', familyId)
            .eq('user_id', currentUser!.id)
            .maybeSingle();
    return result;
  }

  // Grocery items methods
  Future<List<Map<String, dynamic>>> getGroceryItems(String familyId) async {
    return await _client
        .from('grocery_items')
        .select(
          '*, family_members!grocery_items_added_by_fkey(display_name, color)',
        )
        .eq('family_id', familyId)
        .order('added_at', ascending: false);
  }

  Future<void> addGroceryItem({
    required String familyId,
    required String name,
    required String addedById,
  }) async {
    await _client.from('grocery_items').insert({
      'family_id': familyId,
      'name': name,
      'added_by': addedById,
    });
  }

  Future<void> updateGroceryItem(String itemId, bool isCompleted) async {
    await _client
        .from('grocery_items')
        .update({
          'is_completed': isCompleted,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', itemId);
  }

  Future<void> deleteGroceryItem(String itemId) async {
    await _client.from('grocery_items').delete().eq('id', itemId);
  }

  Future<void> clearCompletedItems(String familyId) async {
    await _client
        .from('grocery_items')
        .delete()
        .eq('family_id', familyId)
        .eq('is_completed', true);
  }

  // Real-time subscription for grocery items
  RealtimeChannel subscribeToGroceryItems(
    String familyId,
    void Function(List<Map<String, dynamic>>) onData,
  ) {
    return _client
        .channel('grocery_items_$familyId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'grocery_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'family_id',
            value: familyId,
          ),
          callback: (payload) async {
            final items = await getGroceryItems(familyId);
            onData(items);
          },
        )
        .subscribe();
  }

  Future<Map<String, dynamic>?> getFamilyMembershipForCurrentUser() async {
    if (currentUser == null) return null;

    return await _client
        .from('family_members')
        .select('family_id')
        .eq('user_id', currentUser!.id)
        .maybeSingle();
  }
}
