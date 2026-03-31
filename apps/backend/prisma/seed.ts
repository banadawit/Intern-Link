import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const email = 'admin@internlink.com';
  const password = 'Admin@1234';

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    console.log(`Admin already exists: ${email}`);
    return;
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  await prisma.user.create({
    data: {
      full_name: 'System Admin',
      email,
      password_hash: hashedPassword,
      role: 'ADMIN',
      verification_status: 'APPROVED', // Admin is pre-approved, no email verification needed
    },
  });

  console.log('✅ Admin user created');
  console.log(`   Email:    ${email}`);
  console.log(`   Password: ${password}`);
  console.log('   ⚠️  Change this password after first login!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
