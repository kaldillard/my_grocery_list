import 'package:equatable/equatable.dart';
import 'package:my_grocery_list/models/family_member.dart';

class FamilyState extends Equatable {
  final List<FamilyMember> members;
  final String? selectedMemberId;
  final bool isLoading;

  const FamilyState({
    this.members = const [],
    this.selectedMemberId,
    this.isLoading = false,
  });

  FamilyState copyWith({
    List<FamilyMember>? members,
    String? selectedMemberId,
    bool? isLoading,
  }) {
    return FamilyState(
      members: members ?? this.members,
      selectedMemberId: selectedMemberId ?? this.selectedMemberId,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  FamilyMember? get selectedMember {
    if (selectedMemberId == null) return null;
    try {
      return members.firstWhere((m) => m.id == selectedMemberId);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [members, selectedMemberId, isLoading];
}
