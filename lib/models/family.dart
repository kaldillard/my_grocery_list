// lib/models/family.dart

import 'package:equatable/equatable.dart';

class Family extends Equatable {
  final String id;
  final String name;
  final String inviteCode;
  final DateTime createdAt;

  const Family({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, inviteCode, createdAt];
}
