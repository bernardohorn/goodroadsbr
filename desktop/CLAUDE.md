# GoodRoads Desktop (Flutter Desktop / Windows) — Claude Code Guide

App Flutter Desktop exclusivo para **funcionários da prefeitura**. Painel
administrativo: gerenciar ocorrências, estatísticas, mapas, relatórios e
funcionários.

## Mapas — regra inegociável

Mesma regra do mobile: apenas `flutter_map` + `Nominatim`. Nunca Google
Maps. O painel provavelmente exibirá múltiplos marcadores/clusters de
ocorrências — usar clustering (ex.: `flutter_map_marker_cluster`) para
performance com muitos pontos, não uma dependência de mapas diferente.

## Estrutura (Clean Architecture — espelha o mobile onde fizer sentido)

```
desktop/
├── lib/
│   ├── domain/
│   ├── data/
│   ├── presentation/
│   │   ├── pages/
│   │   │   ├── dashboard/       # estatísticas gerais
│   │   │   ├── ocorrencias/     # listagem, detalhe, mudança de status
│   │   │   ├── mapa/            # visão geral geográfica
│   │   │   ├── relatorios/      # exportação/relatórios
│   │   │   └── funcionarios/    # gestão de usuários internos (RBAC)
│   │   └── widgets/
│   └── core/
├── test/
└── pubspec.yaml
```

## RBAC no cliente

- A UI pode ocultar/mostrar ações conforme o papel do usuário logado, mas
  isso é só cosmético — a autorização real é sempre validada pelo backend.
  Nunca assumir que ocultar um botão é suficiente para proteger uma ação.
- Diferenciar claramente permissões de `funcionario` comum vs.
  `admin_prefeitura` (ex.: gestão de outros funcionários deve ser restrita
  a admin).

## UI e layout

- Material Design 3, mas adaptado a layout desktop: navegação lateral
  persistente, tabelas com paginação/filtro/ordenação, gráficos para
  estatísticas (ex.: `fl_chart` ou `syncfusion_flutter_charts`).
- Layout responsivo a diferentes tamanhos de janela — evitar valores fixos
  de largura/altura hardcoded nas telas principais.
- Exportação de relatórios: preferir formatos abertos (CSV/PDF) — se PDF,
  usar pacote Dart nativo, sem dependências pesadas desnecessárias.

## Comandos

```bash
flutter pub get
flutter run -d windows
flutter test
flutter analyze
flutter build windows --release
```

## Ao terminar uma tarefa

1. Rodar `flutter analyze` e `flutter test`.
2. Confirmar que nenhuma referência a Google Maps foi introduzida.
3. Confirmar que nenhuma tela do desktop expõe fluxo de "registrar
   ocorrência como cidadão" — isso pertence exclusivamente ao mobile.
