// lib/widgets/add_item_input.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/widgets/add_item_dialog.dart';
import '../blocs/grocery/grocery_bloc.dart';
import '../blocs/family/family_bloc.dart';
import '../utils/constants.dart';

class AddItemInput extends StatefulWidget {
  const AddItemInput({Key? key}) : super(key: key);

  @override
  State<AddItemInput> createState() => _AddItemInputState();
}

class _AddItemInputState extends State<AddItemInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _quickAddItem(BuildContext context, String memberId) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<GroceryBloc>().add(AddGroceryItem(text, memberId));
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  void _showDetailedAddDialog(BuildContext context, String memberId) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddItemDialog(),
    );

    if (result != null && result['name'] != null) {
      if (context.mounted) {
        context.read<GroceryBloc>().add(
          AddGroceryItem(
            result['name'],
            memberId,
            quantity: result['quantity'] ?? 1,
            category: result['category'],
            notes: result['notes'],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyBloc, FamilyState>(
      builder: (context, familyState) {
        final selectedMember = familyState.selectedMember;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: selectedMember != null,
                  decoration: InputDecoration(
                    hintText: AppConstants.addItemHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon:
                        selectedMember != null
                            ? IconButton(
                              icon: const Icon(Icons.add),
                              onPressed:
                                  () =>
                                      _quickAddItem(context, selectedMember.id),
                            )
                            : const Icon(Icons.add),
                    helperText:
                        selectedMember == null
                            ? 'Select a family member first'
                            : 'Quick add or use + button for details',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    if (selectedMember != null) {
                      _quickAddItem(context, selectedMember.id);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Detailed add button
              if (selectedMember != null)
                FloatingActionButton(
                  mini: true,
                  onPressed:
                      () => _showDetailedAddDialog(context, selectedMember.id),
                  child: const Icon(Icons.add_circle_outline),
                ),
            ],
          ),
        );
      },
    );
  }
}
