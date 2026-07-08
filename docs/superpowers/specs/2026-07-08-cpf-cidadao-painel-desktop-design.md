# Exibir CPF do cidadão no painel administrativo (desktop)

## Contexto

O campo `cpf` já existe no model `User` do Prisma (`cpf String? @unique`) e
já é coletado no cadastro do cidadão pelo app mobile (`register_page.dart`
→ `POST /auth/register`), armazenado como 11 dígitos sem pontuação
(validado por `/^\d{11}$/` em `auth.schema.ts`). Não é necessária nenhuma
migration — o dado já existe no banco.

A tela de detalhes de ocorrência do desktop (`occurrence_details_page.dart`)
já tem um card "Cidadão" com Nome/E-mail/Telefone, alimentado pelo
`citizen: { select: { id, name, email, phone } }` dentro do
`occurrenceDetail` (Prisma include reutilizado tanto em `findById` quanto em
`findMany`, em `occurrences.repository.ts`). O CPF nunca foi incluído nesse
`select`.

## Escopo

- **Backend** (`occurrences.repository.ts`): adiciona `cpf: true` ao
  `select` do `citizen` em `occurrenceDetail`. Nenhuma mudança de RBAC —
  o acesso a esse payload já é controlado por `assertAccess`
  (`occurrences.service.ts`), o mesmo controle que já protege
  nome/e-mail/telefone hoje.
- **Desktop**:
  - `StaffOccurrence` (entity) e `StaffOccurrenceModel` ganham o campo
    `citizenCpf` (`String?`), parseado de `citizen?['cpf']`.
  - `occurrence_details_page.dart`, card "Cidadão": nova linha
    `_InfoRow(label: 'CPF', value: ...)`, logo após "Nome" (antes de
    E-mail/Telefone, mesma ordem de importância documental). CPF é
    formatado como `123.456.789-00` via uma função privada no próprio
    arquivo (`_formatCpf`, sem dependência nova — dado já vem só como
    dígitos). Sem CPF cadastrado → mostra `—` (mesmo padrão já usado nas
    outras linhas do card).
- **Mobile**: nenhuma mudança. O app do cidadão não tem (nem ganha) um
  card de dados do próprio cidadão na tela de ocorrência — o campo novo no
  payload é ignorado silenciosamente pelo parser JSON do `OccurrenceModel"
  mobile (que não lê `citizen` hoje).
- **Contrato de API**: `docs/api-contract.md` não existia neste repositório;
  criado documentando `GET /occurrences` e `GET /occurrences/:id`
  (as duas rotas que agora incluem `citizen.cpf` na resposta), incluindo
  RBAC e nota da mudança. Mudança é aditiva (novo campo opcional), não
  quebra nenhum cliente existente.

## Fora de escopo

- Adicionar CPF às colunas da tabela de listagem (`occurrences_list_page.dart`)
  — hoje nenhum dado de cidadão aparece ali (só protocolo/descrição/
  categoria/status/prioridade/data), CPF seguiria o mesmo padrão das outras
  informações de contato (só na tela de detalhes).
- Máscara de input/validação de CPF em qualquer formulário (não há
  formulário de CPF no desktop; o cadastro continua sendo feito só pelo
  cidadão no mobile).
- Qualquer mudança de RBAC ou de quem pode acessar detalhes de ocorrência.

## Teste

- Teste de widget do card "Cidadão" em `occurrence_details_page.dart`
  verificando que, dado um `StaffOccurrence` com `citizenCpf: '12345678900'`,
  aparece o texto formatado `123.456.789-00`; e que, com `citizenCpf: null`,
  aparece `—`.
- Teste unitário de `StaffOccurrenceModel.fromJson` cobrindo o parse de
  `citizen.cpf` (presente e ausente).
