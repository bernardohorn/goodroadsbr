import 'package:flutter_test/flutter_test.dart';
import 'package:goodroads_desktop/features/occurrences/data/models/staff_occurrence_model.dart';

Map<String, dynamic> _baseJson({Map<String, dynamic>? citizen}) => {
      'id': 'occ-1',
      'protocolNumber': 'GR-2026-000001',
      'description': 'Buraco grande na estrada',
      'status': 'PENDENTE',
      'priority': 'MEDIA',
      'latitude': -27.1809,
      'longitude': -52.0281,
      'photos': [],
      'createdAt': '2026-07-08T12:00:00.000Z',
      'citizen': ?citizen,
    };

void main() {
  group('StaffOccurrenceModel.fromJson — citizenCpf', () {
    test('preenche citizenCpf quando citizen.cpf esta presente', () {
      final model = StaffOccurrenceModel.fromJson(
        _baseJson(citizen: {'id': 'citizen-1', 'name': 'Maria', 'email': 'maria@example.com', 'cpf': '12345678900'}),
      );

      expect(model.citizenCpf, '12345678900');
    });

    test('citizenCpf fica nulo quando citizen.cpf esta ausente', () {
      final model = StaffOccurrenceModel.fromJson(
        _baseJson(citizen: {'id': 'citizen-1', 'name': 'Maria', 'email': 'maria@example.com'}),
      );

      expect(model.citizenCpf, isNull);
    });

    test('citizenCpf fica nulo quando nao ha citizen no payload', () {
      final model = StaffOccurrenceModel.fromJson(_baseJson());

      expect(model.citizenCpf, isNull);
    });
  });
}
