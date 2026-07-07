import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Badge de status de ocorrencia, com cor consistente em toda a
/// aplicacao. Aceita o valor bruto do backend (`PENDENTE`, `EM_ANDAMENTO`,
/// `RESOLVIDA`, `CANCELADA`) para nao exigir mapeamento nas telas.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  ({Color color, String label}) get _config => switch (status) {
        'PENDENTE' => (color: AppColors.statusPendente, label: 'Pendente'),
        'EM_ANDAMENTO' => (color: AppColors.statusEmAndamento, label: 'Em andamento'),
        'RESOLVIDA' => (color: AppColors.statusResolvida, label: 'Resolvida'),
        'CANCELADA' => (color: AppColors.statusCancelada, label: 'Cancelada'),
        _ => (color: AppColors.statusCancelada, label: status),
      };

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: config.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(config.label, style: TextStyle(color: config.color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

/// Badge de prioridade da ocorrencia (`BAIXA`, `MEDIA`, `ALTA`, `URGENTE`) —
/// so existe no desktop, ja que o cidadao nao define/ve prioridade.
class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.priority});

  final String priority;

  ({Color color, String label}) get _config => switch (priority) {
        'BAIXA' => (color: AppColors.priorityBaixa, label: 'Baixa'),
        'MEDIA' => (color: AppColors.priorityMedia, label: 'Media'),
        'ALTA' => (color: AppColors.priorityAlta, label: 'Alta'),
        'URGENTE' => (color: AppColors.priorityUrgente, label: 'Urgente'),
        _ => (color: AppColors.priorityBaixa, label: priority),
      };

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: config.color), borderRadius: BorderRadius.circular(20)),
      child: Text(config.label, style: TextStyle(color: config.color, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}
