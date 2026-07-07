export interface PushMessage {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Interface de envio de notificacoes push.
 *
 * Decisao do cliente (docs/DECISOES.md): usar Firebase Cloud Messaging
 * (FCM) para o app mobile. A implementacao concreta (`FcmPushProvider`)
 * entra no escopo do modulo de notificacoes (Etapa 5 do roadmap), quando o
 * cadastro do device token do cidadao tambem for implementado. Por ora,
 * `NoopPushProvider` apenas loga a intencao de envio, para que o restante
 * do backend (ex.: o service de ocorrencias, ao mudar status) ja possa
 * depender desta interface sem esperar a integracao real.
 */
export interface PushProvider {
  send(message: PushMessage): Promise<void>;
}
