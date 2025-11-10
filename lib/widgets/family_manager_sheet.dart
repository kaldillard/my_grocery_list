import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_event.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/utils/color_utils.dart';

class FamilyManagerSheet extends StatefulWidget {
  const FamilyManagerSheet({super.key});

  @override
  State<FamilyManagerSheet> createState() => _FamilyManagerSheetState();
}

class _FamilyManagerSheetState extends State<FamilyManagerSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Family Members',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            BlocBuilder<FamilyBloc, FamilyState>(
              builder: (context, state) {
                return Column(
                  children:
                      state.members.map((member) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: ColorUtils.hexToColor(
                              member.color,
                            ),
                            child: Text(
                              member.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(member.name),
                          trailing:
                              state.members.length > 1
                                  ? IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      context.read<FamilyBloc>().add(
                                        RemoveFamilyMember(member.id),
                                      );
                                    },
                                  )
                                  : null,
                        );
                      }).toList(),
                );
              },
            ),
            const Divider(),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Add family member...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  context.read<FamilyBloc>().add(AddFamilyMember(value.trim()));
                  _controller.clear();
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    context.read<FamilyBloc>().add(
                      AddFamilyMember(_controller.text.trim()),
                    );
                    _controller.clear();
                  }
                },
                child: const Text('Add Member'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
