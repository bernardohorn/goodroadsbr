import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/staff_member.dart';
import '../controllers/staff_providers.dart';

/// Dialog de criação/edição de conta de funcionário — so aparece para
/// ADMIN (unico papel autorizado pelo backend a criar/editar contas, ver
/// backend/src/modules/staff/staff.routes.ts).
class StaffFormDialog extends ConsumerStatefulWidget {
  const StaffFormDialog({super.key, this.staff});

  final StaffMember? staff;

  static Future<void> show(BuildContext context, {StaffMember? staff}) {
    return showDialog(context: context, builder: (_) => StaffFormDialog(staff: staff));
  }

  @override
  ConsumerState<StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends ConsumerState<StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.staff?.name);
  late final _emailController = TextEditingController(text: widget.staff?.email);
  late final _phoneController = TextEditingController(text: widget.staff?.phone);
  final _passwordController = TextEditingController();
  late String _role = widget.staff?.role ?? 'FUNCIONARIO';
  late bool _active = widget.staff?.active ?? true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final isEditing = widget.staff != null;
    final result = isEditing
        ? await ref.read(updateStaffUseCaseProvider)(
            id: widget.staff!.id,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            role: _role,
            active: _active,
          )
        : await ref.read(createStaffUseCaseProvider)(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _role,
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) {
        ref.invalidate(staffListProvider);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.staff != null;
    return AlertDialog(
      title: Text(isEditing ? 'Editar funcionário' : 'Novo funcionário'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  label: 'Nome',
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Informe o nome completo' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'E-mail',
                  controller: _emailController,
                  enabled: !isEditing,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(label: 'Telefone (opcional)', controller: _phoneController, keyboardType: TextInputType.phone),
                if (!isEditing) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Senha provisória',
                    controller: _passwordController,
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 8) ? 'Mínimo de 8 caracteres' : null,
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Papel'),
                  items: const [
                    DropdownMenuItem(value: 'FUNCIONARIO', child: Text('Funcionário')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                  ],
                  onChanged: (value) => setState(() => _role = value ?? 'FUNCIONARIO'),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Conta ativa'),
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                  ),
                ],
              ],
            ),
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
