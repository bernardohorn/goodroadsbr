/// Configuracao de ambiente do app. O valor padrao aponta para o backend
/// rodando localmente (ver backend/README.md). Em builds de
/// homologacao/producao, sobrescreva via `--dart-define=API_BASE_URL=...`.
class AppConfig {
  AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3333/api/v1',
  );
}
