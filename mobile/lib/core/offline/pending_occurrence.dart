/// Ocorrencia registrada enquanto o device estava offline (ou o envio
/// falhou por erro de rede), aguardando sincronizacao. Fica salva local via
/// `OfflineDatabase` ate `SyncService` conseguir enviar ao backend.
class PendingOccurrence {
  const PendingOccurrence({
    this.id,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.address,
    this.categoryId,
    required this.photoPaths,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  final int? id; // null antes de persistir (auto-incremento do sqflite)
  final String description;
  final double latitude;
  final double longitude;
  final String? address;
  final String? categoryId;
  final List<String> photoPaths; // caminhos persistentes (copiados do cache do image_picker)
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  PendingOccurrence copyWith({int? id, int? retryCount, String? lastError}) {
    return PendingOccurrence(
      id: id ?? this.id,
      description: description,
      latitude: latitude,
      longitude: longitude,
      address: address,
      categoryId: categoryId,
      photoPaths: photoPaths,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }
}
