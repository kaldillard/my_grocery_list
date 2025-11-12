// lib/screens/family_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/auth/auth_bloc.dart';
import 'package:my_grocery_list/blocs/auth/auth_event.dart';
import 'package:my_grocery_list/screens/auth_wrapper_screen.dart';
import 'package:my_grocery_list/screens/family_setup_screen.dart';
import 'package:my_grocery_list/services/supabase_service.dart';
import 'package:my_grocery_list/utils/color_utils.dart';

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({Key? key}) : super(key: key);

  @override
  State<FamilyListScreen> createState() => _FamilyListScreenState();
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
    setState(() => _isLoading = true);

    final supabaseService = context.read<SupabaseService>();

    try {
      // Get all families the user is a member of
      final memberships = await supabaseService.getAllFamiliesForCurrentUser();

      setState(() {
        _families = memberships;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading families: $e');
      setState(() => _isLoading = false);
    }
  }

  void _selectFamily(String familyId) {
    // Save the selected family
    final supabaseService = context.read<SupabaseService>();
    supabaseService.setSelectedFamilyId(familyId);

    // Navigate to grocery list with selected family
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthWrapperScreen()),
    );
  }

  void _createNewFamily() async {
    final supabaseService = context.read<SupabaseService>();
    final canCreate = await supabaseService.canCreateList(
      supabaseService.currentUser!.id,
    );

    if (!canCreate) {
      // Show upgrade dialog
      _showUpgradeDialog();
      return;
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
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Manage Subscription Required'),
            content: const Text(
              'You\'ve reached the limit for the free plan. '
              'Manage Subscription to Pro or Family plan to create more lists!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Open web browser to subscription page
                  // You can use url_launcher package
                  // launchUrl(Uri.parse('https://yourdomain.com/subscribe'));
                },
                child: const Text('Manage Subscription'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Grocery Lists'),
        actions: [
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
        label: const Text('Create New List'),
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
            onTap: () => _selectFamily(familyData['id'] as String),
          ),
        );
      },
    );
  }
}
