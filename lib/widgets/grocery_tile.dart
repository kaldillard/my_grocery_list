import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/models/family_member.dart';
import 'package:my_grocery_list/models/grocery_item.dart';
import 'package:my_grocery_list/utils/color_utils.dart';

class GroceryTile extends StatefulWidget {
  const GroceryTile({super.key, required this.item, required this.familyState});

  final GroceryItem item;
  final FamilyState familyState;

  @override
  State<GroceryTile> createState() => _GroceryTileState();
}

class _GroceryTileState extends State<GroceryTile> {
  @override
  Widget build(BuildContext context) {
    final member = widget.familyState.members.firstWhere(
      (m) => m.name == widget.item.addedBy,
      orElse:
          () =>
              FamilyMember(id: '', name: widget.item.addedBy, color: '#999999'),
    );

    return Dismissible(
      key: Key(widget.item.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        context.read<GroceryBloc>().add(DeleteGroceryItem(widget.item.id));
      },
      child: ListTile(
        leading: Checkbox(
          value: widget.item.isCompleted,
          onChanged: (_) {
            context.read<GroceryBloc>().add(ToggleGroceryItem(widget.item.id));
          },
        ),
        title: Text(
          widget.item.name,
          style: TextStyle(
            decoration:
                widget.item.isCompleted ? TextDecoration.lineThrough : null,
            color: widget.item.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          'Added by ${widget.item.addedBy}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: CircleAvatar(
          backgroundColor: ColorUtils.hexToColor(member.color),
          radius: 16,
          child: Text(
            member.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
