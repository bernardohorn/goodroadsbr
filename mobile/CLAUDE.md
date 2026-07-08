# GoodRoads Mobile (Flutter) — Claude Code Guide

App Flutter exclusivo para **cidadãos**. Permite registrar ocorrências com
foto, localização (OpenStreetMap) e descrição, e acompanhar o status da
solicitação.

## Mapas — regra inegociável

- Somente `flutter_map` (tiles OSM) + `geolocator` (localização do
  dispositivo) + `Nominatim` (geocoding/reverse geocoding via HTTP).
- **Nunca** adicionar `google_maps_flutter` ou qualquer dependência que
  exija chave de API do Google.
- Respeitar a política de uso do Nominatim (rate limit, `User-Agent`
  identificando o app) — não fazer requisições em excesso; usar cache local
  quando fizer sentido.

## Estrutura (Clean Architecture)

```
mobile/
├── lib/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/       # interfaces abstratas
│   │   └── usecases/
│   ├── data/
│   │   ├── repositories/       # implementações concretas
│   │   ├── datasources/        # remote (API) e local (cache/DB)
│   │   └── models/             # DTOs com fromJson/toJson
│   ├── presentation/
│   │   ├── pages/
│   │   ├── widgets/
│   │   └── controllers/        # ou providers/blocs, conforme state mgmt escolhido
│   └── core/                   # DI, temas, erros, constantes
├── test/
└── pubspec.yaml
```

## UI

- Material Design 3 (`useMaterial3: true`).
- Fluxo principal: registrar ocorrência (foto + localização + descrição) →
  acompanhar status → notificações de atualização.
- Sempre tratar estados de loading/erro/vazio explicitamente nas telas —
  nunca deixar tela travada sem feedback visual.
- Suporte offline básico desejável: permitir rascunho de ocorrência salvo
  localmente se não houver conexão no momento do registro.

## State management e DI

- Definir uma escolha única (ex.: Riverpod ou Bloc) e ser consistente em
  todo o app — não misturar abordagens diferentes entre telas.
- Injeção de dependência centralizada (ex.: `get_it` ou provider da
  ferramenta de state management escolhida).

## Comandos

```bash
flutter pub get
flutter run
flutter test
flutter analyze
flutter build apk --release
flutter build ios --release
```

## Ao terminar uma tarefa

1. Rodar `flutter analyze` e `flutter test`.
2. Confirmar que nenhuma referência a Google Maps foi introduzida
   (`grep -r "google_maps" lib/ pubspec.yaml`).
3. Se a tarefa mudou o contrato consumido da API, avisar que o backend/
   `docs/api-contract.md` pode precisar de revisão.
