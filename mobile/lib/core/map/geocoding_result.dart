import 'package:latlong2/latlong.dart';

class GeocodingResult {
  final String displayName;
  final LatLng position;

  const GeocodingResult({required this.displayName, required this.position});
}
