import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_event.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/utils/color_utils.dart';

class FamilySelector extends StatefulWidget {
  const FamilySelector({super.key});

  @override
  State<FamilySelector> createState() => _FamilySelectorState();
}

class _FamilySelectorState extends State<FamilySelector> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyBloc, FamilyState>(
      builder: (context, state) {
        if (state.members.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shopping as:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    state.members.map((member) {
                      final isSelected = member.id == state.selectedMemberId;
                      return ChoiceChip(
                        label: Text(member.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            context.read<FamilyBloc>().add(
                              SelectFamilyMember(member.id),
                            );
                          }
                        },
                        avatar: CircleAvatar(
                          backgroundColor: ColorUtils.hexToColor(member.color),
                          radius: 12,
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
