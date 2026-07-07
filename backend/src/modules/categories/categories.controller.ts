import { Request, Response } from 'express';
import { CategoriesService } from './categories.service';

export class CategoriesController {
  constructor(private readonly service: CategoriesService = new CategoriesService()) {}

  list = async (req: Request, res: Response) => {
    // Cidadaos veem apenas categorias ativas; a equipe da prefeitura ve todas
    // (inclusive desativadas), para poder reativa-las quando necessario.
    const onlyActive = req.auth?.role === 'CIDADAO';
    const categories = await this.service.list(onlyActive);
    return res.status(200).json(categories);
  };

  create = async (req: Request, res: Response) => {
    const category = await this.service.create(req.body);
    return res.status(201).json(category);
  };

  update = async (req: Request, res: Response) => {
    const category = await this.service.update(req.params.id, req.body);
    return res.status(200).json(category);
  };
}
