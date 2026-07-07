import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/forgot_password_sheet.dart';

/// Tela 10/10 do desktop: dados da propria conta do funcionario logado —
/// acessada pelo avatar na barra lateral, nao por um item fixo de
/// navegacao (ver docs/ARQUITETURA_GOODROADS.md, secao 7.5).
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nameController;
  TextEditingController? _phoneController;
  bool _isLoading = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _nameController ??= TextEditingController(text: user.name);
    _phoneController ??= TextEditingController(text: user.phone);

    Future<void> submit() async {
      if (!_formKey.currentState!.validate()) return;
      setState(() {
        _isLoading = true;
        _message = null;
      });

      final result = await ref.read(authControllerProvider.notifier).updateProfile(
            name: _nameController!.text.trim(),
            phone: _phoneController!.text.trim().isEmpty ? null : _phoneController!.text.trim(),
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      result.fold(
        (failure) => setState(() => _message = failure.message),
        (_) => setState(() => _message = 'Perfil atualizado com sucesso.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Perfil'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 28, child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                                    Text(
                                      user.isAdmin ? 'Administrador' : 'Funcionário',
                                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_message != null) ...[
                            Text(_message!, style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 12),
                          ],
                          AppTextField(
                            label: 'Nome',
                            controller: _nameController,
                            validator: (v) => (v == null || v.trim().length < 3) ? 'Informe o nome completo' : null,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(label: 'Telefone', controller: _phoneController, keyboardType: TextInputType.phone),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(label: 'Salvar alterações', isLoading: _isLoading, onPressed: submit),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Trocar senha'),
                    subtitle: const Text('Envia um código de redefinição para o seu e-mail'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ForgotPasswordDialog.show(context, initialEmail: user.email),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                    title: Text('Sair', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    onTap: () => ref.read(authControllerProvider.notifier).logout(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
