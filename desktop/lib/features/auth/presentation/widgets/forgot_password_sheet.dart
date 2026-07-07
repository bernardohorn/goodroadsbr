import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../controllers/auth_providers.dart';

/// Recuperacao/troca de senha e um dialog, nao uma tela principal — usado a
/// partir do Login e da tela Perfil (ver docs/ARQUITETURA_GOODROADS.md,
/// secao 7.5).
class ForgotPasswordDialog extends ConsumerStatefulWidget {
  const ForgotPasswordDialog({super.key, this.initialEmail});

  final String? initialEmail;

  static Future<void> show(BuildContext context, {String? initialEmail}) {
    return showDialog(context: context, builder: (_) => ForgotPasswordDialog(initialEmail: initialEmail));
  }

  @override
  ConsumerState<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.initialEmail);
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await ref.read(forgotPasswordUseCaseProvider)(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => setState(() => _sent = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recuperar senha'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_sent)
                const Text('Se o e-mail informado estiver cadastrado, você receberá um código de redefinição em instantes.')
              else ...[
                const Text('Informe seu e-mail para receber as instruções de redefinição de senha.'),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'E-mail',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  validator: (value) => (value == null || !value.contains('@')) ? 'Informe um e-mail válido' : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_sent ? 'Fechar' : 'Cancelar')),
        if (!_sent) PrimaryButton(label: 'Enviar', isLoading: _isLoading, onPressed: _submit),
      ],
    );
  }
}
