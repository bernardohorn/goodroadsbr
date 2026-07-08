# Abrir o Mapa focado na localização de uma ocorrência — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ao tocar no preview de mapa da tela de detalhes de uma ocorrência, abrir a aba "Mapa" já centralizada na localização daquela ocorrência, com o pin dela destacado entre as demais.

**Architecture:** A rota `/mapa` passa a aceitar query params opcionais (`lat`, `lng`, `focusId`), parseados por uma função pura (`MapFocusArgs.fromQueryParameters`) e repassados ao construtor de `MapPage`. `MapPage` usa esse foco (quando presente) para centralizar a busca de ocorrências próximas e destacar o pin correspondente, sem afetar o comportamento atual quando acessada normalmente pela aba. O preview de mapa na tela de detalhes vira tocável e navega para essa rota com os query params da ocorrência.

**Tech Stack:** Flutter, `flutter_riverpod`, `go_router`, `flutter_map`, `latlong2`. Sem dependências novas.

## Global Constraints

- Mapas: somente `flutter_map` + `geolocator` + Nominatim — nunca Google Maps (ver `mobile/CLAUDE.md`).
- Clean Architecture: nenhuma lógica nova de domínio/dados é necessária — `Occurrence` já expõe `latitude`/`longitude`, `OccurrencePin` já expõe `id`.
- Sem mudança de contrato de API/backend.
- `flutter analyze` e `flutter test` devem passar limpos ao final de cada task.
- Commits seguem Conventional Commits (`feat:`, `test:`, etc.), conforme `CLAUDE.md` raiz.

---

## File Structure

- **Modify:** `mobile/lib/core/routing/app_routes.dart` — adiciona `AppRoutes.mapFocusedOn(...)` e a classe `MapFocusArgs` (parse puro de query params).
- **Modify:** `mobile/lib/core/routing/app_router.dart` — o `GoRoute` de `AppRoutes.map` passa a repassar `MapFocusArgs.fromQueryParameters(...)` para `MapPage`.
- **Modify:** `mobile/lib/features/map/presentation/pages/map_page.dart` — `MapPage` aceita foco opcional, centraliza nele, destaca o pin, e o FAB sempre recentraliza no GPS real.
- **Modify:** `mobile/lib/features/occurrences/presentation/pages/occurrence_details_page.dart` — preview de mapa vira tocável.
- **Create:** `mobile/test/core/routing/app_routes_test.dart` — testa `AppRoutes.mapFocusedOn` e `MapFocusArgs.fromQueryParameters`.
- **Create:** `mobile/test/features/map/map_page_test.dart` — testa centralização no foco, destaque do pin e recentralização via FAB.
- **Create:** `mobile/test/features/occurrences/occurrence_details_page_test.dart` — testa que tocar o preview navega com os query params corretos.

---

### Task 1: Rota com foco opcional (`AppRoutes.mapFocusedOn` + `MapFocusArgs`)

**Files:**
- Modify: `mobile/lib/core/routing/app_routes.dart`
- Test: `mobile/test/core/routing/app_routes_test.dart`

**Interfaces:**
- Produces: `AppRoutes.mapFocusedOn({required double lat, required double lng, required String occurrenceId}) -> String`
- Produces: `MapFocusArgs` com campos `latitude` (`double?`), `longitude` (`double?`), `occurrenceId` (`String?`), e `factory MapFocusArgs.fromQueryParameters(Map<String, String> queryParameters)`.

- [ ] **Step 1: Escrever o teste (vai falhar, pois nada disso existe ainda)**

Criar `mobile/test/core/routing/app_routes_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:goodroadsbr/core/routing/app_routes.dart';

void main() {
  group('AppRoutes.mapFocusedOn', () {
    test('gera a rota /mapa com lat, lng e focusId como query params', () {
      final path = AppRoutes.mapFocusedOn(lat: -27.1962, lng: -52.0264, occurrenceId: 'occ-1');

      expect(path, '/mapa?lat=-27.1962&lng=-52.0264&focusId=occ-1');
    });
  });

  group('MapFocusArgs.fromQueryParameters', () {
    test('parseia lat/lng/focusId quando presentes', () {
      final args = MapFocusArgs.fromQueryParameters({
        'lat': '-27.1962',
        'lng': '-52.0264',
        'focusId': 'occ-1',
      });

      expect(args.latitude, -27.1962);
      expect(args.longitude, -52.0264);
      expect(args.occurrenceId, 'occ-1');
    });

    test('resulta em campos nulos quando os query params nao existem', () {
      final args = MapFocusArgs.fromQueryParameters(const {});

      expect(args.latitude, isNull);
      expect(args.longitude, isNull);
      expect(args.occurrenceId, isNull);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste para confirmar que falha**

Run: `cd mobile && flutter test test/core/routing/app_routes_test.dart`
Expected: FAIL — `mapFocusedOn`/`MapFocusArgs` não existem em `app_routes.dart`.

- [ ] **Step 3: Implementar em `app_routes.dart`**

Arquivo atual completo (para referência de contexto):

```dart
/// Constantes de rota, para nao espalhar strings magicas por telas e
/// widgets. `go_router` e configurado em `app_router.dart` usando estes
/// mesmos valores.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/cadastro';
  static const home = '/';
  static const map = '/mapa';
  static const history = '/historico';
  static const profile = '/perfil';
  static const registerOccurrence = '/ocorrencias/nova';
  static const occurrenceDetails = '/ocorrencias/:id';

  static String occurrenceDetailsPath(String id) => '/ocorrencias/$id';
}
```

Substituir pelo conteúdo completo abaixo (adiciona `mapFocusedOn` e a classe `MapFocusArgs`):

```dart
/// Constantes de rota, para nao espalhar strings magicas por telas e
/// widgets. `go_router` e configurado em `app_router.dart` usando estes
/// mesmos valores.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/cadastro';
  static const home = '/';
  static const map = '/mapa';
  static const history = '/historico';
  static const profile = '/perfil';
  static const registerOccurrence = '/ocorrencias/nova';
  static const occurrenceDetails = '/ocorrencias/:id';

  static String occurrenceDetailsPath(String id) => '/ocorrencias/$id';

  /// Rota da aba "Mapa" ja centralizada na localizacao de uma ocorrencia
  /// especifica (ver `OccurrenceDetailsPage`, preview de mapa tocavel).
  static String mapFocusedOn({required double lat, required double lng, required String occurrenceId}) =>
      '$map?lat=$lat&lng=$lng&focusId=$occurrenceId';
}

/// Argumentos opcionais de foco extraidos da query string da rota `/mapa`.
/// Isola o parse dos query params (testavel sem precisar de `BuildContext`
/// ou `GoRouterState`) do restante da configuracao de rotas.
class MapFocusArgs {
  const MapFocusArgs({this.latitude, this.longitude, this.occurrenceId});

  final double? latitude;
  final double? longitude;
  final String? occurrenceId;

  factory MapFocusArgs.fromQueryParameters(Map<String, String> queryParameters) {
    return MapFocusArgs(
      latitude: double.tryParse(queryParameters['lat'] ?? ''),
      longitude: double.tryParse(queryParameters['lng'] ?? ''),
      occurrenceId: queryParameters['focusId'],
    );
  }
}
```

- [ ] **Step 4: Rodar o teste para confirmar que passa**

Run: `cd mobile && flutter test test/core/routing/app_routes_test.dart`
Expected: PASS (4 testes).

- [ ] **Step 5: Commit**

```bash
cd mobile
git add lib/core/routing/app_routes.dart test/core/routing/app_routes_test.dart
git commit -m "feat(mobile): adiciona AppRoutes.mapFocusedOn e MapFocusArgs

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 2: `MapPage` centraliza no ponto de foco quando presente

**Files:**
- Modify: `mobile/lib/features/map/presentation/pages/map_page.dart`
- Modify: `mobile/lib/core/routing/app_router.dart`
- Test: `mobile/test/features/map/map_page_test.dart`

**Interfaces:**
- Consumes: `MapFocusArgs` (Task 1), `mapRepositoryProvider` (`Provider<MapRepository>`, já existente em `map_providers.dart`), `mapProviderContractProvider` (`Provider<MapProviderContract>`, já existente).
- Produces: `MapPage({super.key, this.focusLatitude, this.focusLongitude, this.focusOccurrenceId})` — três novos campos opcionais `double?`, `double?`, `String?`.

- [ ] **Step 1: Escrever o teste (vai falhar — `MapPage` ainda nao aceita esses parametros)**

Criar `mobile/test/features/map/map_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodroadsbr/core/error/result.dart';
import 'package:goodroadsbr/core/map/geocoding_result.dart';
import 'package:goodroadsbr/core/map/map_provider_contract.dart';
import 'package:goodroadsbr/features/map/domain/entities/bounding_box.dart';
import 'package:goodroadsbr/features/map/domain/entities/occurrence_pin.dart';
import 'package:goodroadsbr/features/map/domain/repositories/map_repository.dart';
import 'package:goodroadsbr/features/map/presentation/controllers/map_providers.dart';
import 'package:goodroadsbr/features/map/presentation/pages/map_page.dart';
import 'package:latlong2/latlong.dart';

/// Posicao de GPS bem distante do ponto de foco usado nos testes — se o
/// mapa centralizasse nela por engano em vez do foco, os testes abaixo
/// falhariam.
const _gpsPosition = LatLng(-15.7797, -47.9297);
const _focusLat = -27.1962;
const _focusLng = -52.0264;

class _FakeMapRepository implements MapRepository {
  BoundingBox? lastBox;

  @override
  Future<Result<List<OccurrencePin>>> findInBoundingBox(BoundingBox box, {String? status}) async {
    lastBox = box;
    return Result.success(const [
      OccurrencePin(id: 'occ-1', protocolNumber: '2026-0001', status: 'PENDENTE', priority: 'ALTA', latitude: _focusLat, longitude: _focusLng),
      OccurrencePin(id: 'occ-2', protocolNumber: '2026-0002', status: 'PENDENTE', priority: 'BAIXA', latitude: _gpsPosition.latitude, longitude: _gpsPosition.longitude),
    ]);
  }
}

class _FakeMapProviderContract implements MapProviderContract {
  @override
  TileLayer buildTileLayer() => TileLayer(urlTemplate: 'https://example.com/{z}/{x}/{y}.png');

  @override
  Future<LatLng> currentPosition() async => _gpsPosition;

  @override
  Stream<LatLng> watchPosition() => Stream.empty();

  @override
  Future<List<GeocodingResult>> geocode(String query) async => [];

  @override
  Future<String?> reverseGeocode(LatLng point) async => null;
}

void main() {
  testWidgets('com foco, centraliza a busca de ocorrencias no ponto da ocorrencia, nao no GPS', (tester) async {
    final fakeRepository = _FakeMapRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapRepositoryProvider.overrideWithValue(fakeRepository),
          mapProviderContractProvider.overrideWithValue(_FakeMapProviderContract()),
        ],
        child: const MaterialApp(
          home: MapPage(focusLatitude: _focusLat, focusLongitude: _focusLng, focusOccurrenceId: 'occ-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final expectedBox = BoundingBox.aroundPoint(lat: _focusLat, lng: _focusLng, radiusKm: 20);
    expect(fakeRepository.lastBox, isNotNull);
    expect(fakeRepository.lastBox!.north, closeTo(expectedBox.north, 0.0001));
    expect(fakeRepository.lastBox!.south, closeTo(expectedBox.south, 0.0001));
    expect(fakeRepository.lastBox!.east, closeTo(expectedBox.east, 0.0001));
    expect(fakeRepository.lastBox!.west, closeTo(expectedBox.west, 0.0001));
  });

  testWidgets('sem foco, centraliza a busca de ocorrencias na posicao GPS (comportamento atual, sem regressao)', (tester) async {
    final fakeRepository = _FakeMapRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapRepositoryProvider.overrideWithValue(fakeRepository),
          mapProviderContractProvider.overrideWithValue(_FakeMapProviderContract()),
        ],
        child: const MaterialApp(home: MapPage()),
      ),
    );

    await tester.pumpAndSettle();

    final expectedBox = BoundingBox.aroundPoint(lat: _gpsPosition.latitude, lng: _gpsPosition.longitude, radiusKm: 20);
    expect(fakeRepository.lastBox, isNotNull);
    expect(fakeRepository.lastBox!.north, closeTo(expectedBox.north, 0.0001));
    expect(fakeRepository.lastBox!.west, closeTo(expectedBox.west, 0.0001));
  });
}
```

- [ ] **Step 2: Rodar o teste para confirmar que falha**

Run: `cd mobile && flutter test test/features/map/map_page_test.dart`
Expected: FAIL — `MapPage` não tem os parâmetros `focusLatitude`/`focusLongitude`/`focusOccurrenceId`.

- [ ] **Step 3: Implementar em `map_page.dart`**

O arquivo hoje tem esta forma (relevante para o diff):

```dart
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
```

Substituir por:

```dart
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key, this.focusLatitude, this.focusLongitude, this.focusOccurrenceId});

  /// Quando presentes (ver `AppRoutes.mapFocusedOn`), o mapa abre
  /// centralizado nesse ponto em vez da localizacao atual do usuario —
  /// usado ao tocar no preview de mapa da tela de detalhes de ocorrencia.
  final double? focusLatitude;
  final double? focusLongitude;
  final String? focusOccurrenceId;

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
  String? _focusedOccurrenceId;

  LatLng? get _focusPoint =>
      widget.focusLatitude != null && widget.focusLongitude != null
          ? LatLng(widget.focusLatitude!, widget.focusLongitude!)
          : null;

  @override
  void initState() {
    super.initState();
    _focusedOccurrenceId = widget.focusOccurrenceId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    final focus = _focusPoint;
    if (focus != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      _mapController.move(focus, 16);
      unawaited(_loadCurrentPositionMarkerOnly());
      await _loadPinsAround(focus);
      return;
    }

    await _recenterOnCurrentPosition();
  }

  /// Busca a posicao do GPS so para exibir o marcador "voce esta aqui",
  /// sem mover a camera nem recarregar os pins — usado quando o mapa abre
  /// com foco em uma ocorrencia especifica.
  Future<void> _loadCurrentPositionMarkerOnly() async {
    try {
      final position = await ref.read(mapProviderContractProvider).currentPosition();
      if (mounted) setState(() => _currentPosition = position);
    } catch (_) {
      // Sem localizacao disponivel: mantem so o foco, sem marcador "voce esta aqui".
    }
  }

  /// Recentraliza no GPS atual e recarrega os pins em torno dele. Usado no
  /// carregamento inicial (sem foco) e sempre que o FAB "minha localização"
  /// e tocado — inclusive quando a tela abriu com foco em uma ocorrencia,
  /// caso em que tocar o FAB abandona o foco.
  Future<void> _recenterOnCurrentPosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _focusedOccurrenceId = null;
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
```

Adicionar o import de `dart:async` (para `unawaited`) no topo do arquivo, junto aos demais imports:

```dart
import 'dart:async';
```

- [ ] **Step 4: Trocar o `onPressed` do FAB para usar o novo metodo de recentralizacao**

Localizar, mais abaixo no mesmo arquivo:

```dart
      floatingActionButton: FloatingActionButton(
        onPressed: _loadInitialData,
        tooltip: 'Minha localização',
        child: const Icon(Icons.my_location),
      ),
```

Substituir por:

```dart
      floatingActionButton: FloatingActionButton(
        onPressed: _recenterOnCurrentPosition,
        tooltip: 'Minha localização',
        child: const Icon(Icons.my_location),
      ),
```

- [ ] **Step 5: Rodar o teste para confirmar que passa**

Run: `cd mobile && flutter test test/features/map/map_page_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 6: Ligar a rota `/mapa` ao novo `MapPage` com foco — `app_router.dart`**

Localizar em `app_router.dart`:

```dart
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.map, builder: (context, state) => const MapPage())]),
```

Substituir por:

```dart
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.map,
                builder: (context, state) {
                  final focus = MapFocusArgs.fromQueryParameters(state.uri.queryParameters);
                  return MapPage(
                    focusLatitude: focus.latitude,
                    focusLongitude: focus.longitude,
                    focusOccurrenceId: focus.occurrenceId,
                  );
                },
              ),
            ],
          ),
```

`MapFocusArgs` já vem de `app_routes.dart`, que já é importado nesse arquivo (`import 'app_routes.dart';`) — nenhum import novo necessário.

- [ ] **Step 7: Rodar analyze e toda a suite para garantir que nada quebrou**

Run: `cd mobile && flutter analyze && flutter test`
Expected: `No issues found!` e todos os testes passando.

- [ ] **Step 8: Commit**

```bash
cd mobile
git add lib/features/map/presentation/pages/map_page.dart lib/core/routing/app_router.dart test/features/map/map_page_test.dart
git commit -m "feat(mobile): MapPage centraliza em ponto de foco quando presente

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 3: Destacar o pin da ocorrencia focada

**Files:**
- Modify: `mobile/lib/features/map/presentation/pages/map_page.dart`
- Test: `mobile/test/features/map/map_page_test.dart`

**Interfaces:**
- Consumes: `_focusedOccurrenceId` (state field adicionado na Task 2).
- Produces: cada `Marker` de pin ganha `key: Key('pin-marker-${pin.id}')`, permitindo aos testes localizar um pin especifico.

- [ ] **Step 1: Adicionar os dois casos de teste (vao falhar — a chave e o destaque ainda nao existem)**

Adicionar ao final do `main()` em `mobile/test/features/map/map_page_test.dart` (mesmo arquivo da Task 2):

```dart
  testWidgets('destaca o pin da ocorrencia focada entre os demais', (tester) async {
    final fakeRepository = _FakeMapRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapRepositoryProvider.overrideWithValue(fakeRepository),
          mapProviderContractProvider.overrideWithValue(_FakeMapProviderContract()),
        ],
        child: const MaterialApp(
          home: MapPage(focusLatitude: _focusLat, focusLongitude: _focusLng, focusOccurrenceId: 'occ-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final focusedMarker = find.byKey(const Key('pin-marker-occ-1'));
    final otherMarker = find.byKey(const Key('pin-marker-occ-2'));

    expect(focusedMarker, findsOneWidget);
    expect(otherMarker, findsOneWidget);
    expect(find.descendant(of: focusedMarker, matching: find.byType(Container)), findsOneWidget);
    expect(find.descendant(of: otherMarker, matching: find.byType(Container)), findsNothing);
  });

  testWidgets('tocar no FAB "minha localizacao" abandona o foco e recentraliza no GPS', (tester) async {
    final fakeRepository = _FakeMapRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapRepositoryProvider.overrideWithValue(fakeRepository),
          mapProviderContractProvider.overrideWithValue(_FakeMapProviderContract()),
        ],
        child: const MaterialApp(
          home: MapPage(focusLatitude: _focusLat, focusLongitude: _focusLng, focusOccurrenceId: 'occ-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Minha localização'));
    await tester.pumpAndSettle();

    final expectedBox = BoundingBox.aroundPoint(lat: _gpsPosition.latitude, lng: _gpsPosition.longitude, radiusKm: 20);
    expect(fakeRepository.lastBox!.north, closeTo(expectedBox.north, 0.0001));
    expect(find.descendant(of: find.byKey(const Key('pin-marker-occ-1')), matching: find.byType(Container)), findsNothing);
  });
```

- [ ] **Step 2: Rodar o teste para confirmar que falha**

Run: `cd mobile && flutter test test/features/map/map_page_test.dart`
Expected: FAIL — os `Marker` ainda não têm `key`, nem destaque visual para o pin focado.

- [ ] **Step 3: Implementar o destaque em `map_page.dart`**

Localizar, dentro do `MarkerLayer` do metodo `build`:

```dart
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
```

Substituir por:

```dart
                  for (final pin in _pins)
                    Marker(
                      key: Key('pin-marker-${pin.id}'),
                      point: LatLng(pin.latitude, pin.longitude),
                      width: pin.id == _focusedOccurrenceId ? 48 : 36,
                      height: pin.id == _focusedOccurrenceId ? 48 : 36,
                      child: GestureDetector(
                        onTap: () => context.push(AppRoutes.occurrenceDetailsPath(pin.id)),
                        child: pin.id == _focusedOccurrenceId
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: const Icon(Icons.location_on, color: Colors.white, size: 26),
                              )
                            : Icon(Icons.location_on, color: _colorForStatus(pin.status), size: 36),
                      ),
                    ),
```

- [ ] **Step 4: Rodar o teste para confirmar que passa**

Run: `cd mobile && flutter test test/features/map/map_page_test.dart`
Expected: PASS (4 testes no arquivo).

- [ ] **Step 5: Rodar analyze e toda a suite**

Run: `cd mobile && flutter analyze && flutter test`
Expected: `No issues found!` e todos os testes passando.

- [ ] **Step 6: Commit**

```bash
cd mobile
git add lib/features/map/presentation/pages/map_page.dart test/features/map/map_page_test.dart
git commit -m "feat(mobile): destaca pin da ocorrencia focada no mapa

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 4: Preview de mapa na tela de detalhes vira tocavel

**Files:**
- Modify: `mobile/lib/features/occurrences/presentation/pages/occurrence_details_page.dart`
- Test: `mobile/test/features/occurrences/occurrence_details_page_test.dart`

**Interfaces:**
- Consumes: `AppRoutes.mapFocusedOn` (Task 1), `Occurrence.latitude`/`longitude`/`id` (já existentes).
- Produces: o preview de mapa passa a ter `key: const Key('occurrence-location-map-preview')` no `GestureDetector` que o envolve.

- [ ] **Step 1: Escrever o teste (vai falhar — o preview ainda nao e tocavel)**

Criar `mobile/test/features/occurrences/occurrence_details_page_test.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:goodroadsbr/core/error/result.dart';
import 'package:goodroadsbr/core/map/geocoding_result.dart';
import 'package:goodroadsbr/core/map/map_provider_contract.dart';
import 'package:goodroadsbr/core/routing/app_routes.dart';
import 'package:goodroadsbr/features/map/presentation/controllers/map_providers.dart';
import 'package:goodroadsbr/features/occurrences/domain/entities/category.dart';
import 'package:goodroadsbr/features/occurrences/domain/entities/occurrence.dart';
import 'package:goodroadsbr/features/occurrences/domain/entities/occurrence_status_history_entry.dart';
import 'package:goodroadsbr/features/occurrences/domain/entities/paginated_occurrences.dart';
import 'package:goodroadsbr/features/occurrences/domain/repositories/occurrences_repository.dart';
import 'package:goodroadsbr/features/occurrences/presentation/controllers/occurrences_providers.dart';
import 'package:goodroadsbr/features/occurrences/presentation/pages/occurrence_details_page.dart';
import 'package:latlong2/latlong.dart';

final _occurrence = Occurrence(
  id: 'occ-1',
  protocolNumber: '2026-0001',
  description: 'Buraco grande na pista',
  status: 'PENDENTE',
  priority: 'ALTA',
  latitude: -27.1962,
  longitude: -52.0264,
  address: 'Rua Exemplo, 123',
  photos: const [],
  createdAt: DateTime(2026, 7, 8),
);

class _FakeOccurrencesRepository implements OccurrencesRepository {
  @override
  Future<Result<Occurrence>> create({
    required String description,
    required double latitude,
    required double longitude,
    String? address,
    String? categoryId,
    required List<File> photos,
  }) => throw UnimplementedError();

  @override
  Future<Result<Occurrence>> getById(String id) async => Result.success(_occurrence);

  @override
  Future<Result<List<OccurrenceStatusHistoryEntry>>> getHistory(String id) async =>
      Result.success(const <OccurrenceStatusHistoryEntry>[]);

  @override
  Future<Result<List<Category>>> listCategories() async => Result.success(const <Category>[]);

  @override
  Future<Result<PaginatedOccurrences>> listMine({int page = 1, String? status}) => throw UnimplementedError();
}

class _FakeMapProviderContract implements MapProviderContract {
  @override
  TileLayer buildTileLayer() => TileLayer(urlTemplate: 'https://example.com/{z}/{x}/{y}.png');

  @override
  Future<LatLng> currentPosition() async => const LatLng(0, 0);

  @override
  Stream<LatLng> watchPosition() => Stream.empty();

  @override
  Future<List<GeocodingResult>> geocode(String query) async => [];

  @override
  Future<String?> reverseGeocode(LatLng point) async => null;
}

void main() {
  testWidgets('tocar no preview do mapa navega para /mapa com lat/lng/focusId da ocorrencia', (tester) async {
    String? capturedLat;
    String? capturedLng;
    String? capturedFocusId;

    final router = GoRouter(
      initialLocation: AppRoutes.occurrenceDetailsPath('occ-1'),
      routes: [
        GoRoute(
          path: AppRoutes.occurrenceDetails,
          builder: (context, state) => OccurrenceDetailsPage(occurrenceId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoutes.map,
          builder: (context, state) {
            capturedLat = state.uri.queryParameters['lat'];
            capturedLng = state.uri.queryParameters['lng'];
            capturedFocusId = state.uri.queryParameters['focusId'];
            return const Scaffold(body: Text('Mapa focado'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          occurrencesRepositoryProvider.overrideWithValue(_FakeOccurrencesRepository()),
          mapProviderContractProvider.overrideWithValue(_FakeMapProviderContract()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('occurrence-location-map-preview')));
    await tester.pumpAndSettle();

    expect(find.text('Mapa focado'), findsOneWidget);
    expect(double.parse(capturedLat!), closeTo(_occurrence.latitude, 0.0001));
    expect(double.parse(capturedLng!), closeTo(_occurrence.longitude, 0.0001));
    expect(capturedFocusId, 'occ-1');
  });
}
```

- [ ] **Step 2: Rodar o teste para confirmar que falha**

Run: `cd mobile && flutter test test/features/occurrences/occurrence_details_page_test.dart`
Expected: FAIL — não existe nenhum widget com a key `occurrence-location-map-preview`.

- [ ] **Step 3: Implementar em `occurrence_details_page.dart`**

Adicionar os imports no topo do arquivo (junto aos demais):

```dart
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
```

Localizar o preview de mapa:

```dart
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 160,
                        child: IgnorePointer(
                          child: FlutterMap(
```

Substituir por (envolve com `GestureDetector`, mantendo o `FlutterMap` interno intocavel — o toque so dispara a navegacao):

```dart
                    GestureDetector(
                      key: const Key('occurrence-location-map-preview'),
                      onTap: () => context.push(
                        AppRoutes.mapFocusedOn(
                          lat: occurrence.latitude,
                          lng: occurrence.longitude,
                          occurrenceId: occurrence.id,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 160,
                          child: IgnorePointer(
                            child: FlutterMap(
```

E, mais abaixo, fechar a nova estrutura. Localizar o fechamento atual do preview:

```dart
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A localização é aproximada e pode variar em alguns metros.',
```

Substituir por (um `)` a mais para fechar o `GestureDetector`):

```dart
                            ],
                          ),
                        ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A localização é aproximada e pode variar em alguns metros.',
```

- [ ] **Step 4: Rodar `flutter analyze` e ajustar identacao**

Run: `cd mobile && flutter analyze`
Expected: pode acusar formatação; se acusar, rodar `dart format lib/features/occurrences/presentation/pages/occurrence_details_page.dart` e conferir que `flutter analyze` fica limpo (`No issues found!`).

- [ ] **Step 5: Rodar o teste para confirmar que passa**

Run: `cd mobile && flutter test test/features/occurrences/occurrence_details_page_test.dart`
Expected: PASS.

- [ ] **Step 6: Rodar analyze e toda a suite do projeto**

Run: `cd mobile && flutter analyze && flutter test`
Expected: `No issues found!` e todos os testes passando (incluindo os das Tasks 1–3).

- [ ] **Step 7: Checklist final do `mobile/CLAUDE.md`**

Run: `cd mobile && grep -ri "google_maps" -r lib/ pubspec.yaml`
Expected: nenhuma ocorrência.

- [ ] **Step 8: Commit**

```bash
cd mobile
git add lib/features/occurrences/presentation/pages/occurrence_details_page.dart test/features/occurrences/occurrence_details_page_test.dart
git commit -m "feat(mobile): preview de mapa na ocorrencia abre o Mapa focado nela

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Self-Review

**Cobertura do spec:**
- "Ao tocar no preview, abre a tela Mapa já centralizada na ocorrência" → Task 2 (centralização) + Task 4 (navegação a partir do preview). ✓
- "Pin da ocorrência de origem destacado entre as demais" → Task 3. ✓
- "FAB 'minha localização' sempre recentraliza no GPS, abandonando o foco" → Task 2 (método `_recenterOnCurrentPosition`) + Task 3 (teste cobrindo o abandono do foco). ✓
- "Sem foco, comportamento atual não muda" → Task 2, segundo teste (`sem foco, centraliza...`). ✓
- "Sem mudança de contrato de API" → nenhuma task toca `data/`/`domain/repositories` ou datasources. ✓

**Placeholders:** nenhum "TBD"/"implementar depois" — todo step tem código completo.

**Consistência de tipos:** `MapFocusArgs.latitude/longitude/occurrenceId` (Task 1) são exatamente os campos lidos em `app_router.dart` (Task 2) e os nomes usados em `MapPage.focusLatitude/focusLongitude/focusOccurrenceId` (Task 2) batem em todas as tasks subsequentes. `pin.id`/`_focusedOccurrenceId` (Task 3) usam os mesmos tipos (`String`/`String?`) definidos em `OccurrencePin` e `MapPage`.
