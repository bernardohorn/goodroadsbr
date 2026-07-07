import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'geocoding_result.dart';
import 'location_exceptions.dart';
import 'map_provider_contract.dart';
import 'nominatim_geocoding_service.dart';

/// Unica implementacao concreta de [MapProviderContract] hoje: tiles do
/// OpenStreetMap, posicao via Geolocator e geocodificacao via Nominatim.
/// Nada fora deste arquivo (e do contrato) sabe que essas sao as
/// tecnologias usadas.
class OsmMapProvider implements MapProviderContract {
  OsmMapProvider({NominatimGeocodingService? geocodingService})
    : _geocoding = geocodingService ?? NominatimGeocodingService();

  final NominatimGeocodingService _geocoding;

  @override
  TileLayer buildTileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'br.com.goodroads.mobile',
      maxNativeZoom: 19,
    );
  }

  Future<void> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw AppLocationServiceDisabledException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw AppLocationPermissionDeniedException();
    }
  }

  @override
  Future<LatLng> currentPosition() async {
    await _ensurePermission();
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LatLng(position.latitude, position.longitude);
  }

  @override
  Stream<LatLng> watchPosition() async* {
    await _ensurePermission();
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }

  @override
  Future<List<GeocodingResult>> geocode(String query) =>
      _geocoding.search(query);

  @override
  Future<String?> reverseGeocode(LatLng point) => _geocoding.reverse(point);
}
