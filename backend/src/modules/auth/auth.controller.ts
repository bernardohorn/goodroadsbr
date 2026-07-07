import { Request, Response } from 'express';
import { AuthService } from './auth.service';

/**
 * Controllers apenas traduzem HTTP <-> Service. Nenhuma regra de negocio
 * aqui — se um dia a API ganhar uma versao GraphQL ou gRPC, o AuthService
 * e reaproveitado sem alteracoes.
 */
export class AuthController {
  constructor(private readonly service: AuthService = new AuthService()) {}

  register = async (req: Request, res: Response) => {
    const result = await this.service.register(req.body, {
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip
    });
    return res.status(201).json(result);
  };

  login = async (req: Request, res: Response) => {
    const result = await this.service.login(req.body, {
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip
    });
    return res.status(200).json(result);
  };

  refresh = async (req: Request, res: Response) => {
    const result = await this.service.refresh(req.body.refreshToken, {
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip
    });
    return res.status(200).json(result);
  };

  logout = async (req: Request, res: Response) => {
    await this.service.logout(req.body.refreshToken);
    return res.status(204).send();
  };

  forgotPassword = async (req: Request, res: Response) => {
    await this.service.forgotPassword(req.body.email);
    // Sempre 200, exista ou nao o e-mail (evita enumeracao de contas).
    return res.status(200).json({
      message: 'Se o e-mail informado estiver cadastrado, voce recebera as instrucoes de redefinicao.'
    });
  };

  resetPassword = async (req: Request, res: Response) => {
    await this.service.resetPassword(req.body.token, req.body.newPassword);
    return res.status(200).json({ message: 'Senha redefinida com sucesso.' });
  };
}
