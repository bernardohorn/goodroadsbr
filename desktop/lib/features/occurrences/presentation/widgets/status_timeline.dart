import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Trilha horizontal de status (Pendente -> Em andamento -> Resolvido),
/// usada na tela de Detalhes. Ocorrencias canceladas ganham uma
/// representacao propria, ja que "cancelada" nao faz parte da progressao
/// linear normal.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.currentStatus});

  final String currentStatus;

  static const _order = ['PENDENTE', 'EM_ANDAMENTO', 'RESOLVIDA'];
  static const _labels = {'PENDENTE': 'Pendente', 'EM_ANDAMENTO': 'Em andamento', 'RESOLVIDA': 'Resolvido'};

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'CANCELADA') {
      return Row(
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.statusCancelada),
          const SizedBox(width: 8),
          Text('Ocorrência cancelada', style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }

    final currentIndex = _order.indexOf(currentStatus).clamp(0, _order.length - 1);

    return Row(
      children: [
        for (var i = 0; i < _order.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Icon(
                  i <= currentIndex ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: i <= currentIndex ? AppColors.statusResolvida : Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 4),
                Text(_labels[_order[i]]!, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
              ],
            ),
          ),
          if (i < _order.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: i < currentIndex ? AppColors.statusResolvida : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
        ],
      ],
    );
  }
}
