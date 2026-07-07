import 'dart:math';

class BoundingBox {
  const BoundingBox({required this.north, required this.south, required this.east, required this.west});

  final double north;
  final double south;
  final double east;
  final double west;

  /// Bounding box aproximada de `radiusKm` ao redor de um ponto — usado
  /// quando a tela ainda nao tem os limites reais do viewport do mapa
  /// (ex.: carregamento inicial da lista "Todas as ocorrências").
  factory BoundingBox.aroundPoint({required double lat, required double lng, double radiusKm = 15}) {
    final latDelta = radiusKm / 111.0;
    final cosLat = max(cos(lat * pi / 180).abs(), 0.1);
    final lngDelta = radiusKm / (111.0 * cosLat);
    return BoundingBox(north: lat + latDelta, south: lat - latDelta, east: lng + lngDelta, west: lng - lngDelta);
  }
}
