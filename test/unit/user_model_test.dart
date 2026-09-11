import 'package:flutter_test/flutter_test.dart';
import 'package:christian_radios_app/core/models/user.dart';

void main() {
  group('AppUser Model Tests', () {
    test('fromJson deserializes listener user correctly', () {
      final json = {
        'id': 'usr_1',
        'email': 'listener@example.com',
        'name': 'John Doe',
        'role': 'LISTENER',
        'createdAt': '2026-01-01T00:00:00Z',
      };

      final user = AppUser.fromJson(json);

      expect(user.id, equals('usr_1'));
      expect(user.email, equals('listener@example.com'));
      expect(user.name, equals('John Doe'));
      expect(user.isListener, isTrue);
      expect(user.isAdmin, isFalse);
    });

    test('roles evaluate correctly', () {
      const admin = AppUser(
        id: '1',
        email: 'admin@test.com',
        name: 'Admin',
        role: 'ADMIN',
        createdAt: '',
      );

      const owner = AppUser(
        id: '2',
        email: 'owner@test.com',
        name: 'Owner',
        role: 'OWNER',
        createdAt: '',
      );

      expect(admin.isAdmin, isTrue);
      expect(owner.isOwner, isTrue);
    });
  });
}
