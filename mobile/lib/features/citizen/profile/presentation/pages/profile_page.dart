import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../auth/presentation/widgets/forgot_password_sheet.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _editing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final result = await ref.read(authControllerProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _editing = false;
    });
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado.'))),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sair')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_editing) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 32, color: theme.colorScheme.onPrimaryContainer),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            if (_editing) ...[
              AppTextField(label: 'Nome', controller: _nameController, prefixIcon: Icons.person_outline),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Telefone',
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Salvar', isLoading: _isSaving, onPressed: _save),
            ] else ...[
              _ProfileField(label: 'Nome', value: user.name, icon: Icons.person_outline),
              _ProfileField(label: 'CPF', value: user.cpf ?? 'Não informado', icon: Icons.badge_outlined),
              _ProfileField(
                label: 'Data de nascimento',
                value: user.birthDate != null ? DateFormat('dd/MM/yyyy').format(user.birthDate!) : 'Não informado',
                icon: Icons.cake_outlined,
              ),
              _ProfileField(label: 'Telefone', value: user.phone ?? 'Não informado', icon: Icons.phone_outlined),
              _ProfileField(label: 'E-mail', value: user.email, icon: Icons.mail_outline),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline),
                title: const Text('Alterar senha'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ForgotPasswordSheet.show(context),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: Icon(Icons.logout, color: theme.colorScheme.error),
              label: Text('Sair', style: TextStyle(color: theme.colorScheme.error)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: theme.colorScheme.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.outline, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
