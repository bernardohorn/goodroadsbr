import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contador incrementado sempre que o backend responde 401 mesmo apos uma
/// tentativa de refresh (ou seja: a sessao realmente expirou). A feature de
/// auth escuta este provider para limpar o estado local e redirecionar ao
/// login — assim o `core` (que nao pode depender de `features`) consegue
/// avisar a camada de auth sem conhece-la diretamente.
final sessionExpiredProvider = StateProvider<int>((ref) => 0);
