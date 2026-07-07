/// Erro estruturado extraido do corpo de resposta do backend
/// (`{ error: { code, message, details } }`, ver backend/src/core/errors).
class ApiException implements Exception {
  final int? statusCode;
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ApiException($code): $message';
}
