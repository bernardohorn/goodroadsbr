import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/category.dart';
import '../controllers/categories_providers.dart';

/// Dialog de criação/edição de categoria — não conta como tela nova (ver
/// docs/ARQUITETURA_GOODROADS.md, secao 7.5, sobre uso de dialogs para
/// ações pontuais dentro de uma tela principal).
class CategoryFormDialog extends ConsumerStatefulWidget {
  const CategoryFormDialog({super.key, this.category});

  final Category? category;

  static Future<void> show(BuildContext context, {Category? category}) {
    return showDialog(context: context, builder: (_) => CategoryFormDialog(category: category));
  }

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.category?.name);
  late final _colorController = TextEditingController(text: widget.category?.color ?? '#1B7A3E');
  late bool _active = widget.category?.active ?? true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final isEditing = widget.category != null;
    final result = isEditing
        ? await ref.read(updateCategoryUseCaseProvider)(
            id: widget.category!.id,
            name: _nameController.text.trim(),
            color: _colorController.text.trim(),
            active: _active,
          )
        : await ref.read(createCategoryUseCaseProvider)(
            name: _nameController.text.trim(),
            color: _colorController.text.trim(),
          );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) {
        ref.invalidate(categoriesListProvider);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    return AlertDialog(
      title: Text(isEditing ? 'Editar categoria' : 'Nova categoria'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
              AppTextField(
                label: 'Nome',
                controller: _nameController,
                validator: (v) => (v == null || v.trim().length < 2) ? 'Informe um nome válido' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Cor (hex, ex.: #1B7A3E)',
                controller: _colorController,
                validator: (v) =>
                    (v == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v.trim())) ? 'Use o formato #RRGGBB' : null,
              ),
              if (isEditing) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ativa'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
              ],
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
