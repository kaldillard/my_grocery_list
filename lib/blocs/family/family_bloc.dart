import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_event.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/models/family_member.dart';
import 'package:my_grocery_list/services/supabase_service.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final SupabaseService supabaseService;
  final String familyId;

  FamilyBloc({required this.supabaseService, required this.familyId})
    : super(const FamilyState()) {
    on<LoadFamilyData>(_onLoadFamilyData);
    on<SelectFamilyMember>(_onSelectFamilyMember);
  }

  Future<void> _onLoadFamilyData(
    LoadFamilyData event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Get all family members from Supabase
      final membersData = await supabaseService.getFamilyMembers(familyId);

      final members =
          membersData
              .map(
                (data) => FamilyMember(
                  id: data['id'],
                  name: data['display_name'],
                  color: data['color'],
                ),
              )
              .toList();

      // Get current user's member profile
      final currentMember = await supabaseService.getCurrentFamilyMember(
        familyId,
      );

      emit(
        FamilyState(
          members: members,
          selectedMemberId: currentMember?['id'],
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onSelectFamilyMember(
    SelectFamilyMember event,
    Emitter<FamilyState> emit,
  ) async {
    emit(state.copyWith(selectedMemberId: event.id));
  }
}
