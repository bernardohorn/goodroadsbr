---
name: osm-guard
description: Verifica e garante que apenas OpenStreetMap (flutter_map, Geolocator, Nominatim) seja usado em qualquer código de mapas/geolocalização. Use SEMPRE que a tarefa envolver mapas, localização, marcadores, geocoding, coordenadas, tiles, ou antes de finalizar qualquer PR que toque em mobile/ ou desktop/. Bloqueia qualquer referência a Google Maps.
---

## Verificação automática

!`grep -rniE "google.?maps|google_maps_flutter|maps\.googleapis|AIza[0-9A-Za-z_-]{20,}" mobile/ desktop/ backend/ 2>/dev/null || echo "OK: nenhuma referencia a Google Maps encontrada"`

## Regra inegociável

O GoodRoads usa **exclusivamente OpenStreetMap**. Nunca introduza, sugira,
importe ou deixe como fallback:

- `google_maps_flutter` ou qualquer pacote Google Maps
- chamadas a `maps.googleapis.com`
- chaves de API do Google (`AIza...`)

Se o grep acima retornou qualquer linha (que não seja o "OK"), trate como
erro bloqueante: aponte o arquivo/linha e remova/substitua antes de
continuar.

## Stack correta

- **Tiles/renderização de mapa:** `flutter_map` (tiles OSM). Sempre definir
  um `tileProvider` com `User-Agent` que identifique o app.
- **Localização do dispositivo:** `geolocator` (pedir permissão, tratar
  negação e serviço desligado).
- **Geocoding / reverse geocoding:** `Nominatim` via HTTP.
  - Respeitar rate limit (máx. ~1 req/s), enviar `User-Agent` identificando
    o GoodRoads, e usar cache local quando possível.
  - Nunca fazer geocoding em loop sem debounce.
- **Muitos marcadores** (painel desktop): usar clustering
  (`flutter_map_marker_cluster`), não outra lib de mapa.

## Persistência de localização

Coordenadas de ocorrências são salvas como `latitude`/`longitude` numéricos
no backend. O Nominatim é usado só para exibir/formatar endereço — nunca
como fonte de verdade da posição.

## Checklist ao finalizar

1. Rodar o grep acima e confirmar "OK".
2. Confirmar que `pubspec.yaml` (mobile e desktop) não lista nenhum pacote
   Google Maps.
3. Confirmar que requisições ao Nominatim têm `User-Agent` e tratamento de
   erro/rate limit.
