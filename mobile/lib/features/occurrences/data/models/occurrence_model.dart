import '../../domain/entities/occurrence.dart';
import 'occurrence_photo_model.dart';

class OccurrenceModel extends Occurrence {
  const OccurrenceModel({
    required super.id,
    required super.protocolNumber,
    required super.description,
    required super.status,
    required super.priority,
    required super.latitude,
    required super.longitude,
    super.address,
    required super.photos,
    super.categoryName,
    required super.createdAt,
    super.resolvedAt,
  });

  factory OccurrenceModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final photosJson = (json['photos'] as List<dynamic>? ?? []);

    return OccurrenceModel(
      id: json['id'] as String,
      protocolNumber: json['protocolNumber'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      photos: photosJson
          .map((photo) => OccurrencePhotoModel.fromJson(photo as Map<String, dynamic>))
          .toList(),
      categoryName: category?['name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
    );
  }
}
