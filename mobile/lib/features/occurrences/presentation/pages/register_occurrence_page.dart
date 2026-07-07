import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../../core/offline/pending_occurrence.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../citizen/home/presentation/pages/recent_occurrences_provider.dart';
import '../../../map/presentation/controllers/map_providers.dart';
import '../controllers/categories_provider.dart';
import '../controllers/occurrences_providers.dart';
import '../widgets/photo_compressor.dart';

const _maxPhotos = 5;
const _steps = ['Localização', 'Descrição', 'Foto', 'Enviar'];

/// Registro de ocorrência em um unico fluxo de 4 passos (nao 4 telas —
/// ver docs/ARQUITETURA_GOODROADS.md, secao 7.4), com estado preservado ao
/// navegar entre os passos.
class RegisterOccurrencePage extends ConsumerStatefulWidget {
  const RegisterOccurrencePage({super.key});

  @override
  ConsumerState<RegisterOccurrencePage> createState() => _RegisterOccurrencePageState();
}

class _RegisterOccurrencePageState extends ConsumerState<RegisterOccurrencePage> {
  int _step = 0;
  final _mapController = MapController();
  final _descriptionController = TextEditingController();

  LatLng? _pickedLocation;
  String? _address;
  bool _isLocating = true;
  String? _selectedCategoryId;
  final List<File> _photos = [];
  bool _isCompressing = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectLocation());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await ref.read(mapProviderContractProvider).currentPosition();
      if (!mounted) return;
      setState(() => _pickedLocation = position);
      _mapController.move(position, 17);
      _reverseGeocode(position);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível obter sua localização. Ajuste manualmente no mapa.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final address = await ref.read(mapProviderContractProvider).reverseGeocode(point);
      if (mounted) setState(() => _address = address);
    } catch (_) {
      // Endereco e apenas informativo — segue sem ele se a geocodificacao falhar.
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_photos.length >= _maxPhotos) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() => _isCompressing = true);
    final compressed = await compressImageFile(picked.path);
    if (!mounted) return;
    setState(() {
      _photos.add(compressed);
      _isCompressing = false;
    });
  }

  bool get _canGoNext => switch (_step) {
        0 => _pickedLocation != null,
        1 => _descriptionController.text.trim().length >= 10,
        2 => _photos.isNotEmpty,
        _ => true,
      };

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final result = await ref.read(createOccurrenceUseCaseProvider)(
      description: _descriptionController.text.trim(),
      latitude: _pickedLocation!.latitude,
      longitude: _pickedLocation!.longitude,
      address: _address,
      categoryId: _selectedCategoryId,
      photos: _photos,
    );

    if (!mounted) return;

    await result.fold(
      (failure) async {
        // Sem conexao: em vez de so mostrar um erro e perder o que o
        // cidadao preencheu, a ocorrencia e salva localmente e
        // sincronizada automaticamente quando a rede voltar (ver
        // core/offline/ — Etapa 5, "sincronizacao offline" do roadmap).
        // Outros tipos de erro (validacao, servidor) continuam sendo
        // mostrados normalmente, pois reenviar sozinho nao resolveria.
        if (failure is NetworkFailure) {
          await _queueOffline();
        } else if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
        }
      },
      (occurrence) async {
        setState(() => _isSubmitting = false);
        ref.invalidate(recentOccurrencesProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocorrência ${occurrence.protocolNumber} registrada com sucesso!')),
        );
        context.go(AppRoutes.home);
      },
    );
  }

  /// Copia as fotos do cache temporario do `image_picker` para um diretorio
  /// persistente do app antes de enfileirar — o cache pode ser limpo pelo
  /// SO a qualquer momento, o que faria a sincronizacao falhar mais tarde.
  Future<void> _queueOffline() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final pendingDir = Directory(p.join(documentsDir.path, 'pending_occurrence_photos'));
      if (!pendingDir.existsSync()) pendingDir.createSync(recursive: true);

      final persistedPaths = <String>[];
      for (final photo in _photos) {
        final destination = p.join(pendingDir.path, '${DateTime.now().microsecondsSinceEpoch}_${p.basename(photo.path)}');
        await photo.copy(destination);
        persistedPaths.add(destination);
      }

      await ref.read(offlineDatabaseProvider).insert(
            PendingOccurrence(
              description: _descriptionController.text.trim(),
              latitude: _pickedLocation!.latitude,
              longitude: _pickedLocation!.longitude,
              address: _address,
              categoryId: _selectedCategoryId,
              photoPaths: persistedPaths,
              createdAt: DateTime.now(),
            ),
          );

      ref.invalidate(pendingOccurrencesProvider);

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sem conexão — sua ocorrência foi salva e será enviada automaticamente quando a internet voltar.'),
        ),
      );
      context.go(AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a ocorrência localmente. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar ocorrência'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _step == 0 ? context.pop() : setState(() => _step--),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepIndicator(currentStep: _step),
            Expanded(
              child: switch (_step) {
                0 => _LocationStep(
                    mapController: _mapController,
                    isLocating: _isLocating,
                    address: _address,
                    onRecenter: _detectLocation,
                    onMapEvent: (camera) => _pickedLocation = camera,
                    onMapEventEnd: () => _pickedLocation != null ? _reverseGeocode(_pickedLocation!) : null,
                  ),
                1 => _DescriptionStep(
                    controller: _descriptionController,
                    selectedCategoryId: _selectedCategoryId,
                    onCategoryChanged: (id) => setState(() => _selectedCategoryId = id),
                    onChanged: () => setState(() {}),
                  ),
                2 => _PhotoStep(
                    photos: _photos,
                    isCompressing: _isCompressing,
                    onAddCamera: () => _addPhoto(ImageSource.camera),
                    onAddGallery: () => _addPhoto(ImageSource.gallery),
                    onRemove: (index) => setState(() => _photos.removeAt(index)),
                  ),
                _ => _ReviewStep(
                    description: _descriptionController.text.trim(),
                    address: _address,
                    photoCount: _photos.length,
                  ),
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Voltar'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: _step == _steps.length - 1 ? 'Enviar ocorrência' : 'Próximo',
                      isLoading: _isSubmitting,
                      onPressed: !_canGoNext
                          ? null
                          : () => _step == _steps.length - 1 ? _submit() : setState(() => _step++),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: i <= currentStep ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i <= currentStep ? theme.colorScheme.onPrimary : theme.colorScheme.outline,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[i],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: i <= currentStep ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (i < _steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  width: 16,
                  height: 2,
                  color: i < currentStep ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LocationStep extends ConsumerWidget {
  const _LocationStep({
    required this.mapController,
    required this.isLocating,
    required this.address,
    required this.onRecenter,
    required this.onMapEvent,
    required this.onMapEventEnd,
  });

  final MapController mapController;
  final bool isLocating;
  final String? address;
  final VoidCallback onRecenter;
  final void Function(LatLng) onMapEvent;
  final VoidCallback onMapEventEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tileLayer = ref.watch(mapProviderContractProvider).buildTileLayer();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 6),
              const Expanded(child: Text('Arraste o mapa para ajustar o local exato do problema.', style: TextStyle(fontSize: 12))),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: const LatLng(-15.7797, -47.9297),
                  initialZoom: 15,
                  onPositionChanged: (camera, hasGesture) {
                    if (hasGesture) onMapEvent(camera.center);
                  },
                  onMapEvent: (event) {
                    if (event is MapEventMoveEnd) onMapEventEnd();
                  },
                ),
                children: [tileLayer],
              ),
              const IgnorePointer(child: Icon(Icons.location_pin, size: 44, color: Colors.redAccent)),
              if (isLocating) const Positioned(top: 12, child: LinearProgressIndicator()),
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(onPressed: onRecenter, child: const Icon(Icons.my_location)),
              ),
              if (address != null)
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(address!, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DescriptionStep extends ConsumerWidget {
  const _DescriptionStep({
    required this.controller,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? selectedCategoryId;
  final void Function(String?) onCategoryChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categoria (opcional)', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (categories) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in categories)
                  ChoiceChip(
                    label: Text(category.name),
                    selected: selectedCategoryId == category.id,
                    onSelected: (selected) => onCategoryChanged(selected ? category.id : null),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Descreva o problema encontrado na estrada', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 5,
            maxLength: 500,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              hintText: 'Ex.: Buraco grande na pista, próximo à ponte, dificultando a passagem de veículos.',
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    required this.photos,
    required this.isCompressing,
    required this.onAddCamera,
    required this.onAddGallery,
    required this.onRemove,
  });

  final List<File> photos;
  final bool isCompressing;
  final VoidCallback onAddCamera;
  final VoidCallback onAddGallery;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foto do problema *', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            'A foto ajuda a equipe a entender o problema mais rápido. Até $_maxPhotos fotos.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: photos.length + (photos.length < _maxPhotos ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == photos.length) {
                  return _AddPhotoTile(isLoading: isCompressing, onCamera: onAddCamera, onGallery: onAddGallery);
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(photos[index], fit: BoxFit.cover),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemove(index),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.isLoading, required this.onCamera, required this.onGallery});

  final bool isLoading;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isLoading
          ? null
          : () => showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_camera_outlined),
                        title: const Text('Tirar nova foto'),
                        onTap: () {
                          Navigator.of(context).pop();
                          onCamera();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library_outlined),
                        title: const Text('Escolher da galeria'),
                        onTap: () {
                          Navigator.of(context).pop();
                          onGallery();
                        },
                      ),
                    ],
                  ),
                ),
              ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Icon(Icons.add_a_photo_outlined, color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.description, required this.address, required this.photoCount});

  final String description;
  final String? address;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revise antes de enviar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Icon(Icons.location_on_outlined, size: 18), const SizedBox(width: 8), Expanded(child: Text(address ?? 'Localização selecionada no mapa'))]),
                  const Divider(height: 24),
                  Text(description, style: theme.textTheme.bodyMedium),
                  const Divider(height: 24),
                  Row(children: [const Icon(Icons.photo_outlined, size: 18), const SizedBox(width: 8), Text('$photoCount foto(s) anexada(s)')]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
