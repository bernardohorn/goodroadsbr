import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'geocoding_result.dart';

/// Cliente do Nominatim (geocodificacao baseada em OpenStreetMap). Usado na
/// tela Mapa do desktop para a busca por endereco (ver
/// docs/ARQUITETURA_GOODROADS.md, secao 6). Deliberadamente usa uma
/// instancia de Dio propria (nao a `dioProvider` da API do GoodRoads), pois
/// fala com um host completamente diferente e nao deve levar os
/// interceptors de autenticacao da API.
class NominatimGeocodingService {
  NominatimGeocodingService() : _dio = Dio(BaseOptions(baseUrl: 'https://nominatim.openstreetmap.org'));

  final Dio _dio;

  Future<List<GeocodingResult>> search(String query) async {
    if (query.trim().length < 3) return [];

    final response = await _dio.get<List<dynamic>>(
      '/search',
      queryParameters: {'q': query, 'format': 'jsonv2', 'limit': 5, 'countrycodes': 'br'},
      options: Options(headers: {'User-Agent': 'GoodRoads-Desktop/1.0'}),
    );

    return (response.data ?? [])
        .map(
          (item) => GeocodingResult(
            displayName: item['display_name'] as String,
            position: LatLng(double.parse(item['lat'] as String), double.parse(item['lon'] as String)),
          ),
        )
        .toList();
  }
}
