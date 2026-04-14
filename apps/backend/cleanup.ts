import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const email = 'aregashbula@gmail.com';
  
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    console.log('User not found — already deleted.');
    await prisma.$disconnect();
    return;
  }
  
  console.log(`Found user ID: ${user.id}, role: ${user.role}`);
  
  const uid = user.id;
  await prisma.$executeRaw`DELETE FROM "Notification" WHERE "recipientId" = ${uid}`;
  await prisma.$executeRaw`DELETE FROM "AiChatMessage" WHERE "userId" = ${uid}`;
  await prisma.$executeRaw`DELETE FROM "activity_logs" WHERE "userId" = ${uid}`;
  await prisma.$executeRaw`DELETE FROM "PostLike" WHERE "userId" = ${uid}`;
  await prisma.$executeRaw`DELETE FROM "PostComment" WHERE "authorId" = ${uid}`;
  await prisma.$executeRaw`DELETE FROM "PostView" WHERE "userId" = ${uid}`;
  await prisma.$executeRaw`DELETE FROM "PostReport" WHERE "reporterId" = ${uid}`;
  await prisma.$executeRaw`DELETE FROM "CommonPost" WHERE "authorId" = ${uid}`;
  await prisma.$executeRaw`DELETE FROM "Hod" WHERE "userId" = ${uid}`;
  await prisma.$executeRaw`DELETE FROM "HodProfile" WHERE "userId" = ${uid}`;
  await prisma.$executeRaw`DELETE FROM "User" WHERE id = ${uid}`;
  
  console.log(`✅ User ${uid} (${email}) fully deleted.`);
  await prisma.$disconnect();
}

main().catch(console.error);
