#!/usr/bin/env node
// PreToolUse (Bash, filtrado por `if: Bash(git commit*)`) — gate de commit do GoodRoads.
//
// 1) Bloqueia commit que traga segredos no stage (.env, chaves, service-account).
// 2) Roda os checks de qualidade ESCOPADOS pelo que esta staged:
//    - backend/*.ts       -> npm run lint + npm run typecheck (em backend/)
//    - mobile/*.dart|yaml  -> flutter analyze (em mobile/)
//    - desktop/*.dart|yaml -> flutter analyze (em desktop/)
//
// Executado como: node .claude/hooks/pre-commit-guard.mjs  (JSON do hook no stdin)
// Exit 2 = bloqueia o commit e devolve a mensagem (stderr) ao modelo.
import { readFileSync } from 'node:fs';
import { execSync } from 'node:child_process';

let raw = '';
try {
  raw = readFileSync(0, 'utf8');
} catch {
  process.exit(0);
}

let payload;
try {
  payload = JSON.parse(raw || '{}');
} catch {
  process.exit(0);
}

const command = String((payload.tool_input || {}).command || '');
// Reforca o filtro do `if` (defensivo): so age em `git commit`.
if (!/\bgit\s+commit\b/.test(command)) process.exit(0);

function sh(cmd, opts = {}) {
  return execSync(cmd, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], ...opts });
}

let staged = [];
try {
  staged = sh('git diff --cached --name-only')
    .split('\n')
    .map((s) => s.trim())
    .filter(Boolean);
} catch {
  process.exit(0); // sem repo/stage acessivel: nao atrapalha
}
if (staged.length === 0) process.exit(0);

// 1) Segredos nunca podem entrar num commit.
const secretRe = /(^|\/)\.env($|\.)|\.pem$|\.key$|firebase-service-account|(^|\/)keys\//i;
const secrets = staged.filter((f) => secretRe.test(f));
if (secrets.length) {
  process.stderr.write(
    `BLOQUEADO: arquivos sensiveis no stage do commit:\n  - ${secrets.join('\n  - ')}\n` +
      `Remova com "git restore --staged <arquivo>". Segredos nunca vao para o repositorio (ver CLAUDE.md).\n`
  );
  process.exit(2);
}

// 2) Checks de qualidade, so para os escopos que mudaram.
const has = (pred) => staged.some(pred);
const backendTs = has((f) => f.startsWith('backend/') && f.endsWith('.ts'));
const mobileDart = has((f) => f.startsWith('mobile/') && (f.endsWith('.dart') || f.endsWith('pubspec.yaml')));
const desktopDart = has((f) => f.startsWith('desktop/') && (f.endsWith('.dart') || f.endsWith('pubspec.yaml')));

const failures = [];
function runCheck(label, cmd, cwd) {
  try {
    sh(cmd, { cwd });
  } catch (err) {
    if (err && err.code === 'ENOENT') {
      process.stderr.write(`AVISO: pulei "${label}" (ferramenta nao encontrada no PATH).\n`);
      return;
    }
    const out = `${(err && err.stdout) || ''}${(err && err.stderr) || ''}`.trim();
    failures.push(`### ${label} falhou\n${out.slice(-4000)}`);
  }
}

if (backendTs) {
  runCheck('backend: npm run lint', 'npm run lint', 'backend');
  runCheck('backend: npm run typecheck', 'npm run typecheck', 'backend');
}
if (mobileDart) runCheck('mobile: flutter analyze', 'flutter analyze', 'mobile');
if (desktopDart) runCheck('desktop: flutter analyze', 'flutter analyze', 'desktop');

if (failures.length) {
  process.stderr.write(
    `BLOQUEADO: verificacoes de qualidade falharam antes do commit.\n\n${failures.join('\n\n')}\n\n` +
      `Corrija os problemas acima e tente commitar de novo (ou faca stage so do que passa).\n`
  );
  process.exit(2);
}

process.exit(0);
