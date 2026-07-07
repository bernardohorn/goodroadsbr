import '../../domain/entities/staff_occurrence.dart';
import 'occurrence_photo_model.dart';

class StaffOccurrenceModel extends StaffOccurrence {
  const StaffOccurrenceModel({
    required super.id,
    required super.protocolNumber,
    required super.description,
    required super.status,
    required super.priority,
    required super.latitude,
    required super.longitude,
    super.address,
    required super.photos,
    super.categoryId,
    super.categoryName,
    super.teamId,
    super.teamName,
    super.assignedToId,
    super.assignedToName,
    super.citizenName,
    super.citizenEmail,
    super.citizenPhone,
    super.internalNotes,
    required super.createdAt,
    super.resolvedAt,
  });

  factory StaffOccurrenceModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final team = json['team'] as Map<String, dynamic>?;
    final assignedTo = json['assignedTo'] as Map<String, dynamic>?;
    final citizen = json['citizen'] as Map<String, dynamic>?;
    final photosJson = (json['photos'] as List<dynamic>? ?? []);

    return StaffOccurrenceModel(
      id: json['id'] as String,
      protocolNumber: json['protocolNumber'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      photos: photosJson.map((p) => OccurrencePhotoModel.fromJson(p as Map<String, dynamic>)).toList(),
      categoryId: category?['id'] as String?,
      categoryName: category?['name'] as String?,
      teamId: team?['id'] as String?,
      teamName: team?['name'] as String?,
      assignedToId: assignedTo?['id'] as String?,
      assignedToName: assignedTo?['name'] as String?,
      citizenName: citizen?['name'] as String?,
      citizenEmail: citizen?['email'] as String?,
      citizenPhone: citizen?['phone'] as String?,
      internalNotes: json['internalNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
    );
  }
}
