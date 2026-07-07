import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/presentation/controllers/categories_providers.dart';
import '../../domain/entities/bounding_box.dart';
import '../../domain/entities/occurrence_pin.dart';
import '../controllers/map_providers.dart';

const _statusOptions = {'PENDENTE': 'Pendente', 'EM_ANDAMENTO': 'Em andamento', 'RESOLVIDA': 'Resolvida', 'CANCELADA': 'Cancelada'};

/// Tela 5/10 do desktop: mapa com clustering, busca por endereco e filtros
/// aplicados ao backend (ver docs/ARQUITETURA_GOODROADS.md, secao 6 —
/// "Desktop: clustering, busca por endereço, filtros aplicados ao backend,
/// painel rápido de detalhes").
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  static const _brazilCenter = LatLng(-14.235, -51.925);

  List<OccurrencePin> _pins = [];
  bool _isLoading = false;
  String? _statusFilter;
  String? _categoryFilter;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchThisArea());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchThisArea() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final bounds = _mapController.camera.visibleBounds;
    final box = BoundingBox(
      north: bounds.north,
      south: bounds.south,
      east: bounds.east,
      west: bounds.west,
    );

    final result = await ref.read(findOccurrencesInBoundingBoxUseCaseProvider)(
      box,
      status: _statusFilter,
      categoryId: _categoryFilter,
    );

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

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    final results = await ref.read(mapProviderContractProvider).geocode(query);
    if (results.isEmpty || !mounted) return;
    _mapController.move(results.first.position, 14);
    await _searchThisArea();
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
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search), hintText: 'Buscar endereço'),
                    onSubmitted: _searchAddress,
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    isDense: true,
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(isDense: true, labelText: 'Status'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      for (final entry in _statusOptions.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                    ],
                    onChanged: (value) {
                      setState(() => _statusFilter = value);
                      _searchThisArea();
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: categoriesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (categories) => DropdownButtonFormField<String>(
                      isDense: true,
                      initialValue: _categoryFilter,
                      decoration: const InputDecoration(isDense: true, labelText: 'Categoria'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todas')),
                        for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (value) {
                        setState(() => _categoryFilter = value);
                        _searchThisArea();
                      },
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _searchThisArea,
                  icon: const Icon(Icons.travel_explore),
                  label: const Text('Buscar nesta área'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(initialCenter: _brazilCenter, initialZoom: 4),
                  children: [
                    tileLayer,
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 45,
                        size: const Size(40, 40),
                        markers: [
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
                        builder: (context, markers) => CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text('${markers.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isLoading) const Positioned(top: 16, right: 16, child: CircularProgressIndicator()),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text('${_pins.length} ocorrência(s) na área visível'),
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 16,
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
          ),
        ],
      ),
    );
  }
}
