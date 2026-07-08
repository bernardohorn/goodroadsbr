# Abrir o Mapa focado na localização de uma ocorrência

## Contexto

Na tela de detalhes da ocorrência (`occurrence_details_page.dart`) já existe
um preview de mapa mostrando a localização exata da ocorrência (pin
vermelho sobre `FlutterMap`), mas ele é puramente visual: está envolto em
`IgnorePointer` e usa `InteractionOptions(flags: InteractiveFlag.none)`, ou
seja, um toque nele hoje não faz nada.

O app já tem uma tela "Mapa" (`MapPage`, rota `/mapa`, uma das abas do
`StatefulShellRoute`) que mostra ocorrências próximas a um ponto central,
mas esse centro hoje é sempre a localização atual do usuário (GPS via
`OsmMapProvider.currentPosition()`), obtida em `_loadInitialData()`.

## Objetivo

Ao tocar no preview de mapa da tela de detalhes, abrir a tela "Mapa" já
centralizada na localização daquela ocorrência específica, com o pin dela
destacado entre as ocorrências próximas.

## Design

### Navegação (`app_routes.dart`, `app_router.dart`)

- `AppRoutes` ganha um helper:
  ```dart
  static String mapFocusedOn({required double lat, required double lng, required String occurrenceId}) =>
      '$map?lat=$lat&lng=$lng&focusId=$occurrenceId';
  ```
- O `GoRoute` de `AppRoutes.map` passa a extrair `lat`, `lng` e `focusId` de
  `state.uri.queryParameters` (todos opcionais) e repassa para o
  construtor de `MapPage` (que deixa de ser `const`).

### `MapPage`

- Novos parâmetros opcionais no construtor: `focusLatitude`,
  `focusLongitude`, `focusOccurrenceId` (`double?`, `double?`, `String?`).
- `_loadInitialData()`:
  - Se `focusLatitude`/`focusLongitude` vierem preenchidos, o centro
    inicial do mapa e da busca de ocorrências próximas (`_loadPinsAround`)
    passa a ser esse ponto (zoom mais próximo, ex. 16), em vez do GPS do
    usuário.
  - A posição atual do usuário (GPS) continua sendo obtida em paralelo
    apenas para exibir o marcador "você está aqui" — sem influenciar o
    centro/zoom inicial quando há foco.
  - Sem foco (fluxo atual, acesso direto pela aba "Mapa"), nada muda.
- O pin cujo `id == focusOccurrenceId` é renderizado com destaque (ícone
  maior e cor diferenciada) em relação aos demais pins da
  `MarkerLayer`.
- O FAB "minha localização" passa a chamar um método dedicado que sempre
  recentraliza no GPS atual e recarrega os pins em torno dele,
  independentemente de haver um foco ativo (tocar nele "sai" do modo foco).

### `OccurrenceDetailsPage`

- O preview de mapa passa a ser envolto por um `GestureDetector` (mantendo
  o `FlutterMap` interno não-interativo, como hoje — é só uma prévia) cujo
  `onTap` chama
  `context.push(AppRoutes.mapFocusedOn(lat: occurrence.latitude, lng: occurrence.longitude, occurrenceId: occurrence.id))`.

## Fora de escopo

- Mudanças no contrato de API/backend (a ocorrência já traz `latitude`/
  `longitude`, nada novo é consumido).
- Alterar o comportamento do preview em si (continua estático, sem
  pan/zoom) — o toque nele serve só para navegar.
- Botão de "voltar" customizado na `MapPage`: o comportamento padrão do
  `go_router`/`Navigator` ao empilhar a rota já é suficiente.

## Teste

- Teste de widget cobrindo `MapPage` recebendo `focusLatitude`/
  `focusLongitude`/`focusOccurrenceId` e verificando que o centro inicial
  usado na busca de pins é o ponto de foco (não uma posição de GPS
  mockada).
- Teste cobrindo que o preview em `OccurrenceDetailsPage` dispara a
  navegação esperada (rota com os query params corretos) ao ser tocado.
