// lib/services/supabase_service.dart

import 'package:my_grocery_list/models/subscription.dart';
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
    print(
      'SupabaseService - Subscribing to grocery items for family: $familyId',
    );

    final channel =
        _client
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
                print('SupabaseService - Realtime event: ${payload.eventType}');
                print('SupabaseService - New data: ${payload.newRecord}');

                // Fetch fresh data
                final items = await getGroceryItems(familyId);
                print(
                  'SupabaseService - Fetched ${items.length} items after update',
                );
                onData(items);
              },
            )
            .subscribe();

    //print('SupabaseService - Channel created: ${channel.status}');
    return channel;
  }

  Future<Map<String, dynamic>?> getFamilyMembershipForCurrentUser() async {
    if (currentUser == null) return null;

    // Check if user has a selected family
    if (_selectedFamilyId != null) {
      // Verify the user is still a member of this family
      final membership =
          await _client
              .from('family_members')
              .select('family_id')
              .eq('user_id', currentUser!.id)
              .eq('family_id', _selectedFamilyId!)
              .maybeSingle();

      if (membership != null) {
        return membership;
      }
    }

    // Otherwise, get the most recent family or return null to show family list
    final memberships = await _client
        .from('family_members')
        .select('family_id')
        .eq('user_id', currentUser!.id)
        .order('joined_at', ascending: false)
        .limit(1);

    // If user has families, return null to show the family list screen
    // If user has no families, also return null to show family list (which will show empty state)
    return null;
  }

  /// Get all families the current user is a member of
  Future<List<Map<String, dynamic>>> getAllFamiliesForCurrentUser() async {
    if (currentUser == null) return [];

    // First get all families the user belongs to
    final memberships = await _client
        .from('family_members')
        .select('family_id, families!inner(id, name, invite_code, created_at)')
        .eq('user_id', currentUser!.id)
        .order('joined_at', ascending: false);

    // Then for each family, get the member count
    final List<Map<String, dynamic>> familiesWithCount = [];

    for (var membership in memberships) {
      final familyId = membership['family_id'];

      // Count members in this family
      final members = await _client
          .from('family_members')
          .select('id')
          .eq('family_id', familyId);

      familiesWithCount.add({
        'families': membership['families'],
        'family_id': familyId,
        'member_count': members.length,
      });
    }

    return familiesWithCount;
  }

  /// Get a specific family by ID
  Future<Map<String, dynamic>?> getFamilyById(String familyId) async {
    return await _client
        .from('families')
        .select()
        .eq('id', familyId)
        .maybeSingle();
  }

  /// Store selected family ID locally (you can use SharedPreferences later)
  String? _selectedFamilyId;

  void setSelectedFamilyId(String familyId) {
    _selectedFamilyId = familyId;
  }

  String? getSelectedFamilyId() {
    return _selectedFamilyId;
  }

  Future<Subscription?> getSubscriptionForUser(String userId) async {
    final result =
        await _client
            .from('subscriptions')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

    return result != null ? Subscription.fromJson(result) : null;
  }

  Future<bool> canCreateList(String userId) async {
    final sub = await getSubscriptionForUser(userId);

    if (sub == null || sub.tier == SubscriptionTier.free) {
      // Check if user already has a list
      final lists = await _client
          .from('families')
          .select('id')
          .eq('created_by', userId);

      return lists.length < 1;
    }

    return true; // Pro and Family have unlimited lists
  }

  Future<bool> canAddMember(String familyId) async {
    final sub =
        await _client
            .from('subscriptions')
            .select()
            .eq('family_id', familyId)
            .maybeSingle();

    if (sub == null) return false;

    final currentMembers = await _client
        .from('family_members')
        .select('id')
        .eq('family_id', familyId);

    final subData = Subscription.fromJson(sub);
    return currentMembers.length < subData.maxMembers;
  }

  Future<void> sendSubscriptionEmail() async {
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    print('🔵 Sending subscription email to: ${currentUser!.email}');
    print('🔵 User ID: ${currentUser!.id}');

    try {
      // Get the current session to access the JWT token
      final session = _client.auth.currentSession;

      if (session == null) {
        throw Exception('No active session found');
      }

      print('🔵 Got session, calling function...');

      final response = await _client.functions.invoke(
        'send-subscription-email',
        body: {'user_id': currentUser!.id, 'email': currentUser!.email},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      print('🔵 Response status: ${response.status}');
      print('🔵 Response data: ${response.data}');

      if (response.status != 200) {
        String errorMessage = 'Failed to send email';

        if (response.data != null) {
          if (response.data is Map && response.data['error'] != null) {
            errorMessage = response.data['error'].toString();
          } else {
            errorMessage = response.data.toString();
          }
        }

        print('🔴 Error: $errorMessage');
        throw Exception(errorMessage);
      }

      print('✅ Email sent successfully');
    } catch (e, stackTrace) {
      print('🔴 Exception in sendSubscriptionEmail: $e');
      print('🔴 Stack trace: $stackTrace');
      rethrow;
    }
  }
}
