import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/family_setup/family_setup_event.dart';
import 'package:my_grocery_list/blocs/family_setup/family_setup_state.dart';
import 'package:my_grocery_list/services/supabase_service.dart';

class FamilySetupBloc extends Bloc<FamilySetupEvent, FamilySetupState> {
  final SupabaseService supabaseService;

  FamilySetupBloc({required this.supabaseService})
    : super(FamilySetupInitial()) {
    on<CreateFamily>(_onCreateFamily);
    on<JoinFamily>(_onJoinFamily);
  }

  Future<void> _onCreateFamily(
    CreateFamily event,
    Emitter<FamilySetupState> emit,
  ) async {
    emit(FamilySetupLoading());
    try {
      final family = await supabaseService.createFamily(event.familyName);
      if (family != null) {
        await supabaseService.addFamilyMember(
          familyId: family['id'],
          displayName: event.memberName,
          color: event.color,
        );
        emit(FamilySetupSuccess(family['id'], family['invite_code']));
      } else {
        emit(FamilySetupError('Failed to create family'));
      }
    } catch (e) {
      emit(FamilySetupError(e.toString()));
    }
  }

  Future<void> _onJoinFamily(
    JoinFamily event,
    Emitter<FamilySetupState> emit,
  ) async {
    emit(FamilySetupLoading());
    try {
      final family = await supabaseService.joinFamilyByCode(event.inviteCode);
      if (family != null) {
        await supabaseService.addFamilyMember(
          familyId: family['id'],
          displayName: event.memberName,
          color: event.color,
        );
        emit(FamilySetupSuccess(family['id'], family['invite_code']));
      } else {
        emit(FamilySetupError('Invalid invite code'));
      }
    } catch (e) {
      emit(FamilySetupError(e.toString()));
    }
  }
}
