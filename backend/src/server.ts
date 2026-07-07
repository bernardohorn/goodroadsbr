import { createApp } from './app';
import { env } from './config/env';
import { logger } from './core/logger/logger';
import { prisma } from './infra/database/prisma.client';

const app = createApp();

const server = app.listen(env.PORT, () => {
  logger.info(`GoodRoads API rodando na porta ${env.PORT} (${env.NODE_ENV})`);
});

/**
 * Desligamento gracioso (Etapa 6): ao receber SIGTERM (enviado por
 * orquestradores como Docker/Kubernetes ao parar o container) ou SIGINT
 * (Ctrl+C local), para de aceitar novas conexoes, deixa as requisicoes em
 * andamento terminarem, fecha a conexao com o banco e so entao encerra o
 * processo. Sem isso, um `docker stop`/deploy mata o processo na marra e
 * pode cortar uma requisicao no meio (ex.: um upload de foto ou uma
 * transacao do Prisma).
 *
 * Um timeout de seguranca forca o encerramento se o shutdown gracioso
 * demorar demais (ex.: uma conexao HTTP presa em keep-alive).
 */
let isShuttingDown = false;

async function shutdown(signal: string) {
  if (isShuttingDown) return;
  isShuttingDown = true;

  logger.info(`Recebido ${signal}, iniciando desligamento gracioso...`);

  const forceExitTimer = setTimeout(() => {
    logger.error('Desligamento gracioso excedeu o tempo limite, forcando saida.');
    process.exit(1);
  }, 10_000);
  forceExitTimer.unref();

  server.close(async (err) => {
    if (err) {
      logger.error({ err }, 'Erro ao fechar o servidor HTTP');
    }

    try {
      await prisma.$disconnect();
      logger.info('Conexao com o banco encerrada. Ate mais.');
      clearTimeout(forceExitTimer);
      process.exit(err ? 1 : 0);
    } catch (disconnectError) {
      logger.error({ err: disconnectError }, 'Erro ao desconectar do banco');
      clearTimeout(forceExitTimer);
      process.exit(1);
    }
  });
}

process.on('SIGTERM', () => void shutdown('SIGTERM'));
process.on('SIGINT', () => void shutdown('SIGINT'));

// Ultima linha de defesa: loga e derruba o processo em vez de deixar o
// Node continuar rodando em um estado potencialmente inconsistente. Um
// orquestrador de producao (Docker `restart: unless-stopped`, Kubernetes)
// deve reiniciar o container automaticamente apos isso.
process.on('unhandledRejection', (reason) => {
  logger.error({ err: reason }, 'unhandledRejection nao tratado');
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  logger.error({ err: error }, 'uncaughtException nao tratada');
  process.exit(1);
});
