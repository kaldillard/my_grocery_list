// lib/widgets/grocery_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/models/family_member.dart';
import 'package:my_grocery_list/models/grocery_item.dart';
import 'package:my_grocery_list/utils/color_utils.dart';
import 'package:my_grocery_list/widgets/edit_item_dialog.dart';

class GroceryTile extends StatefulWidget {
  const GroceryTile({super.key, required this.item, required this.familyState});

  final GroceryItem item;
  final FamilyState familyState;

  @override
  State<GroceryTile> createState() => _GroceryTileState();
}

class _GroceryTileState extends State<GroceryTile> {
  void _incrementQuantity() {
    if (widget.item.quantity < 99) {
      context.read<GroceryBloc>().add(
        UpdateGroceryItemQuantity(widget.item.id, widget.item.quantity + 1),
      );
    }
  }

  void _decrementQuantity() {
    if (widget.item.quantity > 1) {
      context.read<GroceryBloc>().add(
        UpdateGroceryItemQuantity(widget.item.id, widget.item.quantity - 1),
      );
    }
  }

  void _showEditDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditItemDialog(item: widget.item),
    );

    if (result != null && mounted) {
      context.read<GroceryBloc>().add(
        UpdateGroceryItem(
          widget.item.id,
          name: result['name'],
          category: result['category'],
          notes: result['notes'],
        ),
      );
    }
  }

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
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: _showEditDialog,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: widget.item.isCompleted,
                  onChanged: (_) {
                    context.read<GroceryBloc>().add(
                      ToggleGroceryItem(widget.item.id),
                    );
                  },
                ),

                // Category Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.item.category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.item.category.icon,
                    size: 20,
                    color: widget.item.category.color,
                  ),
                ),
                const SizedBox(width: 12),

                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: TextStyle(
                          decoration:
                              widget.item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                          color: widget.item.isCompleted ? Colors.grey : null,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Added by ${widget.item.addedBy}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (widget.item.notes != null &&
                              widget.item.notes!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.note, size: 12, color: Colors.grey[600]),
                          ],
                        ],
                      ),
                      if (widget.item.notes != null &&
                          widget.item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.item.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed:
                            widget.item.quantity > 1
                                ? _decrementQuantity
                                : null,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 24),
                        child: Text(
                          '${widget.item.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed:
                            widget.item.quantity < 99
                                ? _incrementQuantity
                                : null,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Member avatar
                CircleAvatar(
                  backgroundColor: ColorUtils.hexToColor(member.color),
                  radius: 16,
                  child: Text(
                    member.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
