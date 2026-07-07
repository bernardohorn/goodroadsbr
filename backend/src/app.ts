import path from 'path';
import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { randomUUID } from 'crypto';
import pinoHttp from 'pino-http';
import { env } from './config/env';
import { errorHandler } from './core/errors/errorHandler';
import { defaultRateLimiter } from './core/middlewares/rateLimiter';
import { metricsMiddleware, metricsHandler } from './core/observability/metrics';
import { logger } from './core/logger/logger';
import { prisma } from './infra/database/prisma.client';
import { authRoutes } from './modules/auth/auth.routes';
import { categoriesRoutes } from './modules/categories/categories.routes';
import { dashboardRoutes } from './modules/dashboard/dashboard.routes';
import { mapRoutes } from './modules/map/map.routes';
import { notificationsRoutes } from './modules/notifications/notifications.routes';
import { occurrencesRoutes } from './modules/occurrences/occurrences.routes';
import { reportsRoutes } from './modules/reports/reports.routes';
import { staffRoutes } from './modules/staff/staff.routes';
import { teamsRoutes } from './modules/teams/teams.routes';
import { usersRoutes } from './modules/users/users.routes';

export function createApp() {
  const app = express();

  // Necessario em producao atras de um reverse proxy/load balancer (Nginx,
  // Cloud Run, ELB etc.) para que `req.ip` e o rate limiter enxerguem o IP
  // real do cliente (via X-Forwarded-For) em vez do IP do proxy.
  if (env.isProduction) {
    app.set('trust proxy', 1);
  }

  app.use(
    helmet({
      // HSTS so faz sentido atras de HTTPS real (producao); em dev por HTTP
      // simples o header e ignorado pelos navegadores mesmo, mas evitamos
      // mandar a diretiva fora de producao para nao confundir testes locais.
      hsts: env.isProduction ? { maxAge: 15552000, includeSubDomains: true } : false
    })
  );
  app.use(
    cors({
      origin: env.corsOrigins.length > 0 ? env.corsOrigins : true,
      credentials: true
    })
  );
  app.use(express.json({ limit: '2mb' }));

  // Um ID de correlacao por requisicao, propagado pelo cliente (se enviado)
  // ou gerado aqui, ecoado em `X-Request-Id` e anexado a cada linha de log
  // dessa requisicao — essencial para rastrear um erro especifico em logs
  // agregados (ver docs/ARQUITETURA_GOODROADS.md, secao 12).
  app.use(
    pinoHttp({
      logger,
      autoLogging: !env.isTest,
      genReqId: (req, res) => {
        const existing = req.headers['x-request-id'];
        const id = (Array.isArray(existing) ? existing[0] : existing) ?? randomUUID();
        res.setHeader('X-Request-Id', id);
        return id;
      }
    })
  );
  app.use(metricsMiddleware);
  app.use(defaultRateLimiter);

  // Servidor de arquivos estaticos para o LocalDiskStorageProvider (dev).
  // Em producao com STORAGE_DRIVER=s3, esta rota simplesmente nao e usada
  // (as URLs de foto apontam direto para o bucket).
  if (env.STORAGE_DRIVER === 'local') {
    app.use('/uploads', express.static(path.resolve(process.cwd(), env.LOCAL_STORAGE_DIR)));
  }

  // Liveness: responde 200 sempre que o processo Node esta de pe, sem
  // depender de nenhuma dependencia externa. Usado por orquestradores
  // (Docker HEALTHCHECK, Kubernetes livenessProbe) para decidir se o
  // container precisa ser reiniciado.
  app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  // Readiness: so responde 200 se o banco estiver alcancavel. Usado por
  // orquestradores (readinessProbe) e load balancers para decidir se a
  // instancia deve receber trafego — evita mandar requisicoes para uma
  // instancia que subiu mas ainda nao consegue falar com o Postgres.
  app.get('/health/ready', async (_req, res) => {
    try {
      await prisma.$queryRaw`SELECT 1`;
      res.status(200).json({ status: 'ready', timestamp: new Date().toISOString() });
    } catch (error) {
      logger.error({ err: error }, 'Readiness check falhou: banco inalcancavel');
      res.status(503).json({ status: 'not_ready', timestamp: new Date().toISOString() });
    }
  });

  // Metricas no formato Prometheus (ver src/core/observability/metrics.ts).
  // Sem autenticacao propositalmente: em producao, deve ficar atras de uma
  // rede interna/VPC ou de um proxy que restrinja o acesso a essa rota, e
  // nao exposta publicamente junto com a API — pratica padrao em ambientes
  // com Prometheus fazendo scrape.
  app.get('/metrics', metricsHandler);

  app.use(`${env.API_PREFIX}/auth`, authRoutes);
  app.use(`${env.API_PREFIX}/users`, usersRoutes);
  app.use(`${env.API_PREFIX}/occurrences`, occurrencesRoutes);
  app.use(`${env.API_PREFIX}/categories`, categoriesRoutes);
  app.use(`${env.API_PREFIX}/teams`, teamsRoutes);
  app.use(`${env.API_PREFIX}/notifications`, notificationsRoutes);
  app.use(`${env.API_PREFIX}/map`, mapRoutes);
  app.use(`${env.API_PREFIX}/staff`, staffRoutes);
  app.use(`${env.API_PREFIX}/dashboard`, dashboardRoutes);
  app.use(`${env.API_PREFIX}/reports`, reportsRoutes);

  app.use((req, res) => {
    res.status(404).json({ error: { code: 'NOT_FOUND', message: `Rota ${req.method} ${req.path} nao existe.` } });
  });

  app.use(errorHandler);

  return app;
}
