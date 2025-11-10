import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_event.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/models/family_member.dart';
import 'package:my_grocery_list/utils/color_utils.dart';
import 'package:my_grocery_list/utils/constants.dart';
import 'package:uuid/uuid.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  FamilyBloc() : super(const FamilyState()) {
    on<LoadFamilyData>(_onLoadFamilyData);
    on<AddFamilyMember>(_onAddFamilyMember);
    on<RemoveFamilyMember>(_onRemoveFamilyMember);
    on<SelectFamilyMember>(_onSelectFamilyMember);
  }

  Future<void> _onLoadFamilyData(
    LoadFamilyData event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await Future.delayed(const Duration(milliseconds: 300));

    // Initialize with default member
    if (state.members.isEmpty) {
      final defaultMember = FamilyMember(
        id: const Uuid().v4(),
        name: 'Me',
        color: AppConstants.familyColors[0],
      );
      emit(
        FamilyState(
          members: [defaultMember],
          selectedMemberId: defaultMember.id,
          isLoading: false,
        ),
      );
    } else {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _onAddFamilyMember(AddFamilyMember event, Emitter<FamilyState> emit) {
    // Use ColorUtils.getColorByIndex instead
    final color = ColorUtils.getColorByIndex(state.members.length);

    final newMember = FamilyMember(
      id: const Uuid().v4(),
      name: event.name,
      color: color,
    );
    emit(state.copyWith(members: [...state.members, newMember]));
  }

  void _onRemoveFamilyMember(
    RemoveFamilyMember event,
    Emitter<FamilyState> emit,
  ) {
    final updatedMembers =
        state.members.where((m) => m.id != event.id).toList();
    String? newSelectedId = state.selectedMemberId;

    if (state.selectedMemberId == event.id && updatedMembers.isNotEmpty) {
      newSelectedId = updatedMembers.first.id;
    }

    emit(
      state.copyWith(members: updatedMembers, selectedMemberId: newSelectedId),
    );
  }

  void _onSelectFamilyMember(
    SelectFamilyMember event,
    Emitter<FamilyState> emit,
  ) {
    emit(state.copyWith(selectedMemberId: event.id));
  }
}
