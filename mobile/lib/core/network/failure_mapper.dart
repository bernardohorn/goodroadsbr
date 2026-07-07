import 'package:dio/dio.dart';
import '../error/failure.dart';
import 'api_exception.dart';

/// Converte qualquer erro capturado nos repositories em um `Failure`
/// tipado. Centralizar essa traducao aqui evita que cada repository
/// reimplemente a mesma logica de "que tipo de erro e esse".
Failure mapErrorToFailure(Object error) {
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) {
      switch (inner.statusCode) {
        case 401:
          return UnauthorizedFailure(inner.message);
        case 400:
          return ValidationFailure(inner.message, inner.details);
        default:
          return ServerFailure(inner.code, inner.message, inner.details);
      }
    }

    const networkErrorTypes = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    if (networkErrorTypes.contains(error.type)) {
      return const NetworkFailure();
    }
  }

  return const UnknownFailure();
}
