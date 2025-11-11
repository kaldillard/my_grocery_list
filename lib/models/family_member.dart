import 'package:equatable/equatable.dart';

/// Model representing a family member
class FamilyMember extends Equatable {
  final String id;
  final String name;
  final String color;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.color,
  });

  /// Create a copy of this member with some fields replaced
  FamilyMember copyWith({String? id, String? name, String? color}) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  /// Convert this member to JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': color};
  }

  /// Create a member from JSON
  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
    );
  }

  @override
  List<Object?> get props => [id, name, color];

  @override
  String toString() {
    return 'FamilyMember(id: $id, name: $name, color: $color)';
  }
}
