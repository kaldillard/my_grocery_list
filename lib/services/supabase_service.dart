// lib/services/supabase_service.dart

import 'dart:async';
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
    print('🔓 Signing out user');

    // Clean up subscription listener
    await stopListeningToSubscription();

    // Clear cached subscription data
    _currentSubscription = null;
    _subscriptionController.add(null);

    // Clear selected family and list
    _selectedFamilyId = null;
    _selectedListId = null;

    // Sign out from Supabase
    await _client.auth.signOut();

    print('✅ Sign out complete - all caches cleared');
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
    try {
      print('🔍 Looking up family with invite code: $inviteCode');

      // Use maybeSingle() instead of single() to handle case where family doesn't exist
      final family =
          await _client
              .from('families')
              .select()
              .eq('invite_code', inviteCode.trim().toUpperCase())
              .maybeSingle();

      if (family == null) {
        print('❌ No family found with that invite code');
        throw Exception('Invalid invite code. Please check and try again.');
      }

      print('✅ Found family: ${family['name']}');
      return family;
    } catch (e) {
      print('❌ Error in joinFamilyByCode: $e');
      rethrow;
    }
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

  // ==================== SUBSCRIPTION METHODS ====================

  // Realtime subscription listener
  RealtimeChannel? _subscriptionChannel;

  // Current subscription data cache
  Subscription? _currentSubscription;

  // Stream controller to notify listeners
  final _subscriptionController = StreamController<Subscription?>.broadcast();

  /// Stream that emits subscription updates
  Stream<Subscription?> get subscriptionStream =>
      _subscriptionController.stream;

  /// Get cached subscription (useful for synchronous access)
  Subscription? get currentSubscription => _currentSubscription;

  /// Check if user has an active paid subscription
  bool get hasActiveSubscription {
    return _currentSubscription != null &&
        _currentSubscription!.status == 'active' &&
        _currentSubscription!.tier != SubscriptionTier.free;
  }

  /// Get current subscription tier
  SubscriptionTier get subscriptionTier {
    return _currentSubscription?.tier ?? SubscriptionTier.free;
  }

  /// Get max lists allowed (null means unlimited)
  int? get maxLists {
    return _currentSubscription?.maxLists;
  }

  /// Start listening to subscription changes for the current user's family
  Future<void> startListeningToSubscription() async {
    if (currentUser == null) {
      print('⚠️ No user logged in, cannot listen to subscription');
      return;
    }

    try {
      print('🎧 Setting up subscription listener...');

      // Get user's family_id
      final familyResponse =
          await _client
              .from('family_members')
              .select('family_id')
              .eq('user_id', currentUser!.id)
              .maybeSingle();

      if (familyResponse == null) {
        print('⚠️ User not in any family');
        return;
      }

      final familyId = familyResponse['family_id'];
      print('👨‍👩‍👧‍👦 Listening to subscriptions for family: $familyId');

      // Cancel existing channel if any
      await _subscriptionChannel?.unsubscribe();

      // Create new channel for this family's subscription
      _subscriptionChannel =
          _client
              .channel('subscription-$familyId')
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'subscriptions',
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'family_id',
                  value: familyId,
                ),
                callback: (payload) {
                  print('🔔 Subscription change detected!');
                  print('Event: ${payload.eventType}');
                  print('Data: ${payload.newRecord}');

                  if (payload.newRecord.isNotEmpty) {
                    final subscription = Subscription.fromJson(
                      payload.newRecord,
                    );
                    _currentSubscription = subscription;
                    _subscriptionController.add(subscription);

                    // Show notification if subscription became active
                    if (subscription.status == 'active') {
                      print('✅ Subscription is now ACTIVE!');
                      print('Tier: ${subscription.tier}');
                      print('Max lists: ${subscription.maxLists}');
                      print('Max members: ${subscription.maxMembers}');
                    }
                  }
                },
              )
              .subscribe();

      print('✅ Subscription listener active');

      // Also fetch current subscription state
      await fetchCurrentSubscription();
    } catch (e) {
      print('❌ Error setting up subscription listener: $e');
    }
  }

  /// Fetch the current subscription (initial state)
  Future<Subscription?> fetchCurrentSubscription() async {
    if (currentUser == null) return null;

    try {
      // Get user's family_id
      final familyResponse =
          await _client
              .from('family_members')
              .select('family_id')
              .eq('user_id', currentUser!.id)
              .maybeSingle();

      if (familyResponse == null) return null;

      final familyId = familyResponse['family_id'];

      // Get subscription
      final subscriptionData =
          await _client
              .from('subscriptions')
              .select('*')
              .eq('family_id', familyId)
              .maybeSingle();

      if (subscriptionData != null) {
        final subscription = Subscription.fromJson(subscriptionData);
        print(
          '📊 Current subscription: ${subscription.tier} (${subscription.status})',
        );
        _currentSubscription = subscription;
        _subscriptionController.add(subscription);
        return subscription;
      } else {
        print('📊 No active subscription found');
        _currentSubscription = null;
        _subscriptionController.add(null);
        return null;
      }
    } catch (e) {
      print('❌ Error fetching subscription: $e');
      return null;
    }
  }

  /// Stop listening to subscription changes
  Future<void> stopListeningToSubscription() async {
    print('🔇 Stopping subscription listener');
    await _subscriptionChannel?.unsubscribe();
    _subscriptionChannel = null;
  }

  /// Dispose resources (call this when service is no longer needed)
  void dispose() {
    stopListeningToSubscription();
    _subscriptionController.close();
  }

  // Legacy methods - keeping for backward compatibility
  Future<Subscription?> getSubscriptionForUser(String userId) async {
    final result =
        await _client
            .from('subscriptions')
            .select()
            .eq('user_id', userId)
            .eq('status', 'active')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    return result != null ? Subscription.fromJson(result) : null;
  }

  Future<bool> canCreateList(String userId) async {
    // Use cached subscription if available
    if (_currentSubscription != null) {
      if (_currentSubscription!.tier == SubscriptionTier.free) {
        final lists = await _client
            .from('families')
            .select('id')
            .eq('created_by', userId);
        return lists.length < 1;
      }
      return true;
    }

    // Fallback to fetching
    final sub = await getSubscriptionForUser(userId);

    if (sub == null || sub.tier == SubscriptionTier.free) {
      final lists = await _client
          .from('families')
          .select('id')
          .eq('created_by', userId);

      return lists.length < 1;
    }

    return true;
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

    Future<List<Map<String, dynamic>>> getGroceryListsForFamily(
      String familyId,
    ) async {
      return await _client
          .from('grocery_lists')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
    }

    /// Create a new grocery list
    Future<Map<String, dynamic>> createGroceryList({
      required String familyId,
      required String name,
    }) async {
      final result =
          await _client
              .from('grocery_lists')
              .insert({
                'family_id': familyId,
                'name': name,
                'created_by': currentUser!.id,
              })
              .select()
              .single();

      return result;
    }

    /// Update a grocery list name
    Future<void> updateGroceryListName(String listId, String newName) async {
      await _client
          .from('grocery_lists')
          .update({'name': newName})
          .eq('id', listId);
    }

    /// Delete a grocery list (and all its items via CASCADE)
    Future<void> deleteGroceryList(String listId) async {
      await _client.from('grocery_lists').delete().eq('id', listId);
    }

    // ==================== UPDATED GROCERY ITEMS METHODS ====================

    /// Get grocery items for a specific list (replaces old getGroceryItems)
    Future<List<Map<String, dynamic>>> getGroceryItemsForList(
      String listId,
    ) async {
      return await _client
          .from('grocery_items')
          .select(
            '*, family_members!grocery_items_added_by_fkey(display_name, color)',
          )
          .eq('list_id', listId)
          .order('added_at', ascending: false);
    }

    /// Add grocery item (updated to use list_id instead of family_id)
    Future<void> addGroceryItemToList({
      required String listId,
      required String name,
      required String addedById,
    }) async {
      await _client.from('grocery_items').insert({
        'list_id': listId,
        'name': name,
        'added_by': addedById,
      });
    }

    /// Clear completed items for a list
    Future<void> clearCompletedItemsInList(String listId) async {
      await _client
          .from('grocery_items')
          .delete()
          .eq('list_id', listId)
          .eq('is_completed', true);
    }

    // ==================== UPDATED REALTIME SUBSCRIPTION ====================

    /// Subscribe to grocery items for a specific list
    RealtimeChannel subscribeToGroceryItemsInList(
      String listId,
      void Function(List<Map<String, dynamic>>) onData,
    ) {
      print('SupabaseService - Subscribing to grocery items for list: $listId');

      final channel =
          _client
              .channel('grocery_items_list_$listId')
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'grocery_items',
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'list_id',
                  value: listId,
                ),
                callback: (payload) async {
                  print(
                    'SupabaseService - Realtime event: ${payload.eventType}',
                  );

                  // Fetch fresh data
                  final items = await getGroceryItemsForList(listId);
                  print(
                    'SupabaseService - Fetched ${items.length} items after update',
                  );
                  onData(items);
                },
              )
              .subscribe();

      return channel;
    }

    // ==================== LIST SELECTION (LOCAL STORAGE) ====================

    String? _selectedListId;

    void setSelectedListId(String listId) {
      _selectedListId = listId;
    }

    String? getSelectedListId() {
      return _selectedListId;
    }

    /// Get the selected list ID for a family (or return the first/default list)
    Future<String?> getOrCreateDefaultList(String familyId) async {
      // Check if there's a selected list
      if (_selectedListId != null) {
        return _selectedListId;
      }

      // Get all lists for the family
      final lists = await getGroceryListsForFamily(familyId);

      if (lists.isEmpty) {
        // Create a default list if none exists
        final newList = await createGroceryList(
          familyId: familyId,
          name: 'Family Grocery Haul',
        );
        _selectedListId = newList['id'] as String;
        return _selectedListId;
      }

      // Return the first list
      _selectedListId = lists[0]['id'] as String;
      return _selectedListId;
    }
  }

  Future<List<Map<String, dynamic>>> getGroceryListsForFamily(
    String familyId,
  ) async {
    return await _client
        .from('grocery_lists')
        .select()
        .eq('family_id', familyId)
        .order('created_at', ascending: false);
  }

  /// Create a new grocery list
  Future<Map<String, dynamic>> createGroceryList({
    required String familyId,
    required String name,
  }) async {
    final result =
        await _client
            .from('grocery_lists')
            .insert({
              'family_id': familyId,
              'name': name,
              'created_by': currentUser!.id,
            })
            .select()
            .single();

    return result;
  }

  /// Update a grocery list name
  Future<void> updateGroceryListName(String listId, String newName) async {
    await _client
        .from('grocery_lists')
        .update({'name': newName})
        .eq('id', listId);
  }

  /// Delete a grocery list (and all its items via CASCADE)
  Future<void> deleteGroceryList(String listId) async {
    await _client.from('grocery_lists').delete().eq('id', listId);
  }

  // ==================== UPDATED GROCERY ITEMS METHODS ====================

  /// Get grocery items for a specific list (replaces old getGroceryItems)
  Future<List<Map<String, dynamic>>> getGroceryItemsForList(
    String listId,
  ) async {
    return await _client
        .from('grocery_items')
        .select(
          '*, family_members!grocery_items_added_by_fkey(display_name, color)',
        )
        .eq('list_id', listId)
        .order('added_at', ascending: false);
  }

  /// Add grocery item (updated to use list_id instead of family_id)
  Future<void> addGroceryItemToList({
    required String listId,
    required String name,
    required String addedById,
  }) async {
    await _client.from('grocery_items').insert({
      'list_id': listId,
      'name': name,
      'added_by': addedById,
    });
  }

  /// Clear completed items for a list
  Future<void> clearCompletedItemsInList(String listId) async {
    await _client
        .from('grocery_items')
        .delete()
        .eq('list_id', listId)
        .eq('is_completed', true);
  }

  // ==================== UPDATED REALTIME SUBSCRIPTION ====================

  /// Subscribe to grocery items for a specific list
  RealtimeChannel subscribeToGroceryItemsInList(
    String listId,
    void Function(List<Map<String, dynamic>>) onData,
  ) {
    print('SupabaseService - Subscribing to grocery items for list: $listId');

    final channel =
        _client
            .channel('grocery_items_list_$listId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'grocery_items',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'list_id',
                value: listId,
              ),
              callback: (payload) async {
                print('SupabaseService - Realtime event: ${payload.eventType}');

                // Fetch fresh data
                final items = await getGroceryItemsForList(listId);
                print(
                  'SupabaseService - Fetched ${items.length} items after update',
                );
                onData(items);
              },
            )
            .subscribe();

    return channel;
  }

  // ==================== LIST SELECTION (LOCAL STORAGE) ====================

  String? _selectedListId;

  void setSelectedListId(String listId) {
    _selectedListId = listId;
  }

  String? getSelectedListId() {
    return _selectedListId;
  }

  /// Get the selected list ID for a family (or return the first/default list)
  Future<String?> getOrCreateDefaultList(String familyId) async {
    // Check if there's a selected list
    if (_selectedListId != null) {
      return _selectedListId;
    }

    // Get all lists for the family
    final lists = await getGroceryListsForFamily(familyId);

    if (lists.isEmpty) {
      // Create a default list if none exists
      final newList = await createGroceryList(
        familyId: familyId,
        name: 'Family Grocery Haul',
      );
      _selectedListId = newList['id'] as String;
      return _selectedListId;
    }

    // Return the first list
    _selectedListId = lists[0]['id'] as String;
    return _selectedListId;
  }
}
