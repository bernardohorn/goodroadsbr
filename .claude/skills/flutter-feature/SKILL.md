---
name: flutter-feature
description: Cria uma nova feature/tela nos apps Flutter (mobile de cidadãos OU desktop da prefeitura) seguindo Clean Architecture (domain/data/presentation), Material Design 3 e o state management adotado no projeto. Use quando o usuário pedir uma nova tela, fluxo, feature ou funcionalidade em mobile/ ou desktop/.
---

## Antes de começar: identifique o app

- `mobile/` = **somente cidadãos**. Registrar/acompanhar ocorrências. Nunca
  adicionar painel administrativo, gestão de funcionários ou aprovação de
  ocorrências aqui.
- `desktop/` = **somente funcionários/prefeitura**. Gestão, estatísticas,
  mapas, relatórios. Nunca adicionar o fluxo de "registrar ocorrência como
  cidadão" aqui.

Se a feature pedida não pertence ao app em questão, pare e avise o usuário.

## Estrutura da feature (slice vertical)

```
lib/
├── domain/
│   ├── entities/<feature>.dart          # objeto puro, sem libs externas
│   ├── repositories/<feature>_repo.dart # interface abstrata
│   └── usecases/<acao>_usecase.dart
├── data/
│   ├── models/<feature>_model.dart      # fromJson/toJson
│   ├── datasources/<feature>_remote.dart# chama a API (nunca o banco direto)
│   └── repositories/<feature>_repo_impl.dart
└── presentation/
    ├── pages/<feature>_page.dart
    ├── widgets/
    └── controllers/                     # provider/bloc/riverpod do projeto
```

## Regras obrigatórias

- **Material Design 3** (`useMaterial3: true`); reusar tema central, não
  hardcodar cores/tamanhos soltos.
- **State management único**: usar a abordagem já adotada no app (não
  misturar Riverpod + Bloc). Verificar o que já existe antes de escolher.
- **Estados de UI**: toda tela trata `loading`, `erro` e `vazio`
  explicitamente. Nunca deixar tela sem feedback.
- **Sem acesso direto ao banco**: o Flutter só fala com o backend via HTTP.
- **Mapas/localização**: se a feature usar mapa ou GPS, seguir `osm-guard`
  (flutter_map + geolocator + Nominatim, nunca Google).
- **RBAC no desktop**: ocultar ações por papel é só cosmético; a
  autorização real é do backend.

## Ao finalizar

1. `flutter analyze && flutter test`.
2. `grep -rni "google_maps" lib/ pubspec.yaml` deve vir vazio.
3. Se consome um endpoint novo/alterado, conferir `docs/api-contract.md`.
