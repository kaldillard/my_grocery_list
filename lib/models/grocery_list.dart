import 'package:equatable/equatable.dart';

class GroceryList extends Equatable {
  final String id;
  final String familyId;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroceryList({
    required this.id,
    required this.familyId,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroceryList.fromJson(Map<String, dynamic> json) {
    return GroceryList(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'name': name,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GroceryList copyWith({
    String? id,
    String? familyId,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroceryList(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    familyId,
    name,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
