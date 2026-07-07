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
