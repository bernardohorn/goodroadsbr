/// Exceções específicas da aplicação relacionadas à localização.
/// São utilizadas para desacoplar a camada de apresentação das exceções
/// lançadas por bibliotecas externas.
library;

class AppLocationServiceDisabledException implements Exception {}

class AppLocationPermissionDeniedException implements Exception {}

class AppLocationPermissionPermanentlyDeniedException implements Exception {}
