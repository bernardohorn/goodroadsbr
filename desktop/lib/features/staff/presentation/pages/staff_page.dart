import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/staff_providers.dart';
import '../widgets/staff_form_dialog.dart';

/// Tela 7/10 do desktop: gestão de funcionários. Leitura liberada para
/// qualquer FUNCIONARIO/ADMIN (necessária para o dialog de atribuição de
/// ocorrências); criar/editar contas fica restrito a ADMIN — mesma regra do
/// backend (ver backend/src/modules/staff/staff.routes.ts), reforçada aqui
/// apenas para melhor UX (o backend e quem garante a seguranca real).
class StaffPage extends ConsumerWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);
    final isAdmin = ref.watch(authControllerProvider).valueOrNull?.isAdmin ?? false;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Usuários',
              subtitle: 'Funcionários e administradores com acesso ao painel.',
              action: isAdmin
                  ? FilledButton.icon(
                      onPressed: () => StaffFormDialog.show(context),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Novo funcionário'),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: staffAsync.when(
                loading: () => const Column(children: [SkeletonRow(), SkeletonRow(), SkeletonRow()]),
                error: (error, _) => Center(child: Text('Não foi possível carregar os usuários: $error')),
                data: (staff) {
                  if (staff.isEmpty) {
                    return const EmptyState(icon: Icons.groups_outlined, title: 'Nenhum funcionário cadastrado');
                  }
                  return Card(
                    child: ListView.separated(
                      itemCount: staff.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final member = staff[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?')),
                          title: Text(member.name),
                          subtitle: Text('${member.email}${member.active ? '' : ' · Inativo'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(label: Text(member.role == 'ADMIN' ? 'Administrador' : 'Funcionário')),
                              if (isAdmin) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => StaffFormDialog.show(context, staff: member),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
