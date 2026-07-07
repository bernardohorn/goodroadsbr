import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'geocoding_result.dart';

/// Abstrai tudo que as telas de mapa precisam, isolando a implementacao
/// concreta baseada em OpenStreetMap (ver docs/ARQUITETURA_GOODROADS.md,
/// secao 6). Se um dia for necessario trocar de provedor de tiles ou de
/// geocodificacao, basta criar uma nova implementacao desta interface —
/// nenhuma tela precisa mudar.
abstract class MapProviderContract {
  TileLayer buildTileLayer();

  /// Posicao atual (uma unica leitura). Lanca [LocationServiceDisabledException],
  /// [LocationPermissionDeniedException] ou
  /// [LocationPermissionPermanentlyDeniedException] quando aplicavel.
  Future<LatLng> currentPosition();

  /// Fluxo de posicao, usado para centralizar o mapa continuamente.
  Stream<LatLng> watchPosition();

  Future<List<GeocodingResult>> geocode(String query);

  Future<String?> reverseGeocode(LatLng point);
}
