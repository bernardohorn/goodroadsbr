import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodroads_desktop/features/auth/domain/entities/staff_user.dart';
import 'package:goodroads_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:goodroads_desktop/features/citizens/domain/entities/citizen.dart';
import 'package:goodroads_desktop/features/citizens/domain/entities/paginated_citizens.dart';
import 'package:goodroads_desktop/features/citizens/presentation/controllers/citizens_list_controller.dart';
import 'package:goodroads_desktop/features/staff/domain/entities/staff_member.dart';
import 'package:goodroads_desktop/features/staff/presentation/controllers/staff_providers.dart';
import 'package:goodroads_desktop/features/staff/presentation/pages/staff_page.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user);
  final StaffUser _user;

  @override
  Future<StaffUser?> build() async => _user;
}

class _FakeCitizensListController extends CitizensListController {
  @override
  Future<PaginatedCitizens> build() async => PaginatedCitizens(
        items: [
          Citizen(
            id: 'citizen-1',
            name: 'Ana Cidada',
            email: 'ana@example.com',
            active: true,
            createdAt: DateTime(2026, 7, 8),
          ),
        ],
        total: 1,
        page: 1,
        pageSize: 20,
      );
}

const _admin = StaffUser(id: 'admin-1', name: 'Maria Admin', email: 'maria@prefeitura.gov', role: 'ADMIN');

const _staff = [
  StaffMember(id: 'admin-1', name: 'Maria Admin', email: 'maria@prefeitura.gov', role: 'ADMIN'),
  StaffMember(id: 'func-1', name: 'Joao Funcionario', email: 'joao@prefeitura.gov', role: 'FUNCIONARIO'),
];

Future<void> _pumpUsersPage(WidgetTester tester) async {
  // Layout desktop assume janela larga (ver desktop/CLAUDE.md); o viewport
  // padrao de teste (800x600) estoura a DataTable de cidadaos.
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(_admin)),
        staffListProvider.overrideWith((ref) async => _staff),
        citizensListControllerProvider.overrideWith(() => _FakeCitizensListController()),
      ],
      child: const MaterialApp(home: StaffPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('separa administradores, funcionarios e cidadaos em secoes', (tester) async {
    await _pumpUsersPage(tester);

    expect(find.text('Administradores'), findsOneWidget);
    expect(find.text('Funcionários'), findsOneWidget);
    expect(find.text('Cidadãos'), findsOneWidget);

    expect(find.text('Maria Admin'), findsOneWidget);
    expect(find.text('Joao Funcionario'), findsOneWidget);
    expect(find.text('Ana Cidada'), findsOneWidget);
  });
}
