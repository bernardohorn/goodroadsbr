import 'dart:io';
import '../../features/occurrences/domain/usecases/create_occurrence_usecase.dart';
import 'offline_database.dart';

// NOTA de arquitetura: `core/` normalmente nao depende de `features/`. A
// unica excecao ja existente no projeto e `go_router_refresh_notifier.dart`
// (depende de `features/auth` para saber se ha sessao). Este arquivo segue
// o mesmo precedente: sincronizar a fila offline exige o caso de uso de
// criacao de ocorrencia, que pertence ao dominio da feature. Extrair uma
// interface para `core/` so para evitar este import seria complexidade sem
// beneficio real neste tamanho de projeto.

const _maxRetries = 5;

class SyncResult {
  const SyncResult({required this.synced, required this.failed});
  final int synced;
  final int failed;
}

/// Tenta enviar todas as ocorrencias pendentes ao backend. Chamado quando a
/// conectividade volta (ver connectivity_sync_controller.dart) e tambem
/// disponivel para disparo manual (botao "Sincronizar agora" na Home).
class SyncService {
  SyncService({required OfflineDatabase database, required CreateOccurrenceUseCase createOccurrenceUseCase})
      : _database = database,
        _createOccurrenceUseCase = createOccurrenceUseCase;

  final OfflineDatabase _database;
  final CreateOccurrenceUseCase _createOccurrenceUseCase;

  bool _isSyncing = false;

  Future<SyncResult> syncPending() async {
    if (_isSyncing) return const SyncResult(synced: 0, failed: 0);
    _isSyncing = true;

    var synced = 0;
    var failed = 0;

    try {
      final pending = await _database.listAll();
      for (final item in pending) {
        if (item.retryCount >= _maxRetries) {
          failed++;
          continue;
        }

        final photos = item.photoPaths.map(File.new).where((f) => f.existsSync()).toList();
        if (photos.isEmpty) {
          // Fotos sumiram do storage local (ex.: SO limpou o cache) — sem
          // foto obrigatoria nao ha como reenviar; remove da fila em vez
          // de tentar para sempre.
          await _database.remove(item.id!);
          continue;
        }

        final result = await _createOccurrenceUseCase(
          description: item.description,
          latitude: item.latitude,
          longitude: item.longitude,
          address: item.address,
          categoryId: item.categoryId,
          photos: photos,
        );

        await result.fold(
          (failure) async {
            failed++;
            await _database.markFailedAttempt(item.id!, error: failure.message);
          },
          (_) async {
            synced++;
            await _database.remove(item.id!);
            for (final photo in photos) {
              if (photo.existsSync()) await photo.delete();
            }
          },
        );
      }
    } finally {
      _isSyncing = false;
    }

    return SyncResult(synced: synced, failed: failed);
  }
}
