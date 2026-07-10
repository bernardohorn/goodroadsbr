import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodroads_desktop/features/occurrences/domain/entities/occurrence_status_history_entry.dart';
import 'package:goodroads_desktop/features/occurrences/domain/entities/staff_occurrence.dart';
import 'package:goodroads_desktop/features/occurrences/presentation/controllers/occurrence_details_providers.dart';
import 'package:goodroads_desktop/features/occurrences/presentation/pages/occurrence_details_page.dart';

StaffOccurrence _buildOccurrence({String? citizenCpf}) {
  return StaffOccurrence(
    id: 'occ-1',
    protocolNumber: 'GR-2026-000001',
    description: 'Buraco grande na estrada',
    status: 'PENDENTE',
    priority: 'MEDIA',
    latitude: -27.1809,
    longitude: -52.0281,
    photos: const [],
    categoryName: 'Buraco',
    teamName: 'Equipe Zona Norte',
    assignedToName: 'João Funcionário',
    citizenName: 'Maria Cidadã',
    citizenCpf: citizenCpf,
    citizenEmail: 'maria@example.com',
    citizenPhone: '(45) 99999-0000',
    createdAt: DateTime(2026, 7, 8, 12, 0),
  );
}

Future<void> _pumpDetailsPage(WidgetTester tester, StaffOccurrence occurrence) async {
  // Layout desktop assume janela larga (ver desktop/CLAUDE.md); o viewport
  // padrao de teste (800x600) estoura o Row de duas colunas do card.
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        occurrenceDetailsProvider.overrideWith((ref, id) async => occurrence),
        occurrenceHistoryProvider.overrideWith((ref, id) async => const <OccurrenceStatusHistoryEntry>[]),
      ],
      child: MaterialApp(home: OccurrenceDetailsPage(occurrenceId: occurrence.id)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('card Cidadão mostra o CPF formatado quando presente', (tester) async {
    await _pumpDetailsPage(tester, _buildOccurrence(citizenCpf: '12345678900'));

    expect(find.text('CPF'), findsOneWidget);
    expect(find.text('123.456.789-00'), findsOneWidget);
  });

  testWidgets('card Cidadão mostra travessão quando cidadão não tem CPF cadastrado', (tester) async {
    await _pumpDetailsPage(tester, _buildOccurrence(citizenCpf: null));

    expect(find.text('CPF'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });
}
