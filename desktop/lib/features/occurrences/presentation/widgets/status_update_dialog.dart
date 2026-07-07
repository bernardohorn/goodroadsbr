import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../controllers/occurrence_details_providers.dart';
import '../controllers/occurrences_list_controller.dart';
import '../controllers/occurrences_providers.dart';

/// Espelha `ALLOWED_STATUS_TRANSITIONS` do backend
/// (backend/src/config/constants.ts) so para nao oferecer opcoes invalidas
/// na UI — a validacao real (fonte da verdade) continua no servidor.
const _allowedTransitions = <String, List<String>>{
  'PENDENTE': ['EM_ANDAMENTO', 'CANCELADA'],
  'EM_ANDAMENTO': ['RESOLVIDA', 'CANCELADA', 'PENDENTE'],
  'RESOLVIDA': [],
  'CANCELADA': [],
};

const _statusLabels = {
  'PENDENTE': 'Pendente',
  'EM_ANDAMENTO': 'Em andamento',
  'RESOLVIDA': 'Resolvida',
  'CANCELADA': 'Cancelada',
};

class StatusUpdateDialog extends ConsumerStatefulWidget {
  const StatusUpdateDialog({super.key, required this.occurrenceId, required this.currentStatus});

  final String occurrenceId;
  final String currentStatus;

  static Future<void> show(BuildContext context, {required String occurrenceId, required String currentStatus}) {
    return showDialog(
      context: context,
      builder: (_) => StatusUpdateDialog(occurrenceId: occurrenceId, currentStatus: currentStatus),
    );
  }

  @override
  ConsumerState<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends ConsumerState<StatusUpdateDialog> {
  String? _newStatus;
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newStatus == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(updateStatusUseCaseProvider)(
      id: widget.occurrenceId,
      status: _newStatus!,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) {
        ref.invalidate(occurrenceDetailsProvider(widget.occurrenceId));
        ref.invalidate(occurrenceHistoryProvider(widget.occurrenceId));
        ref.read(occurrencesListControllerProvider.notifier).refresh();
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = _allowedTransitions[widget.currentStatus] ?? [];
    return AlertDialog(
      title: const Text('Atualizar status'),
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
            if (options.isEmpty)
              Text('"${_statusLabels[widget.currentStatus]}" é um estado final e não pode mais ser alterado.')
            else ...[
              Text('Status atual: ${_statusLabels[widget.currentStatus]}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _newStatus,
                decoration: const InputDecoration(labelText: 'Novo status'),
                items: [for (final s in options) DropdownMenuItem(value: s, child: Text(_statusLabels[s] ?? s))],
                onChanged: (value) => setState(() => _newStatus = value),
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Observação (opcional)', controller: _noteController, maxLines: 3),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        if (options.isNotEmpty)
          PrimaryButton(label: 'Confirmar', isLoading: _isLoading, onPressed: _newStatus == null ? null : _submit),
      ],
    );
  }
}
