import 'package:flutter_map/flutter_map.dart';
import 'geocoding_result.dart';
import 'map_provider_contract.dart';
import 'nominatim_geocoding_service.dart';

/// Unica implementacao concreta de [MapProviderContract] hoje: tiles do
/// OpenStreetMap e geocodificacao via Nominatim. Nada fora deste arquivo
/// (e do contrato) sabe que essas sao as tecnologias usadas.
class OsmMapProvider implements MapProviderContract {
  OsmMapProvider({NominatimGeocodingService? geocodingService})
      : _geocoding = geocodingService ?? NominatimGeocodingService();

  final NominatimGeocodingService _geocoding;

  @override
  TileLayer buildTileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'br.com.goodroads.desktop',
      maxNativeZoom: 19,
    );
  }

  @override
  Future<List<GeocodingResult>> geocode(String query) => _geocoding.search(query);
}
