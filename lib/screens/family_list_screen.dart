// lib/screens/family_list_screen.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/auth/auth_bloc.dart';
import 'package:my_grocery_list/blocs/auth/auth_event.dart';
import 'package:my_grocery_list/blocs/subscription/subscription_bloc.dart';
import 'package:my_grocery_list/blocs/subscription/subscription_state.dart';
import 'package:my_grocery_list/models/subscription.dart';
import 'package:my_grocery_list/screens/auth_wrapper_screen.dart';
import 'package:my_grocery_list/screens/family_setup_screen.dart';
import 'package:my_grocery_list/screens/list_selection_screen.dart';
import 'package:my_grocery_list/screens/subscription_screen.dart';
import 'package:my_grocery_list/services/supabase_service.dart';
import 'package:my_grocery_list/utils/color_utils.dart';

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({super.key});

  @override
  State<FamilyListScreen> createState() => _FamilyListScreenState();
}

bool get _canShowSubscription {
  if (kIsWeb) return true;
  try {
    return !Platform.isIOS;
  } catch (e) {
    return true;
  }
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  List<Map<String, dynamic>> _families = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamilies();
  }

  Future<void> _loadFamilies() async {
    // Get the service BEFORE any await calls
    final supabaseService = context.read<SupabaseService>();

    setState(() => _isLoading = true);

    try {
      final memberships = await supabaseService.getAllFamiliesForCurrentUser();

      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _families = memberships;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading families: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectFamily(String familyId, String familyName) {
    final supabaseService = context.read<SupabaseService>();
    supabaseService.setSelectedFamilyId(familyId);

    // Navigate to list selection screen instead of directly to grocery list
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) =>
                ListSelectionScreen(familyId: familyId, familyName: familyName),
      ),
    );
  }

  void _createNewFamily() async {
    // Check subscription status from bloc
    final subscriptionState = context.read<SubscriptionBloc>().state;

    if (subscriptionState is SubscriptionLoaded) {
      final subscription = subscriptionState.subscription;

      // Check if user can create more lists
      if (subscription.tier == SubscriptionTier.free && _families.isNotEmpty) {
        _showUpgradeDialog();
        return;
      }
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => const FamilySetupScreen(isCreatingNew: true),
          ),
        )
        .then((_) => _loadFamilies());
  }

  void _showInviteCode(
    BuildContext context,
    String inviteCode,
    String familyName,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Invite Code for $familyName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share this code with family members:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        inviteCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invite code copied!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showUpgradeDialog() {
    final supabaseService = context.read<SupabaseService>();

    if (!_canShowSubscription) {
      showDialog(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Upgrade Required'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You\'ve reached the limit for the free plan.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('To upgrade to Pro or Family plan:'),
                  const SizedBox(height: 8),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• '),
                      Expanded(
                        child: Text('Check your email for a subscription link'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• '),
                      Expanded(
                        child: Text(
                          'Or visit our website to manage your subscription',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    try {
                      await supabaseService.sendSubscriptionEmail();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Check your email for the subscription link!',
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Send Email Link'),
                ),
              ],
            ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Upgrade Required'),
            content: const Text(
              'You\'ve reached the limit for the free plan. '
              'Upgrade to Pro or Family plan to create more lists!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  final familyId =
                      _families.isNotEmpty
                          ? (_families[0]['families']
                                  as Map<String, dynamic>)['id']
                              as String?
                          : null;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SubscriptionScreen(familyId: familyId),
                    ),
                  );
                },
                child: const Text('View Plans'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Family List'),
        actions: [
          // Show subscription tier indicator
          BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, state) {
              if (state is SubscriptionLoaded) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Chip(
                    label: Text(
                      state.subscription.tier.displayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor:
                        state.subscription.tier == SubscriptionTier.free
                            ? Colors.grey[300]
                            : Colors.green[100],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          if (_canShowSubscription)
            IconButton(
              icon: const Icon(Icons.workspace_premium),
              tooltip: 'Manage Subscription',
              onPressed: () {
                final familyId =
                    _families.isNotEmpty
                        ? (_families[0]['families']
                                as Map<String, dynamic>)['id']
                            as String?
                        : null;

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SubscriptionScreen(familyId: familyId),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _families.isEmpty
              ? _buildEmptyState()
              : _buildFamilyList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewFamily,
        icon: const Icon(Icons.add),
        label: const Text('Create New Family'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No grocery lists yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first list or join an existing one',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewFamily,
            icon: const Icon(Icons.add),
            label: const Text('Create List'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder:
                          (_) => const FamilySetupScreen(isCreatingNew: false),
                    ),
                  )
                  .then((_) => _loadFamilies());
            },
            icon: const Icon(Icons.group_add),
            label: const Text('Join Existing List'),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _families.length,
      itemBuilder: (context, index) {
        final family = _families[index];
        final familyData = family['families'] as Map<String, dynamic>;
        final memberCount = family['member_count'] as int? ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: ColorUtils.hexToColor(
                ColorUtils.getColorByIndex(index),
              ),
              child: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
            title: Text(
              familyData['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text('$memberCount member${memberCount != 1 ? 's' : ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed:
                      () => _showInviteCode(
                        context,
                        familyData['invite_code'] as String,
                        familyData['name'] as String,
                      ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            // Update the ListTile onTap in _buildFamilyList:
            onTap:
                () => _selectFamily(
                  familyData['id'] as String,
                  familyData['name'] as String,
                ),
          ),
        );
      },
    );
  }
}
