import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/bounding_box.dart';
import '../../domain/entities/occurrence_pin.dart';
import '../controllers/map_providers.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final _mapController = MapController();
  static const _fallbackCenter = LatLng(-15.7797, -47.9297); // Brasilia, usado se a localizacao falhar

  LatLng? _currentPosition;
  List<OccurrencePin> _pins = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    LatLng center = _fallbackCenter;
    try {
      center = await ref.read(mapProviderContractProvider).currentPosition();
      setState(() => _currentPosition = center);
      _mapController.move(center, 14);
    } catch (_) {
      // Sem localizacao disponivel: segue com o centro padrao, apenas sem
      // marcador de "voce esta aqui".
    }

    await _loadPinsAround(center);
  }

  Future<void> _loadPinsAround(LatLng center) async {
    final box = BoundingBox.aroundPoint(lat: center.latitude, lng: center.longitude, radiusKm: 20);
    final result = await ref.read(findOccurrencesInBoundingBoxUseCaseProvider)(box);

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _errorMessage = failure.message;
        _isLoading = false;
      }),
      (pins) => setState(() {
        _pins = pins;
        _isLoading = false;
      }),
    );
  }

  Color _colorForStatus(String status) => switch (status) {
        'PENDENTE' => AppColors.statusPendente,
        'EM_ANDAMENTO' => AppColors.statusEmAndamento,
        'RESOLVIDA' => AppColors.statusResolvida,
        _ => AppColors.statusCancelada,
      };

  @override
  Widget build(BuildContext context) {
    final tileLayer = ref.watch(mapProviderContractProvider).buildTileLayer();

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _fallbackCenter, initialZoom: 12),
            children: [
              tileLayer,
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  for (final pin in _pins)
                    Marker(
                      point: LatLng(pin.latitude, pin.longitude),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => context.push(AppRoutes.occurrenceDetailsPath(pin.id)),
                        child: Icon(Icons.location_on, color: _colorForStatus(pin.status), size: 36),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_isLoading) const Positioned(top: 16, right: 16, child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadInitialData,
        tooltip: 'Minha localização',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
