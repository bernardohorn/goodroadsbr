import 'package:flutter/material.dart';

/// Exibida enquanto o app tenta restaurar a sessao (verifica token salvo +
/// confirma com o backend) antes de decidir a rota inicial. Nao conta como
/// uma das 10 telas principais — e apenas um estado transitorio de
/// bootstrap, nao uma tela de navegacao.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.add_road_rounded, color: theme.colorScheme.onPrimaryContainer, size: 36),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
