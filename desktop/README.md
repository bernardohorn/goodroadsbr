# GoodRoads — Desktop (Funcionário da Prefeitura)

App Flutter para Windows usado pela equipe da prefeitura para gerenciar as ocorrências reportadas pelos cidadãos. Ver arquitetura completa em `../docs/ARQUITETURA_GOODROADS.md`, seção 7.

## Status (Etapa 4)

Implementadas as 10 telas principais (escopo expandido a pedido do cliente — ver `../docs/DECISOES.md`, entrada "Escopo do app Desktop expandido"):

1. Login · 2. Dashboard (cards de indicadores + gráfico mensal + distribuição por categoria + ocorrências recentes) · 3. Ocorrências (lista com busca/filtros de status, prioridade e categoria/ordenação/paginação) · 4. Detalhes da ocorrência (fotos, mapa, classificação, dados do cidadão, histórico, ações de mudar status e atribuir/classificar) · 5. Mapa (clustering, busca de endereço via Nominatim, filtros aplicados ao backend) · 6. Categorias (CRUD) · 7. Usuários (gestão de funcionários — leitura para toda a equipe, criação/edição restrita a `ADMIN`) · 8. Relatórios (exportação de ocorrências filtradas em CSV ou PDF) · 9. Configurações (tema claro/escuro/sistema, preferência de notificação local, informações do app) · 10. Perfil (dados da própria conta, troca de senha, logout).

Não há tela de cadastro: contas de funcionário só são criadas por um `ADMIN` na tela "Usuários" — diferente do app mobile, onde o cidadão se cadastra sozinho.

Também implementado: barra lateral fixa de navegação (substitui a barra inferior do mobile — cabe mais itens sem menu "mais"), Clean Architecture em todas as features (`domain` → `data` → `presentation`), Riverpod (sem codegen), `go_router` com `StatefulShellRoute` + redirecionamento automático conforme sessão, rejeição no cliente de login de conta `CIDADAO` (o backend já bloqueia via RBAC em toda rota de funcionário; o cliente apenas dá uma mensagem clara em vez de uma tela cheia de erros 403), tema Material 3 claro/escuro compartilhando a paleta do app mobile, camada de mapas desacoplada do provedor (`MapProviderContract` + `OsmMapProvider`, sem GPS — o funcionário trabalha de um escritório, não em campo).

**Decisões técnicas registradas nesta etapa** (ver `../docs/DECISOES.md` para o histórico completo):

- A tela Configurações cobre apenas preferências reais do cliente (tema, notificação local, informações do app) — não simula um módulo de "configurações do sistema" que não existe no backend.
- Não há tela "Times/Equipes": o backend tem esse conceito (usado no dialog de atribuição de ocorrências, como um seletor), mas não foi pedido como tela própria pelo cliente.

**Limitação do ambiente:** sem acesso ao Flutter/Dart SDK nem ao pub.dev neste sandbox, não foi possível rodar `flutter pub get`, `flutter analyze` ou `flutter test`. Verificação estática apenas (balanceamento de chaves/parênteses/colchetes em todos os 121 arquivos `.dart`, resolução de 100% dos imports relativos, checagem de que cada página referenciada no `go_router` tem exatamente uma definição). Rode `flutter pub get && flutter analyze && flutter test` no seu ambiente como primeiro passo.

## Pré-requisitos

- Flutter SDK (canal stable) com suporte a build Windows habilitado (`flutter config --enable-windows-desktop`).
- Backend rodando localmente (ver `../backend/README.md`), já com o seed executado (`npm run prisma:seed`) — ele cria as contas de teste `funcionario@goodroads.dev` e `admin@goodroads.dev`, ambas com senha `Trocar@123`.

## Como rodar

```bash
cd desktop
flutter pub get

flutter run -d windows --dart-define=API_BASE_URL=http://localhost:3333/api/v1
```

## Testes

```bash
flutter test
```

## Estrutura

Mesma organização de `core/` + `features/` do app mobile (ver `../docs/ARQUITETURA_GOODROADS.md`, seção 7.2), com features próprias do desktop: `dashboard`, `staff`, `reports`, `settings`, além de versões mais ricas de `occurrences` (inclui equipe, responsável e dados do cidadão, não expostos ao papel `CIDADAO`) e `map` (com clustering).
