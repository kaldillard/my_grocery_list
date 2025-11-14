import 'package:flutter_test/flutter_test.dart';
import 'package:my_grocery_list/models/family_member.dart';

void main() {
  group('FamilyMember', () {
    test('creates member with all properties', () {
      const member = FamilyMember(id: '1', name: 'John', color: '#FF6B6B');

      expect(member.id, '1');
      expect(member.name, 'John');
      expect(member.color, '#FF6B6B');
    });

    test('copyWith creates new instance with updated values', () {
      const original = FamilyMember(id: '1', name: 'John', color: '#FF6B6B');

      final updated = original.copyWith(name: 'Jane');

      expect(updated.id, '1');
      expect(updated.name, 'Jane');
      expect(updated.color, '#FF6B6B');
    });

    test('toJson serializes correctly', () {
      const member = FamilyMember(id: '1', name: 'John', color: '#FF6B6B');

      final json = member.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'John');
      expect(json['color'], '#FF6B6B');
    });

    test('fromJson deserializes correctly', () {
      final json = {'id': '1', 'name': 'John', 'color': '#FF6B6B'};

      final member = FamilyMember.fromJson(json);

      expect(member.id, '1');
      expect(member.name, 'John');
      expect(member.color, '#FF6B6B');
    });

    test('equality works correctly', () {
      const member1 = FamilyMember(id: '1', name: 'John', color: '#FF6B6B');
      const member2 = FamilyMember(id: '1', name: 'John', color: '#FF6B6B');
      const member3 = FamilyMember(id: '2', name: 'John', color: '#FF6B6B');

      expect(member1, equals(member2));
      expect(member1, isNot(equals(member3)));
    });
  });
}
