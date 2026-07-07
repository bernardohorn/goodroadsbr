/**
 * Seed de desenvolvimento: cria os 3 papeis (roles), uma prefeitura de
 * exemplo, categorias padrao e um usuario funcionario para testes manuais.
 *
 * Executar com: npm run prisma:seed
 */
import { PrismaClient, RoleName } from '@prisma/client';
import argon2 from 'argon2';

const prisma = new PrismaClient();

async function main() {
  const roles = await Promise.all(
    Object.values(RoleName).map((name) =>
      prisma.role.upsert({
        where: { name },
        update: {},
        create: { name }
      })
    )
  );

  const funcionarioRole = roles.find((r) => r.name === RoleName.FUNCIONARIO)!;

  const municipality = await prisma.municipality.upsert({
    where: { slug: 'concordia' },
    update: {},
    create: {
      name: 'Prefeitura de Concordia',
      slug: 'concordia',
      primaryColor: '#1B7A3E'
    }
  });

  const categories = ['Buraco na via', 'Erosao', 'Ponte danificada', 'Alagamento', 'Sinalizacao'];
  await Promise.all(
    categories.map((name) =>
      prisma.category.upsert({
        where: { name },
        update: {},
        create: { name }
      })
    )
  );

  await prisma.team.upsert({
    where: { id: 'seed-team-a' },
    update: {},
    create: { id: 'seed-team-a', name: 'Time A', municipalityId: municipality.id }
  });

  const adminRole = roles.find((r) => r.name === RoleName.ADMIN)!;

  const passwordHash = await argon2.hash('Trocar@123', { type: argon2.argon2id });
  await prisma.user.upsert({
    where: { email: 'funcionario@goodroads.dev' },
    update: {},
    create: {
      name: 'Funcionario GoodRoads',
      email: 'funcionario@goodroads.dev',
      passwordHash,
      roleId: funcionarioRole.id,
      municipalityId: municipality.id
    }
  });

  // Conta ADMIN: unica com permissao para criar/editar outros funcionarios
  // (tela "Usuarios" do app desktop — ver docs/ARQUITETURA_GOODROADS.md, 7.5).
  await prisma.user.upsert({
    where: { email: 'admin@goodroads.dev' },
    update: {},
    create: {
      name: 'Administrador GoodRoads',
      email: 'admin@goodroads.dev',
      passwordHash,
      roleId: adminRole.id,
      municipalityId: municipality.id
    }
  });

  console.log('Seed concluido.');
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
