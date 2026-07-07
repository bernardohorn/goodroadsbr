import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../controllers/auth_providers.dart';

/// Recuperacao de senha e um bottom sheet a partir do Login, nao uma tela
/// principal (ver docs/ARQUITETURA_GOODROADS.md, secao 7.4 — o app mobile
/// tem exatamente 8 telas principais).
class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const Padding(
        padding: EdgeInsets.only(bottom: 24),
        child: ForgotPasswordSheet(),
      ),
    );
  }

  @override
  ConsumerState<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
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
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
            ),
            Text('Recuperar senha', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_sent)
              const Text('Se o e-mail informado estiver cadastrado, você receberá as instruções em instantes.')
            else ...[
              const Text('Informe o e-mail cadastrado para receber as instruções de redefinição.'),
              const SizedBox(height: 16),
              AppTextField(
                label: 'E-mail',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline,
                validator: (value) =>
                    (value == null || !value.contains('@')) ? 'Informe um e-mail válido' : null,
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Enviar', isLoading: _isLoading, onPressed: _submit),
            ],
          ],
        ),
      ),
    );
  }
}
