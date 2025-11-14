import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/subscription/subscription_bloc.dart';
import 'package:my_grocery_list/blocs/subscription/subscription_state.dart';
import 'package:my_grocery_list/models/subscription.dart';
import 'package:my_grocery_list/screens/grocery_list_screen.dart';
import 'package:my_grocery_list/services/supabase_service.dart';
import 'package:my_grocery_list/utils/color_utils.dart';
import 'package:my_grocery_list/blocs/family/family_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_event.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';

class ListSelectionScreen extends StatefulWidget {
  final String familyId;
  final String familyName;

  const ListSelectionScreen({
    Key? key,
    required this.familyId,
    required this.familyName,
  }) : super(key: key);

  @override
  State<ListSelectionScreen> createState() => _ListSelectionScreenState();
}

class _ListSelectionScreenState extends State<ListSelectionScreen> {
  List<Map<String, dynamic>> _lists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);

    final supabaseService = context.read<SupabaseService>();

    try {
      final lists = await supabaseService.getGroceryListsForFamily(
        widget.familyId,
      );

      setState(() {
        _lists = lists;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading lists: $e');
      setState(() => _isLoading = false);
    }
  }

  void _selectList(String listId) {
    final supabaseService = context.read<SupabaseService>();
    supabaseService.setSelectedListId(listId);

    // Navigate to grocery list screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _buildGroceryListWithBLoCs(listId)),
    );
  }

  Widget _buildGroceryListWithBLoCs(String listId) {
    final supabaseService = context.read<SupabaseService>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (context) => FamilyBloc(
                supabaseService: supabaseService,
                familyId: widget.familyId,
              )..add(LoadFamilyData()),
        ),
        BlocProvider(
          create:
              (context) =>
                  GroceryBloc(supabaseService: supabaseService, listId: listId)
                    ..add(LoadGroceryData()),
        ),
      ],
      child: const GroceryListScreen(),
    );
  }

  Future<void> _createNewList() async {
    // Check subscription status
    final subscriptionState = context.read<SubscriptionBloc>().state;

    if (subscriptionState is SubscriptionLoaded) {
      final subscription = subscriptionState.subscription;

      // Check if user can create more lists
      if (subscription.tier == SubscriptionTier.free && _lists.isNotEmpty) {
        _showUpgradeDialog();
        return;
      }
    }

    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('New List'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'List Name',
                hintText: 'e.g., Weekly Shopping',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    Navigator.pop(context, nameController.text.trim());
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      final supabaseService = context.read<SupabaseService>();

      try {
        await supabaseService.createGroceryList(
          familyId: widget.familyId,
          name: result,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('List created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadLists();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showUpgradeDialog() {
    final supabaseService = context.read<SupabaseService>();
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
                child: const Text('OK'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.familyName),
        actions: [
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
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _lists.isEmpty
              ? _buildEmptyState()
              : _buildListView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewList,
        icon: const Icon(Icons.add),
        label: const Text('New List'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No lists yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first grocery list',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewList,
            icon: const Icon(Icons.add),
            label: const Text('Create List'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lists.length,
      itemBuilder: (context, index) {
        final list = _lists[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: ColorUtils.hexToColor(
                ColorUtils.getColorByIndex(index),
              ),
              child: const Icon(Icons.shopping_basket, color: Colors.white),
            ),
            title: Text(
              list['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(
              'Created ${_formatDate(DateTime.parse(list['created_at'] as String))}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectList(list['id'] as String),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
