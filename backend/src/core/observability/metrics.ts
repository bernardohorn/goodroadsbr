import { NextFunction, Request, Response } from 'express';
import client from 'prom-client';

/**
 * Metricas Prometheus (Etapa 6). `prom-client` coleta metricas padrao do
 * processo Node (uso de memoria, event loop lag, CPU etc.) automaticamente
 * via `collectDefaultMetrics`, e registramos aqui uma metrica de negocio
 * simples: duracao e contagem de requisicoes HTTP por rota/metodo/status.
 *
 * Por que um registry proprio (`registry`) em vez do registry global do
 * `prom-client`: evita duplicar metricas se `createApp()` for chamado mais
 * de uma vez no mesmo processo (acontece nos testes, que sobem varias
 * instancias do app via supertest).
 */
export const registry = new client.Registry();
client.collectDefaultMetrics({ register: registry });

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duracao das requisicoes HTTP em segundos',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5],
  registers: [registry]
});

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total de requisicoes HTTP',
  labelNames: ['method', 'route', 'status_code'],
  registers: [registry]
});

/**
 * Usa `req.route`/`baseUrl` quando disponivel para agrupar por rota
 * parametrizada (ex.: `/api/v1/occurrences/:id`) em vez do path cru — evita
 * explosao de series temporais (cardinalidade) com um UUID diferente por
 * requisicao.
 */
function resolveRouteLabel(req: Request): string {
  const routePath = req.route?.path as string | undefined;
  if (routePath) {
    return `${req.baseUrl}${routePath}`;
  }
  return req.baseUrl || req.path;
}

export function metricsMiddleware(req: Request, res: Response, next: NextFunction) {
  const stopTimer = httpRequestDuration.startTimer();

  res.on('finish', () => {
    const labels = {
      method: req.method,
      route: resolveRouteLabel(req),
      status_code: String(res.statusCode)
    };
    stopTimer(labels);
    httpRequestsTotal.inc(labels);
  });

  next();
}

export async function metricsHandler(_req: Request, res: Response) {
  res.setHeader('Content-Type', registry.contentType);
  res.send(await registry.metrics());
}
