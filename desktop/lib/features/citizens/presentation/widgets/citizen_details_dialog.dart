import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/cpf_formatter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/citizen.dart';
import '../controllers/citizens_list_controller.dart';
import '../controllers/citizens_providers.dart';

/// Dialog somente-leitura com as informacoes de um cidadao (conta gerenciada
/// exclusivamente pelo app mobile). O unico controle de escrita disponivel
/// aqui e ativar/desativar a conta, restrito a ADMIN — mesma restricao do
/// backend (ver backend/src/modules/citizens/citizens.routes.ts).
class CitizenDetailsDialog extends ConsumerStatefulWidget {
  const CitizenDetailsDialog({super.key, required this.citizen});

  final Citizen citizen;

  static Future<void> show(BuildContext context, {required Citizen citizen}) {
    return showDialog(context: context, builder: (_) => CitizenDetailsDialog(citizen: citizen));
  }

  @override
  ConsumerState<CitizenDetailsDialog> createState() => _CitizenDetailsDialogState();
}

class _CitizenDetailsDialogState extends ConsumerState<CitizenDetailsDialog> {
  bool _isLoading = false;
  String? _error;

  Future<void> _toggleActive() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(updateCitizenStatusUseCaseProvider)(
      id: widget.citizen.id,
      active: !widget.citizen.active,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) {
        ref.read(citizensListControllerProvider.notifier).refresh();
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final citizen = widget.citizen;
    final isAdmin = ref.watch(authControllerProvider).valueOrNull?.isAdmin ?? false;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return AlertDialog(
      title: const Text('Cidadão'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 12),
            ],
            _DetailRow(label: 'Nome', value: citizen.name),
            _DetailRow(label: 'E-mail', value: citizen.email),
            _DetailRow(label: 'Telefone', value: citizen.phone ?? '—'),
            _DetailRow(label: 'CPF', value: formatCpf(citizen.cpf) ?? '—'),
            _DetailRow(label: 'Cadastrado em', value: dateFormat.format(citizen.createdAt)),
            _DetailRow(label: 'Status', value: citizen.active ? 'Ativo' : 'Inativo'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
        if (isAdmin)
          FilledButton.icon(
            onPressed: _isLoading ? null : _toggleActive,
            icon: Icon(citizen.active ? Icons.block : Icons.check_circle_outline),
            label: Text(_isLoading ? 'Aguarde...' : (citizen.active ? 'Desativar conta' : 'Reativar conta')),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
          Text(value),
        ],
      ),
    );
  }
}
