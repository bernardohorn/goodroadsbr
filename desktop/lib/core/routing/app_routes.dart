/// Constantes de rota, para nao espalhar strings magicas por telas e
/// widgets. `go_router` e configurado em `app_router.dart` usando estes
/// mesmos valores. Ver docs/ARQUITETURA_GOODROADS.md, secao 7.5 (10 telas).
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';

  static const dashboard = '/';
  static const occurrences = '/ocorrencias';
  static const map = '/mapa';
  static const categories = '/categorias';
  static const staff = '/usuarios';
  static const reports = '/relatorios';
  static const settings = '/configuracoes';
  static const profile = '/perfil';

  static const occurrenceDetails = '/ocorrencias/:id';
  static String occurrenceDetailsPath(String id) => '/ocorrencias/$id';
}
