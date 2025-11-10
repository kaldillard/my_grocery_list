import 'package:equatable/equatable.dart';

abstract class FamilyEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFamilyData extends FamilyEvent {}

class AddFamilyMember extends FamilyEvent {
  final String name;

  AddFamilyMember(this.name);

  @override
  List<Object?> get props => [name];
}

class RemoveFamilyMember extends FamilyEvent {
  final String id;

  RemoveFamilyMember(this.id);

  @override
  List<Object?> get props => [id];
}

class SelectFamilyMember extends FamilyEvent {
  final String id;

  SelectFamilyMember(this.id);

  @override
  List<Object?> get props => [id];
}
