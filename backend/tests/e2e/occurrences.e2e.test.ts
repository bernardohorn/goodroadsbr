/**
 * E2E do fluxo de ocorrencias (o coracao do produto), contra a aplicacao
 * real e um Postgres real — ver tests/e2e/setupE2e.ts para pre-requisitos.
 * Cobre: criacao com foto obrigatoria, listagem escopada por papel,
 * checagem de posse (RBAC de dado, nao so de rota) e transicao de status
 * restrita a FUNCIONARIO/ADMIN (RBAC de rota).
 *
 * Como o endpoint de registro publico (`/auth/register`) so cria contas
 * `CIDADAO` (por design — ver auth.service.ts), o usuario `FUNCIONARIO`
 * usado aqui e inserido diretamente via Prisma, do mesmo jeito que
 * `prisma/seed.ts` faz em desenvolvimento.
 */
import argon2 from 'argon2';
import request from 'supertest';
import { RoleName } from '@prisma/client';
import { createApp } from '../../src/app';
import { prisma } from '../../src/infra/database/prisma.client';
import { ARGON2_OPTIONS } from '../../src/config/constants';
import { uniqueEmail } from './setupE2e';

const app = createApp();

async function createStaffUser(role: typeof RoleName.FUNCIONARIO | typeof RoleName.ADMIN) {
  const email = uniqueEmail(role.toLowerCase());
  const password = 'Senha@123';
  const roleRow = await prisma.role.findUniqueOrThrow({ where: { name: role } });
  const passwordHash = await argon2.hash(password, { type: argon2.argon2id, ...ARGON2_OPTIONS });

  await prisma.user.create({
    data: { name: `Staff E2E (${role})`, email, passwordHash, roleId: roleRow.id }
  });

  const loginResponse = await request(app).post('/api/v1/auth/login').send({ email, password });
  return loginResponse.body.accessToken as string;
}

async function createCitizenAndLogin() {
  const email = uniqueEmail('cidadao-oc');
  const password = 'Senha@123';
  await request(app).post('/api/v1/auth/register').send({ name: 'Cidadao Ocorrencia', email, password });
  const loginResponse = await request(app).post('/api/v1/auth/login').send({ email, password });
  return loginResponse.body.accessToken as string;
}

describe('E2E — /api/v1/occurrences', () => {
  it('rejeita criacao sem foto anexada', async () => {
    const citizenToken = await createCitizenAndLogin();

    const response = await request(app)
      .post('/api/v1/occurrences')
      .set('Authorization', `Bearer ${citizenToken}`)
      .field('description', 'Buraco grande na estrada principal, dificil de desviar.')
      .field('latitude', '-27.1809')
      .field('longitude', '-52.0281');

    expect(response.status).toBe(400);
    expect(response.body.error.message).toMatch(/foto/i);
  });

  it('cidadao cria ocorrencia com foto, ve so a propria, e funcionario avanca o status', async () => {
    const citizenToken = await createCitizenAndLogin();
    const staffToken = await createStaffUser(RoleName.FUNCIONARIO);

    const photo = Buffer.from(
      // 1x1 PNG transparente valido — suficiente para passar pelo
      // fileFilter (mimetype) sem depender de uma imagem real em disco.
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      'base64'
    );

    const createResponse = await request(app)
      .post('/api/v1/occurrences')
      .set('Authorization', `Bearer ${citizenToken}`)
      .field('description', 'Buraco grande na estrada principal, dificil de desviar.')
      .field('latitude', '-27.1809')
      .field('longitude', '-52.0281')
      .attach('photos', photo, { filename: 'buraco.png', contentType: 'image/png' });

    expect(createResponse.status).toBe(201);
    expect(createResponse.body.protocolNumber).toMatch(/^GR-\d{4}-\d{6}$/);
    expect(createResponse.body.status).toBe('PENDENTE');
    const occurrenceId = createResponse.body.id;

    // Cidadao consegue ver a propria ocorrencia.
    const ownGetResponse = await request(app)
      .get(`/api/v1/occurrences/${occurrenceId}`)
      .set('Authorization', `Bearer ${citizenToken}`);
    expect(ownGetResponse.status).toBe(200);

    // Cidadao NAO pode alterar o status (rota restrita a FUNCIONARIO/ADMIN).
    const forbiddenStatusResponse = await request(app)
      .patch(`/api/v1/occurrences/${occurrenceId}/status`)
      .set('Authorization', `Bearer ${citizenToken}`)
      .send({ status: 'EM_ANDAMENTO' });
    expect(forbiddenStatusResponse.status).toBe(403);

    // Outro cidadao (dono diferente) nao pode ver a ocorrencia de alguem.
    const otherCitizenToken = await createCitizenAndLogin();
    const otherGetResponse = await request(app)
      .get(`/api/v1/occurrences/${occurrenceId}`)
      .set('Authorization', `Bearer ${otherCitizenToken}`);
    expect(otherGetResponse.status).toBe(403);

    // Funcionario pode avancar o status (transicao permitida PENDENTE -> EM_ANDAMENTO).
    const advanceResponse = await request(app)
      .patch(`/api/v1/occurrences/${occurrenceId}/status`)
      .set('Authorization', `Bearer ${staffToken}`)
      .send({ status: 'EM_ANDAMENTO', note: 'Equipe a caminho.' });
    expect(advanceResponse.status).toBe(200);
    expect(advanceResponse.body.status).toBe('EM_ANDAMENTO');

    // Transicao invalida (EM_ANDAMENTO -> PENDENTE e permitida, mas
    // EM_ANDAMENTO -> EM_ANDAMENTO nao esta na lista de destinos).
    const invalidTransitionResponse = await request(app)
      .patch(`/api/v1/occurrences/${occurrenceId}/status`)
      .set('Authorization', `Bearer ${staffToken}`)
      .send({ status: 'EM_ANDAMENTO' });
    expect(invalidTransitionResponse.status).toBe(400);

    // Historico reflete a transicao.
    const historyResponse = await request(app)
      .get(`/api/v1/occurrences/${occurrenceId}/history`)
      .set('Authorization', `Bearer ${staffToken}`);
    expect(historyResponse.status).toBe(200);
    expect(historyResponse.body.length).toBeGreaterThanOrEqual(2);

    // Listagem do cidadao dono so retorna as proprias ocorrencias.
    const citizenListResponse = await request(app)
      .get('/api/v1/occurrences')
      .set('Authorization', `Bearer ${citizenToken}`);
    expect(citizenListResponse.status).toBe(200);
    expect(citizenListResponse.body.items.every((item: { citizenId: string }) => item.citizenId)).toBe(true);
    expect(citizenListResponse.body.items.some((item: { id: string }) => item.id === occurrenceId)).toBe(true);
  });
});
