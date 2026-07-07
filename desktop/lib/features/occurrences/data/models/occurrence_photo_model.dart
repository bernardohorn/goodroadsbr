import '../../domain/entities/occurrence_photo.dart';

class OccurrencePhotoModel extends OccurrencePhoto {
  const OccurrencePhotoModel({required super.id, required super.url, super.thumbnailUrl, required super.order});

  factory OccurrencePhotoModel.fromJson(Map<String, dynamic> json) {
    return OccurrencePhotoModel(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }
}
