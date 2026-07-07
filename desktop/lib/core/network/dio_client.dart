import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

/// Cliente HTTP central da aplicacao. Responsavel por:
///  - anexar o access token JWT em toda requisicao autenticada;
///  - renovar a sessao automaticamente via refresh token quando o backend
///    responde 401 (com uma trava para nao disparar multiplos refreshes
///    simultaneos quando varias requisicoes falham ao mesmo tempo);
///  - traduzir o corpo de erro do backend (`{ error: { code, message } }`)
///    em `ApiException`, consumido pelos repositories para montar `Failure`.
///
/// Nenhuma outra camada do app deve instanciar `Dio` diretamente — todas
/// passam por aqui, garantindo que o comportamento de auth/refresh seja
/// consistente em toda a aplicacao.
class DioClient {
  DioClient({
    required SecureStorageService storage,
    required void Function() onSessionExpired,
  })  : _storage = storage,
        _onSessionExpired = onSessionExpired {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    _refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  final SecureStorageService _storage;
  final void Function() _onSessionExpired;

  late final Dio dio;
  late final Dio _refreshDio;
  Future<bool>? _refreshInFlight;

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null && !options.path.contains('/auth/refresh')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    final statusCode = error.response?.statusCode;
    final requestPath = error.requestOptions.path;
    final isAuthEndpoint = requestPath.contains('/auth/login') || requestPath.contains('/auth/refresh');

    if (statusCode == 401 && !isAuthEndpoint) {
      final refreshed = await _refreshSession();
      if (refreshed) {
        try {
          final retried = await dio.fetch(error.requestOptions);
          return handler.resolve(retried);
        } catch (_) {
          // cai para o tratamento de erro padrao abaixo
        }
      } else {
        _onSessionExpired();
      }
    }

    handler.next(_translate(error));
  }

  /// Garante uma unica requisicao de refresh em voo mesmo se varias
  /// chamadas 401'arem ao mesmo tempo. As demais aguardam o mesmo `Future`.
  Future<bool> _refreshSession() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _refreshDio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      final accessToken = response.data['accessToken'] as String;
      final newRefreshToken = response.data['refreshToken'] as String;
      await _storage.saveTokens(accessToken: accessToken, refreshToken: newRefreshToken);
      return true;
    } catch (_) {
      await _storage.clear();
      return false;
    }
  }

  DioException _translate(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      final errorBody = data['error'] as Map<String, dynamic>;
      final apiException = ApiException(
        statusCode: error.response?.statusCode,
        code: errorBody['code'] as String? ?? 'UNKNOWN_ERROR',
        message: errorBody['message'] as String? ?? 'Erro desconhecido.',
        details: errorBody['details'] as Map<String, dynamic>?,
      );
      return error.copyWith(error: apiException);
    }
    return error;
  }
}
