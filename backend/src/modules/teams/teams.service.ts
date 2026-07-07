import { TeamsRepository } from './teams.repository';

export class TeamsService {
  constructor(private readonly repo: TeamsRepository = new TeamsRepository()) {}

  list(municipalityId: string | null) {
    return this.repo.findAll(municipalityId);
  }

  create(data: { name: string; municipalityId?: string | null }) {
    return this.repo.create(data);
  }
}
