import 'dart:io';
import '../../../../core/error/result.dart';
import '../entities/occurrence.dart';
import '../repositories/occurrences_repository.dart';

class CreateOccurrenceUseCase {
  const CreateOccurrenceUseCase(this._repository);
  final OccurrencesRepository _repository;

  Future<Result<Occurrence>> call({
    required String description,
    required double latitude,
    required double longitude,
    String? address,
    String? categoryId,
    required List<File> photos,
  }) {
    return _repository.create(
      description: description,
      latitude: latitude,
      longitude: longitude,
      address: address,
      categoryId: categoryId,
      photos: photos,
    );
  }
}
