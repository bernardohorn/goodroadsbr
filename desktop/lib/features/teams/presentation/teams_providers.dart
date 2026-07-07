import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../data/datasources/teams_remote_data_source.dart';
import '../data/models/team_model.dart';

final teamsRemoteDataSourceProvider = Provider((ref) => TeamsRemoteDataSource(ref.watch(dioProvider)));

final teamsListProvider = FutureProvider.autoDispose<List<TeamModel>>((ref) {
  return ref.watch(teamsRemoteDataSourceProvider).list();
});
