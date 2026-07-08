# Exibir latitude/longitude na revisão do registro de ocorrência

## Contexto

O app mobile já obtém a localização do cidadão via `geolocator`
(`OsmMapProvider.currentPosition()`), mostra essa posição no mapa (marcador
"você está aqui" no `MapPage`, e o pino arrastável na etapa "Localização" do
`RegisterOccurrencePage`) e já envia latitude/longitude ao backend ao
registrar uma ocorrência (`_submit()` em `register_occurrence_page.dart`).

O que falta: a etapa "Revisar" do fluxo de registro (`_ReviewStep`) mostra
apenas o endereço (reverse geocoding via Nominatim), nunca os valores
numéricos de latitude/longitude. O cidadão não tem como conferir a posição
exata antes de enviar.

## Escopo

Alteração restrita à camada de apresentação, em
`mobile/lib/features/occurrences/presentation/pages/register_occurrence_page.dart`:

- `_RegisterOccurrencePageState` passa `_pickedLocation` (já existente,
  tipo `LatLng?`) para `_ReviewStep`.
- `_ReviewStep` ganha um parâmetro `LatLng? location` e, no card de revisão,
  exibe duas linhas abaixo do endereço:
  - `Lat: <latitude.toStringAsFixed(6)>`
  - `Lng: <longitude.toStringAsFixed(6)>`
- Nenhuma mudança em `core/map`, `MapProviderContract`, domínio ou
  contrato de API — lat/lng já é capturado e já trafega para o backend hoje.
- Nenhuma dependência nova.

## Fora de escopo

- Botão de copiar coordenadas (descartado nesta rodada).
- Exibir coordenadas no `MapPage` geral (fora do fluxo de registro).
- Qualquer mudança em `google_maps_flutter` ou providers de mapa (segue
  100% OpenStreetMap/geolocator, sem novas dependências).

## Teste

- Teste de widget para `_ReviewStep` (ou teste do `RegisterOccurrencePage`
  cobrindo a etapa de revisão) verificando que, dado um `_pickedLocation`
  não nulo, o texto `Lat:` e `Lng:` com 6 casas decimais aparece na tela.
