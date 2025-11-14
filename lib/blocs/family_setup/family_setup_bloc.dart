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
    print('Creating family: ${event.familyName}');
    print('Member name: ${event.memberName}');
    print('Current user: ${supabaseService.currentUser?.id}');

    try {
      final family = await supabaseService.createFamily(event.familyName);
      print('Family created: $family');

      if (family != null) {
        print('Adding family member...');
        await supabaseService.addFamilyMember(
          familyId: family['id'],
          displayName: event.memberName,
          color: event.color,
        );
        print('Member added successfully');
        emit(FamilySetupSuccess(family['id'], family['invite_code']));
      } else {
        print('Family creation returned null');
        emit(FamilySetupError('Failed to create family'));
      }
    } catch (e) {
      print('Error creating family: $e');
      print('Error type: ${e.runtimeType}');
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
      print(e.toString());
      emit(FamilySetupError(e.toString()));
    }
  }
}
