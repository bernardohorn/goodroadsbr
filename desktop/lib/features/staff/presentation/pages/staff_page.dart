import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/cpf_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../citizens/presentation/controllers/citizens_list_controller.dart';
import '../../../citizens/presentation/widgets/citizen_details_dialog.dart';
import '../../domain/entities/staff_member.dart';
import '../controllers/staff_providers.dart';
import '../widgets/staff_form_dialog.dart';

/// Tela 7/10 do desktop: gestao de usuarios do sistema. Reune tres grupos —
/// Administradores e Funcionarios (contas de staff, GET /staff) e Cidadaos
/// (contas do app mobile, GET /citizens) — ver spec
/// docs/superpowers/specs/2026-07-10-tela-usuarios-cidadaos-desktop-design.md.
/// Leitura de staff liberada para qualquer FUNCIONARIO/ADMIN; criar/editar
/// conta de staff e ativar/desativar cidadao ficam restritos a ADMIN — mesma
/// regra do backend, reforcada aqui so para UX.
class StaffPage extends ConsumerStatefulWidget {
  const StaffPage({super.key});

  @override
  ConsumerState<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends ConsumerState<StaffPage> {
  final _citizenSearchController = TextEditingController();

  @override
  void dispose() {
    _citizenSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    final isAdmin = ref.watch(authControllerProvider).valueOrNull?.isAdmin ?? false;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Usuários',
              subtitle: 'Administradores, funcionários e cidadãos cadastrados no sistema.',
              action: isAdmin
                  ? FilledButton.icon(
                      onPressed: () => StaffFormDialog.show(context),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Novo funcionário'),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            staffAsync.when(
              loading: () => const Column(children: [SkeletonRow(), SkeletonRow()]),
              error: (error, _) => Text('Não foi possível carregar a equipe: $error'),
              data: (staff) {
                final admins = staff.where((m) => m.role == 'ADMIN').toList();
                final funcionarios = staff.where((m) => m.role == 'FUNCIONARIO').toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StaffGroupSection(title: 'Administradores', members: admins, isAdmin: isAdmin),
                    const SizedBox(height: 24),
                    _StaffGroupSection(title: 'Funcionários', members: funcionarios, isAdmin: isAdmin),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Cidadãos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              width: 320,
              child: TextField(
                controller: _citizenSearchController,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por nome ou e-mail',
                ),
                onSubmitted: (value) => ref.read(citizensListControllerProvider.notifier).setSearch(value),
              ),
            ),
            const SizedBox(height: 12),
            const _CitizensSection(),
          ],
        ),
      ),
    );
  }
}

class _StaffGroupSection extends StatelessWidget {
  const _StaffGroupSection({required this.title, required this.members, required this.isAdmin});

  final String title;
  final List<StaffMember> members;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Nenhum registro.', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?')),
                  title: Text(member.name),
                  subtitle: Text('${member.email}${member.active ? '' : ' · Inativo'}'),
                  trailing: isAdmin
                      ? IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => StaffFormDialog.show(context, staff: member),
                        )
                      : null,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CitizensSection extends ConsumerWidget {
  const _CitizensSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citizensAsync = ref.watch(citizensListControllerProvider);
    final controller = ref.read(citizensListControllerProvider.notifier);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return citizensAsync.when(
      loading: () => const Column(children: [SkeletonRow(), SkeletonRow()]),
      error: (error, _) => Text('Não foi possível carregar os cidadãos: $error'),
      data: (page) {
        if (page.items.isEmpty) {
          return const EmptyState(icon: Icons.groups_outlined, title: 'Nenhum cidadão encontrado');
        }
        return Column(
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nome')),
                    DataColumn(label: Text('E-mail')),
                    DataColumn(label: Text('Telefone')),
                    DataColumn(label: Text('CPF')),
                    DataColumn(label: Text('Cadastrado em')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: [
                    for (final citizen in page.items)
                      DataRow(
                        onSelectChanged: (_) => CitizenDetailsDialog.show(context, citizen: citizen),
                        cells: [
                          DataCell(Text(citizen.name)),
                          DataCell(Text(citizen.email)),
                          DataCell(Text(citizen.phone ?? '—')),
                          DataCell(Text(formatCpf(citizen.cpf) ?? '—')),
                          DataCell(Text(dateFormat.format(citizen.createdAt))),
                          DataCell(Text(citizen.active ? 'Ativo' : 'Inativo')),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${page.total} cidadão(s) · página ${page.page} de ${page.totalPages}'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: page.page > 1 ? () => controller.setPage(page.page - 1) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: page.hasNextPage ? () => controller.setPage(page.page + 1) : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
