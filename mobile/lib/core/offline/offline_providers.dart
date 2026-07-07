import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/citizen/home/presentation/pages/recent_occurrences_provider.dart';
import '../../features/occurrences/presentation/controllers/occurrences_providers.dart';
import 'offline_database.dart';
import 'pending_occurrence.dart';
import 'sync_service.dart';

final offlineDatabaseProvider = Provider<OfflineDatabase>((ref) => OfflineDatabase());

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    database: ref.watch(offlineDatabaseProvider),
    createOccurrenceUseCase: ref.watch(createOccurrenceUseCaseProvider),
  );
});

/// Lista de ocorrencias aguardando sincronizacao — consumida pela Home
/// (banner "N ocorrência(s) pendente(s) de envio").
final pendingOccurrencesProvider = FutureProvider.autoDispose<List<PendingOccurrence>>((ref) {
  return ref.watch(offlineDatabaseProvider).listAll();
});

/// Dispara `SyncService.syncPending()` automaticamente sempre que a
/// conectividade sai de "nenhuma" para qualquer coisa (wifi/dados moveis).
/// Mantido vivo pela raiz do app (ver core/di/providers.dart / app.dart) —
/// nao e `autoDispose` de proposito, precisa continuar ouvindo o tempo
/// todo que o app estiver aberto.
final connectivitySyncControllerProvider = Provider<void>((ref) {
  final subscription = Connectivity().onConnectivityChanged.listen((results) async {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (!hasConnection) return;

    final result = await ref.read(syncServiceProvider).syncPending();
    if (result.synced > 0) {
      ref.invalidate(pendingOccurrencesProvider);
      ref.invalidate(recentOccurrencesProvider);
    }
  });

  ref.onDispose(subscription.cancel);
});
