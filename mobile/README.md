# GoodRoads — Mobile (Cidadão)

App Flutter para o cidadão (Android/iOS): registrar ocorrências em estradas rurais e acompanhar seu andamento. Ver arquitetura completa em `../docs/ARQUITETURA_GOODROADS.md`, seção 7.

## Status (Etapa 5)

Implementadas as 8 telas principais do app:

1. Login · 2. Cadastro · 3. Início (Home) · 4. Registrar ocorrência (wizard de 4 passos: localização → descrição → foto → enviar) · 5. Mapa · 6. Histórico (abas "Minhas ocorrências" / "Todas as ocorrências") · 7. Detalhes da ocorrência (fotos, localização, linha do tempo de status) · 8. Perfil.

Também implementado: autenticação completa (login, cadastro, recuperação de senha via bottom sheet, refresh token automático com fila de retry), Clean Architecture em todas as features (`domain` → `data` → `presentation`), tema Material 3 claro/escuro, camada de mapas desacoplada do provedor (OpenStreetMap + Nominatim), compressão de imagem antes do upload, skeleton loading e empty states reutilizáveis, navegação com `go_router` (shell com barra inferior + redirecionamento automático conforme sessão).

Implementado nesta etapa (Etapa 5 — push real + sincronização offline, ver `core/push/` e `core/offline/`):

- **Push notifications**: registro/remoção do device token no backend a cada login/logout (`core/push/device_registration_repository.dart`), exibição em foreground via `flutter_local_notifications` (o FCM não mostra notificação sozinho com o app aberto) e navegação até a ocorrência ao tocar na notificação.
- **Sincronização offline**: se o registro de uma ocorrência falhar por falta de conexão, ela é salva localmente (`core/offline/offline_database.dart`, `sqflite`) com as fotos copiadas para um diretório persistente, e reenviada automaticamente quando a conectividade volta (`connectivity_plus`) — ou manualmente pelo banner "N ocorrência(s) aguardando envio" na Home. Até 5 tentativas por item.

**Passo obrigatório antes de compilar com push funcionando:** rode `flutterfire configure` (Firebase CLI + login, apontando para um projeto Firebase real) na raiz de `mobile/`. Esse comando gera `lib/firebase_options.dart` e os arquivos nativos (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`), que **não existem neste repositório** — não foi possível gerá-los neste ambiente de desenvolvimento (sem Firebase CLI nem projeto Firebase real disponíveis). Sem esse passo, o app não compila com as dependências de Firebase adicionadas; se quiser rodar o app sem push por enquanto, remova temporariamente `firebase_core`/`firebase_messaging` do `pubspec.yaml` e a inicialização em `lib/main.dart`.

Ainda **não** implementado (próximas etapas): hardening de segurança e testes end-to-end, produção (Docker, CI/CD, observabilidade) — ver `../docs/ARQUITETURA_GOODROADS.md`, seção 10.

## Pré-requisitos

- Flutter SDK (canal stable, compatível com `environment.sdk` do `pubspec.yaml`).
- Backend rodando localmente (ver `../backend/README.md`) ou uma URL de API acessível.

## Como rodar

```bash
cd mobile
flutter pub get

# Aponta para o backend (padrão: http://localhost:3333/api/v1)
flutter run --dart-define=API_BASE_URL=http://localhost:3333/api/v1
```

> No emulador Android, `localhost` do host não é acessível diretamente — use `http://10.0.2.2:3333/api/v1` como `API_BASE_URL` ao rodar no emulador padrão do Android Studio.

## Testes

```bash
flutter test
```

## Nota sobre o ambiente de desenvolvimento

Este código foi escrito em um ambiente sem acesso ao Flutter/Dart SDK nem ao `pub.dev` (rede restrita), portanto não foi possível rodar `flutter pub get`, `flutter analyze` ou `flutter test` durante o desenvolvimento. A verificação feita foi estática: balanceamento de chaves/parênteses em todos os arquivos `.dart`, resolução de 100% dos imports relativos, e checagem de que cada provider/classe referenciado (ex.: nas rotas do `go_router`) tem exatamente uma definição correspondente no código. Rode `flutter pub get && flutter analyze && flutter test` como primeiro passo no seu ambiente — é esperado que o resolvedor de pacotes precise ajustar a versão exata do `intl` para a que o `flutter_localizations` da sua versão do Flutter exige (o próprio `flutter pub get` informa a versão certa nesse caso).

## Estrutura

Ver `../docs/ARQUITETURA_GOODROADS.md`, seção 7.2, para a organização completa de `core/` e `features/`.
