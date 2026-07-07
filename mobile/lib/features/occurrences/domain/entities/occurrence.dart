import 'package:equatable/equatable.dart';
import 'occurrence_photo.dart';

class Occurrence extends Equatable {
  const Occurrence({
    required this.id,
    required this.protocolNumber,
    required this.description,
    required this.status,
    required this.priority,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.photos,
    this.categoryName,
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
  final String? categoryName;
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
        categoryName,
        createdAt,
        resolvedAt,
      ];
}
