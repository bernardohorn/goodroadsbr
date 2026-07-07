import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../categories/presentation/controllers/categories_providers.dart';
import '../../../staff/presentation/controllers/staff_providers.dart';
import '../../../teams/presentation/teams_providers.dart';
import '../../domain/entities/staff_occurrence.dart';
import '../controllers/occurrence_details_providers.dart';
import '../controllers/occurrences_list_controller.dart';
import '../controllers/occurrences_providers.dart';

const _priorityLabels = {'BAIXA': 'Baixa', 'MEDIA': 'Média', 'ALTA': 'Alta', 'URGENTE': 'Urgente'};

/// Dialog de atribuição/triagem: categoria, prioridade, equipe, responsável
/// e observações internas — todos editáveis num unico lugar (evita criar
/// telas extras so para isso, ver docs/ARQUITETURA_GOODROADS.md, secao 7.5).
class AssignDialog extends ConsumerStatefulWidget {
  const AssignDialog({super.key, required this.occurrence});

  final StaffOccurrence occurrence;

  static Future<void> show(BuildContext context, {required StaffOccurrence occurrence}) {
    return showDialog(context: context, builder: (_) => AssignDialog(occurrence: occurrence));
  }

  @override
  ConsumerState<AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<AssignDialog> {
  late String? _categoryId = widget.occurrence.categoryId;
  late String _priority = widget.occurrence.priority;
  late String? _teamId = widget.occurrence.teamId;
  late String? _assignedToId = widget.occurrence.assignedToId;
  late final _notesController = TextEditingController(text: widget.occurrence.internalNotes);
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(updateOccurrenceDetailsUseCaseProvider)(
      id: widget.occurrence.id,
      categoryId: _categoryId,
      priority: _priority,
      teamId: _teamId,
      assignedToId: _assignedToId,
      internalNotes: _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) {
        ref.invalidate(occurrenceDetailsProvider(widget.occurrence.id));
        ref.read(occurrencesListControllerProvider.notifier).refresh();
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final teamsAsync = ref.watch(teamsListProvider);
    final staffAsync = ref.watch(staffListProvider);

    return AlertDialog(
      title: const Text('Atribuir e classificar'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Não foi possível carregar categorias.'),
                data: (categories) => DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: [for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: [
                  for (final entry in _priorityLabels.entries)
                    DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                ],
                onChanged: (value) => setState(() => _priority = value ?? _priority),
              ),
              const SizedBox(height: 16),
              teamsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Não foi possível carregar equipes.'),
                data: (teams) => DropdownButtonFormField<String>(
                  initialValue: _teamId,
                  decoration: const InputDecoration(labelText: 'Equipe'),
                  items: [for (final t in teams) DropdownMenuItem(value: t.id, child: Text(t.name))],
                  onChanged: (value) => setState(() => _teamId = value),
                ),
              ),
              const SizedBox(height: 16),
              staffAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Não foi possível carregar funcionários.'),
                data: (staff) => DropdownButtonFormField<String>(
                  initialValue: _assignedToId,
                  decoration: const InputDecoration(labelText: 'Atribuído a'),
                  items: [for (final s in staff) DropdownMenuItem(value: s.id, child: Text(s.name))],
                  onChanged: (value) => setState(() => _assignedToId = value),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Observações internas', controller: _notesController, maxLines: 4),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        PrimaryButton(label: 'Salvar', isLoading: _isLoading, onPressed: _submit),
      ],
    );
  }
}
