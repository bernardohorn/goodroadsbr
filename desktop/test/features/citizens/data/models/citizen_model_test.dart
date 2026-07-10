import 'package:flutter_test/flutter_test.dart';
import 'package:goodroads_desktop/features/citizens/data/models/citizen_model.dart';

void main() {
  group('CitizenModel.fromJson', () {
    test('parseia todos os campos presentes', () {
      final model = CitizenModel.fromJson({
        'id': 'citizen-1',
        'name': 'Maria Cidada',
        'email': 'maria@example.com',
        'phone': '(45) 99999-0000',
        'cpf': '12345678900',
        'avatarUrl': null,
        'active': true,
        'createdAt': '2026-07-08T12:00:00.000Z',
      });

      expect(model.id, 'citizen-1');
      expect(model.name, 'Maria Cidada');
      expect(model.email, 'maria@example.com');
      expect(model.phone, '(45) 99999-0000');
      expect(model.cpf, '12345678900');
      expect(model.active, true);
      expect(model.createdAt, DateTime.parse('2026-07-08T12:00:00.000Z'));
    });

    test('phone e cpf ficam nulos quando ausentes, active assume true por padrao', () {
      final model = CitizenModel.fromJson({
        'id': 'citizen-2',
        'name': 'Ana',
        'email': 'ana@example.com',
        'createdAt': '2026-07-08T12:00:00.000Z',
      });

      expect(model.phone, isNull);
      expect(model.cpf, isNull);
      expect(model.active, true);
    });
  });
}
