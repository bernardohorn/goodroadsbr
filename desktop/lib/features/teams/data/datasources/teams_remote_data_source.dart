import 'package:dio/dio.dart';
import '../models/team_model.dart';

/// Fonte de dados minima para os times de atendimento. Nao ha uma tela
/// "Times" no escopo do desktop (ver docs/ARQUITETURA_GOODROADS.md, secao
/// 7.5) — este feature existe apenas para alimentar o seletor "Equipe" no
/// dialog de atribuicao de ocorrencias.
class TeamsRemoteDataSource {
  const TeamsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<TeamModel>> list() async {
    final response = await _dio.get('/teams');
    return (response.data as List<dynamic>).map((t) => TeamModel.fromJson(t as Map<String, dynamic>)).toList();
  }
}
