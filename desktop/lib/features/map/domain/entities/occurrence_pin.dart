import 'package:equatable/equatable.dart';

/// Projecao leve de uma ocorrencia para exibicao no mapa — sem
/// descricao/fotos, que exigiriam buscar o detalhe completo por item.
class OccurrencePin extends Equatable {
  const OccurrencePin({
    required this.id,
    required this.protocolNumber,
    required this.status,
    required this.priority,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String protocolNumber;
  final String status;
  final String priority;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [id, protocolNumber, status, priority, latitude, longitude];
}
