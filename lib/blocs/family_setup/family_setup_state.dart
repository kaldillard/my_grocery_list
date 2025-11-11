import 'package:equatable/equatable.dart';

abstract class FamilySetupState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FamilySetupInitial extends FamilySetupState {}

class FamilySetupLoading extends FamilySetupState {}

class FamilySetupSuccess extends FamilySetupState {
  final String familyId;
  final String inviteCode;

  FamilySetupSuccess(this.familyId, this.inviteCode);

  @override
  List<Object?> get props => [familyId, inviteCode];
}

class FamilySetupError extends FamilySetupState {
  final String message;

  FamilySetupError(this.message);

  @override
  List<Object?> get props => [message];
}
