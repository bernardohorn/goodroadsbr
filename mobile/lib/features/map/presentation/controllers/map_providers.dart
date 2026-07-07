import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/map/map_provider_contract.dart';
import '../../../../core/map/osm_map_provider.dart';
import '../../data/datasources/map_remote_data_source.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/usecases/find_occurrences_in_bounding_box_usecase.dart';

final mapProviderContractProvider = Provider<MapProviderContract>((ref) => OsmMapProvider());

final mapRemoteDataSourceProvider = Provider((ref) => MapRemoteDataSource(ref.watch(dioProvider)));

final mapRepositoryProvider = Provider<MapRepository>((ref) => MapRepositoryImpl(ref.watch(mapRemoteDataSourceProvider)));

final findOccurrencesInBoundingBoxUseCaseProvider =
    Provider((ref) => FindOccurrencesInBoundingBoxUseCase(ref.watch(mapRepositoryProvider)));
