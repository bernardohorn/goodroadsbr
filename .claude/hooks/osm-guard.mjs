#!/usr/bin/env node
// PreToolUse (Write|Edit|MultiEdit) — guardrail do GoodRoads.
// Bloqueia qualquer edicao que introduza Google Maps nos apps Flutter
// (regra OSM-only, a mais inviolavel do projeto — ver CLAUDE.md). Usa apenas
// flutter_map + Geolocator + Nominatim (OpenStreetMap).
//
// Executado como: node .claude/hooks/osm-guard.mjs   (recebe o JSON do hook no stdin)
// Exit 2 = bloqueia a chamada da tool e devolve a mensagem (stderr) ao modelo.
import { readFileSync } from 'node:fs';

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

const input = payload.tool_input || {};
const filePath = String(input.file_path || '').replace(/\\/g, '/');

// A regra OSM-only se aplica aos apps Flutter (mobile/ e desktop/) e ao
// pubspec.yaml (onde uma dependencia do Google Maps entraria). O backend nao
// tem mapas, entao nao ha o que checar la.
const relevant = /\/(mobile|desktop)\//.test(filePath) || /pubspec\.ya?ml$/.test(filePath);
if (!relevant) process.exit(0);

// Junta todo o texto que esta sendo escrito/editado (Write, Edit, MultiEdit).
const chunks = [];
if (typeof input.content === 'string') chunks.push(input.content);
if (typeof input.new_string === 'string') chunks.push(input.new_string);
if (Array.isArray(input.edits)) {
  for (const e of input.edits) {
    if (e && typeof e.new_string === 'string') chunks.push(e.new_string);
  }
}
const text = chunks.join('\n');
if (!text) process.exit(0);

const forbidden = [
  /google_maps_flutter/i,
  /google_maps/i,
  /com\.google\.android\.gms\.maps/i,
  /maps\.googleapis\.com/i,
  /\bGMSServices\b/,
  /\bGoogleMap\s*\(/,
];

const hit = forbidden.find((re) => re.test(text));
if (hit) {
  process.stderr.write(
    `BLOQUEADO (regra OSM-only do GoodRoads): a edicao em "${filePath}" introduz ` +
      `referencia a Google Maps (padrao: ${hit}). Use apenas flutter_map + Geolocator + ` +
      `Nominatim (OpenStreetMap). Ver CLAUDE.md e a skill osm-guard.\n`
  );
  process.exit(2);
}

process.exit(0);
