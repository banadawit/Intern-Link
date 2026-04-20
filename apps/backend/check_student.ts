import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function checkStudent() {
  const users = await prisma.user.findMany({
    where: { role: 'STUDENT' },
    include: { studentProfile: true }
  });
  console.log(JSON.stringify(users, null, 2));
}

checkStudent().catch(console.error).finally(() => prisma.$disconnect());
