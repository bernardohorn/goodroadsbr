import { NextFunction, Request, Response } from 'express';
import { AnyZodObject, ZodEffects } from 'zod';

type Schema = AnyZodObject | ZodEffects<AnyZodObject>;

/**
 * Middleware generico de validacao com zod. Cada modulo declara seu proprio
 * schema (`*.schema.ts`) para body/params/query e este middleware garante
 * que 100% das rotas validem a entrada antes de chegar no controller —
 * primeira linha de defesa contra payloads malformados e base da
 * sanitizacao (ver docs/ARQUITETURA_GOODROADS.md, secao 4.2).
 */
export function validate(schema: { body?: Schema; params?: Schema; query?: Schema }) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (schema.body) {
      req.body = schema.body.parse(req.body);
    }
    if (schema.params) {
      req.params = schema.params.parse(req.params) as typeof req.params;
    }
    if (schema.query) {
      req.query = schema.query.parse(req.query) as typeof req.query;
    }
    next();
  };
}
