import 'failure.dart';

/// Result generico ao estilo `Either`, implementado sem dependencia externa
/// (Dart 3 `sealed class` + `switch` ja cobre o pattern matching que
/// bibliotecas como fpdart ofereceriam). Toda operacao de repositorio
/// retorna `Result<T>` em vez de lancar excecao, tornando explicito nos
/// tipos quais chamadas podem falhar.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = ResultError<T>;

  R fold<R>(R Function(Failure failure) onFailure, R Function(T data) onSuccess) {
    final self = this;
    if (self is Success<T>) return onSuccess(self.data);
    if (self is ResultError<T>) return onFailure(self.failure);
    throw StateError('Result subtype nao tratado');
  }

  bool get isSuccess => this is Success<T>;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class ResultError<T> extends Result<T> {
  final Failure failure;
  const ResultError(this.failure);
}
