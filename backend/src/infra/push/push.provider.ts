import { env } from '../../config/env';
import { FcmPushProvider } from './FcmPushProvider';
import { NoopPushProvider } from './NoopPushProvider';
import { PushProvider } from './PushProvider';

// PUSH_DRIVER=fcm (Etapa 5) liga o envio real via Firebase Cloud Messaging;
// PUSH_DRIVER=noop (padrao) mantem o comportamento das Etapas 1-4, util
// para rodar o backend sem credenciais do Firebase configuradas (ex.: este
// sandbox de desenvolvimento, que nao tem como validar uma integracao real
// com o FCM).
export const pushProvider: PushProvider = env.PUSH_DRIVER === 'fcm' ? new FcmPushProvider() : new NoopPushProvider();
