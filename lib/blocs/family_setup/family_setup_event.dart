import 'package:equatable/equatable.dart';

abstract class FamilySetupEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CreateFamily extends FamilySetupEvent {
  final String familyName;
  final String memberName;
  final String color;

  CreateFamily(this.familyName, this.memberName, this.color);

  @override
  List<Object?> get props => [familyName, memberName, color];
}

class JoinFamily extends FamilySetupEvent {
  final String inviteCode;
  final String memberName;
  final String color;

  JoinFamily(this.inviteCode, this.memberName, this.color);

  @override
  List<Object?> get props => [inviteCode, memberName, color];
}
