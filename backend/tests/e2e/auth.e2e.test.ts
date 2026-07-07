/**
 * E2E do fluxo de autenticacao completo, contra a aplicacao real e um
 * Postgres real (ver tests/e2e/setupE2e.ts para pre-requisitos). Cobre o
 * caminho HTTP -> validate -> controller -> service -> repository -> Prisma
 * de ponta a ponta, incluindo a deteccao de reuso de refresh token, que os
 * testes unitarios (`tests/auth.service.test.ts`) ja cobrem com repository
 * mockado, mas vale confirmar aqui contra o banco de verdade.
 */
import request from 'supertest';
import { createApp } from '../../src/app';
import { uniqueEmail } from './setupE2e';

const app = createApp();

function validPassword() {
  return 'Senha@123';
}

describe('E2E — /api/v1/auth', () => {
  it('GET /health responde 200 sem depender de nada externo', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('ok');
  });

  it('GET /health/ready responde 200 quando o banco esta acessivel', async () => {
    const response = await request(app).get('/health/ready');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('ready');
  });

  it('GET /metrics expoe metricas no formato Prometheus', async () => {
    const response = await request(app).get('/metrics');
    expect(response.status).toBe(200);
    expect(response.text).toContain('http_request_duration_seconds');
  });

  it('registra um cidadao, faz login, acessa /users/me e faz logout', async () => {
    const email = uniqueEmail('cidadao');

    const registerResponse = await request(app).post('/api/v1/auth/register').send({
      name: 'Cidadao E2E',
      email,
      password: validPassword()
    });
    expect(registerResponse.status).toBe(201);
    expect(registerResponse.body.user.email).toBe(email);
    expect(registerResponse.body.user.passwordHash).toBeUndefined();
    expect(registerResponse.body.accessToken).toEqual(expect.any(String));
    expect(registerResponse.body.refreshToken).toEqual(expect.any(String));

    const duplicateResponse = await request(app).post('/api/v1/auth/register').send({
      name: 'Cidadao Duplicado',
      email,
      password: validPassword()
    });
    expect(duplicateResponse.status).toBe(409);

    const wrongPasswordResponse = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password: 'SenhaErrada@123' });
    expect(wrongPasswordResponse.status).toBe(401);

    const loginResponse = await request(app).post('/api/v1/auth/login').send({ email, password: validPassword() });
    expect(loginResponse.status).toBe(200);
    const { accessToken, refreshToken } = loginResponse.body;

    const meResponse = await request(app).get('/api/v1/users/me').set('Authorization', `Bearer ${accessToken}`);
    expect(meResponse.status).toBe(200);
    expect(meResponse.body.email).toBe(email);
    expect(meResponse.body.role.name).toBe('CIDADAO');

    const noTokenResponse = await request(app).get('/api/v1/users/me');
    expect(noTokenResponse.status).toBe(401);

    const refreshResponse = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });
    expect(refreshResponse.status).toBe(200);
    const rotatedRefreshToken = refreshResponse.body.refreshToken;
    expect(rotatedRefreshToken).not.toBe(refreshToken);

    // Reuso do refresh token antigo (ja rotacionado) deve ser rejeitado e,
    // pela regra de negocio, revogar TODA a sessao — inclusive o token novo.
    const reuseResponse = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });
    expect(reuseResponse.status).toBe(401);

    const rotatedTokenAfterReuseResponse = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: rotatedRefreshToken });
    expect(rotatedTokenAfterReuseResponse.status).toBe(401);

    const logoutResponse = await request(app).post('/api/v1/auth/logout').send({ refreshToken: rotatedRefreshToken });
    expect(logoutResponse.status).toBe(204);
  });

  it('rejeita registro com senha fraca (validacao zod)', async () => {
    const response = await request(app).post('/api/v1/auth/register').send({
      name: 'Cidadao Fraco',
      email: uniqueEmail('fraco'),
      password: '123'
    });
    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('forgot-password responde 200 mesmo para e-mail inexistente (evita enumeracao)', async () => {
    const response = await request(app).post('/api/v1/auth/forgot-password').send({ email: uniqueEmail('inexistente') });
    expect(response.status).toBe(200);
  });
});
