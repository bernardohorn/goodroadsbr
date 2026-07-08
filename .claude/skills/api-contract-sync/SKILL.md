---
name: api-contract-sync
description: Mantém o contrato de API sincronizado entre backend, mobile e desktop quando uma rota, DTO ou schema muda. Use sempre que criar/alterar/remover um endpoint, mudar formato de request/response, ou renomear campos que trafegam entre backend e os apps Flutter.
---

## Por que existe

O backend é consumido por dois clientes Flutter independentes (mobile e
desktop). Uma mudança de contrato que não é propagada quebra silenciosamente
um dos apps. Esta skill garante que a mudança seja documentada e o impacto
seja avisado.

## Contrato atual (se existir)

!`cat docs/api-contract.md 2>/dev/null | head -80 || echo "docs/api-contract.md ainda nao existe — criar."`

## Passos

1. **Atualizar `docs/api-contract.md`** com a rota afetada, contendo:
   - Método + caminho (`POST /api/v1/ocorrencias`)
   - Papéis autorizados (RBAC)
   - Schema de request (campos, tipos, obrigatoriedade)
   - Schema de response (200) e formato de erro
   - Nota de versão/data da mudança

2. **Mapear impacto nos clientes**. Verifique onde o campo/rota é usado:

   !`grep -rniE "api/v1|ocorrenc|/auth|/usuario" mobile/lib desktop/lib 2>/dev/null | head -40 || echo "(sem matches ou pastas ausentes)"`

3. **Avisar explicitamente** quais dos dois apps (mobile/desktop) precisam
   de ajuste no model/datasource correspondente. Não fazer a edição nos
   apps automaticamente sem o usuário pedir — apenas listar o que muda.

## Regras

- Mudança que quebra compatibilidade (remover/renomear campo, mudar tipo)
  deve ser destacada como **breaking change** e, se possível, versionada
  (`/api/v2` ou campo opcional durante transição).
- Papéis (RBAC) fazem parte do contrato: se a autorização de uma rota muda,
  documentar.
- Nunca deixar o contrato desatualizado após mexer numa rota — este é o
  passo final obrigatório de qualquer tarefa que toque a API.
