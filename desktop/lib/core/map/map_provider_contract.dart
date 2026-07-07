import 'package:flutter_map/flutter_map.dart';
import 'geocoding_result.dart';

/// Abstrai tudo que a tela de Mapa do desktop precisa, isolando a
/// implementacao concreta baseada em OpenStreetMap (ver
/// docs/ARQUITETURA_GOODROADS.md, secao 6). Se um dia for necessario trocar
/// de provedor de tiles ou de geocodificacao, basta criar uma nova
/// implementacao desta interface — nenhuma tela precisa mudar.
///
/// Diferente do app mobile, o desktop nao le a posicao atual do dispositivo
/// (o funcionario trabalha de um escritorio, nao em campo) — por isso o
/// contrato aqui e mais enxuto, sem `currentPosition`/`watchPosition`.
abstract class MapProviderContract {
  TileLayer buildTileLayer();

  Future<List<GeocodingResult>> geocode(String query);
}
