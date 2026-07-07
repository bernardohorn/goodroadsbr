import { z } from 'zod';

export const registerSchema = {
  body: z.object({
    name: z.string().trim().min(3, 'Nome deve ter ao menos 3 caracteres').max(120),
    email: z.string().trim().toLowerCase().email('E-mail invalido'),
    password: z
      .string()
      .min(8, 'A senha deve ter ao menos 8 caracteres')
      .regex(/[a-z]/, 'A senha deve conter ao menos uma letra minuscula')
      .regex(/[A-Z]/, 'A senha deve conter ao menos uma letra maiuscula')
      .regex(/[0-9]/, 'A senha deve conter ao menos um numero'),
    cpf: z
      .string()
      .trim()
      .regex(/^\d{11}$/, 'CPF deve conter 11 digitos numericos')
      .optional(),
    birthDate: z.coerce.date().optional(),
    phone: z.string().trim().max(20).optional()
  })
};

export const loginSchema = {
  body: z.object({
    email: z.string().trim().toLowerCase().email('E-mail invalido'),
    password: z.string().min(1, 'Senha obrigatoria')
  })
};

export const refreshSchema = {
  body: z.object({
    refreshToken: z.string().min(1, 'refreshToken obrigatorio')
  })
};

export const logoutSchema = refreshSchema;

export const forgotPasswordSchema = {
  body: z.object({
    email: z.string().trim().toLowerCase().email('E-mail invalido')
  })
};

export const resetPasswordSchema = {
  body: z.object({
    token: z.string().min(1, 'token obrigatorio'),
    newPassword: z
      .string()
      .min(8, 'A senha deve ter ao menos 8 caracteres')
      .regex(/[a-z]/, 'A senha deve conter ao menos uma letra minuscula')
      .regex(/[A-Z]/, 'A senha deve conter ao menos uma letra maiuscula')
      .regex(/[0-9]/, 'A senha deve conter ao menos um numero')
  })
};
