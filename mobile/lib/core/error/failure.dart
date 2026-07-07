/// Hierarquia de falhas de dominio. Toda chamada de rede/repositorio que
/// pode falhar retorna um `Failure` (via `Result`, ver result.dart) em vez
/// de lancar excecoes cruas — a camada de apresentacao sempre sabe qual
/// mensagem mostrar ao usuario sem precisar interpretar excecoes do Dio.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexao com a internet. Verifique sua rede.']);
}

class ServerFailure extends Failure {
  final String code;
  final Map<String, dynamic>? details;
  const ServerFailure(this.code, super.message, [this.details]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sessao expirada. Faca login novamente.']);
}

class ValidationFailure extends Failure {
  final Map<String, dynamic>? details;
  const ValidationFailure(super.message, [this.details]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocorreu um erro inesperado. Tente novamente.']);
}
