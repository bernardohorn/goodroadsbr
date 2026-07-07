import '../../domain/entities/occurrence_pin.dart';

class OccurrencePinModel extends OccurrencePin {
  const OccurrencePinModel({
    required super.id,
    required super.protocolNumber,
    required super.status,
    required super.priority,
    required super.latitude,
    required super.longitude,
  });

  factory OccurrencePinModel.fromJson(Map<String, dynamic> json) {
    return OccurrencePinModel(
      id: json['id'] as String,
      protocolNumber: json['protocolNumber'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
