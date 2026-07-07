import 'package:equatable/equatable.dart';
import 'occurrence_photo.dart';

/// Visao da ocorrencia sob a otica da prefeitura — mais rica que a do
/// cidadao (mobile): inclui equipe, responsavel, dados do cidadao e
/// observacoes internas, todos ja retornados pelo backend em
/// GET /occurrences[/:id] para papeis FUNCIONARIO/ADMIN.
class StaffOccurrence extends Equatable {
  const StaffOccurrence({
    required this.id,
    required this.protocolNumber,
    required this.description,
    required this.status,
    required this.priority,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.photos,
    this.categoryId,
    this.categoryName,
    this.teamId,
    this.teamName,
    this.assignedToId,
    this.assignedToName,
    this.citizenName,
    this.citizenEmail,
    this.citizenPhone,
    this.internalNotes,
    required this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String protocolNumber;
  final String description;
  final String status;
  final String priority;
  final double latitude;
  final double longitude;
  final String? address;
  final List<OccurrencePhoto> photos;
  final String? categoryId;
  final String? categoryName;
  final String? teamId;
  final String? teamName;
  final String? assignedToId;
  final String? assignedToName;
  final String? citizenName;
  final String? citizenEmail;
  final String? citizenPhone;
  final String? internalNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  String get coverPhotoUrl => photos.isNotEmpty ? photos.first.url : '';

  @override
  List<Object?> get props => [
        id,
        protocolNumber,
        description,
        status,
        priority,
        latitude,
        longitude,
        address,
        photos,
        categoryId,
        categoryName,
        teamId,
        teamName,
        assignedToId,
        assignedToName,
        citizenName,
        citizenEmail,
        citizenPhone,
        internalNotes,
        createdAt,
        resolvedAt,
      ];
}
