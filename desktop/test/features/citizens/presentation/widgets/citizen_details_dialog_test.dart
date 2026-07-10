import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodroads_desktop/core/error/result.dart';
import 'package:goodroads_desktop/features/auth/domain/entities/staff_user.dart';
import 'package:goodroads_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:goodroads_desktop/features/citizens/domain/entities/citizen.dart';
import 'package:goodroads_desktop/features/citizens/domain/entities/paginated_citizens.dart';
import 'package:goodroads_desktop/features/citizens/domain/repositories/citizens_repository.dart';
import 'package:goodroads_desktop/features/citizens/presentation/controllers/citizens_list_controller.dart';
import 'package:goodroads_desktop/features/citizens/presentation/controllers/citizens_providers.dart';
import 'package:goodroads_desktop/features/citizens/presentation/widgets/citizen_details_dialog.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user);
  final StaffUser _user;

  @override
  Future<StaffUser?> build() async => _user;
}

class _EmptyCitizensListController extends CitizensListController {
  @override
  Future<PaginatedCitizens> build() async => const PaginatedCitizens(items: [], total: 0, page: 1, pageSize: 20);
}

class _RecordingCitizensRepository implements CitizensRepository {
  (String, bool)? calledWith;

  @override
  Future<Result<PaginatedCitizens>> list({required int page, String? search}) => throw UnimplementedError();

  @override
  Future<Result<Citizen>> updateStatus({required String id, required bool active}) async {
    calledWith = (id, active);
    return Result.success(
      Citizen(id: id, name: 'Ana Cidada', email: 'ana@example.com', active: active, createdAt: DateTime(2026, 7, 8)),
    );
  }
}

final _citizen = Citizen(
  id: 'citizen-1',
  name: 'Ana Cidada',
  email: 'ana@example.com',
  phone: '(45) 98888-0000',
  cpf: '12345678900',
  active: true,
  createdAt: DateTime(2026, 7, 8),
);

Future<_RecordingCitizensRepository> _pumpDialog(WidgetTester tester, {required bool isAdmin}) async {
  final repo = _RecordingCitizensRepository();
  final user = StaffUser(
    id: 'staff-1',
    name: isAdmin ? 'Maria Admin' : 'Joao Funcionario',
    email: 'staff@prefeitura.gov',
    role: isAdmin ? 'ADMIN' : 'FUNCIONARIO',
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(user)),
        citizensListControllerProvider.overrideWith(() => _EmptyCitizensListController()),
        citizensRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => CitizenDetailsDialog.show(context, citizen: _citizen),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('mostra os dados do cidadao formatados', (tester) async {
    await _pumpDialog(tester, isAdmin: false);

    expect(find.text('Ana Cidada'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('(45) 98888-0000'), findsOneWidget);
    expect(find.text('123.456.789-00'), findsOneWidget);
    expect(find.text('Ativo'), findsOneWidget);
  });

  testWidgets('botao Desativar conta nao aparece para FUNCIONARIO', (tester) async {
    await _pumpDialog(tester, isAdmin: false);

    expect(find.text('Desativar conta'), findsNothing);
  });

  testWidgets('ADMIN ve o botao e ele chama o use case ao ser tocado', (tester) async {
    final repo = await _pumpDialog(tester, isAdmin: true);

    expect(find.text('Desativar conta'), findsOneWidget);

    await tester.tap(find.text('Desativar conta'));
    await tester.pumpAndSettle();

    expect(repo.calledWith, ('citizen-1', false));
  });
}
