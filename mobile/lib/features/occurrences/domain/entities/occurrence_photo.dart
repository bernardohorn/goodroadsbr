import 'package:equatable/equatable.dart';

class OccurrencePhoto extends Equatable {
  const OccurrencePhoto({required this.id, required this.url, this.thumbnailUrl, required this.order});

  final String id;
  final String url;
  final String? thumbnailUrl;
  final int order;

  @override
  List<Object?> get props => [id, url, thumbnailUrl, order];
}
