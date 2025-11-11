// lib/widgets/add_item_input.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import '../blocs/grocery/grocery_bloc.dart';
import '../blocs/family/family_bloc.dart';
import '../utils/constants.dart';

/// Widget for adding new grocery items
/// Displays a text field that allows users to add items to the grocery list
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

  void _addItem(BuildContext context, String memberId) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<GroceryBloc>().add(AddGroceryItem(text, memberId));
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyBloc, FamilyState>(
      builder: (context, familyState) {
        final selectedMember = familyState.selectedMember;

        return Padding(
          padding: const EdgeInsets.all(16),
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
                        onPressed: () => _addItem(context, selectedMember.name),
                      )
                      : const Icon(Icons.add),
              helperText:
                  selectedMember == null
                      ? 'Select a family member first'
                      : null,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              if (selectedMember != null) {
                _addItem(context, selectedMember.name);
              }
            },
          ),
        );
      },
    );
  }
}
