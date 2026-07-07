/**
 * Gera um par de chaves RSA (2048 bits) para assinar/validar os JWTs em ambiente
 * de desenvolvimento. Em producao, as chaves devem ser geradas fora do repositorio
 * e injetadas via cofre de segredos (Vault, AWS Secrets Manager, etc.), nunca commitadas.
 */
const { generateKeyPairSync } = require('crypto');
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'keys', 'dev');
fs.mkdirSync(dir, { recursive: true });

const { publicKey, privateKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
});

fs.writeFileSync(path.join(dir, 'private.pem'), privateKey, { mode: 0o600 });
fs.writeFileSync(path.join(dir, 'public.pem'), publicKey, { mode: 0o644 });

console.log(`Chaves de desenvolvimento geradas em ${dir}`);
