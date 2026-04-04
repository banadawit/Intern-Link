import { PrismaClient, Role } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const adminEmail = 'cursorbana@gmail.com';
  const adminPassword = 'Admin@1234';

  let admin = await prisma.user.findUnique({ where: { email: adminEmail } });
  if (!admin) {
    const hashedPassword = await bcrypt.hash(adminPassword, 10);
    await prisma.user.create({
      data: {
        full_name: 'System Admin',
        email: adminEmail,
        password_hash: hashedPassword,
        role: 'ADMIN',
        verification_status: 'APPROVED',
        institution_access_approval: 'APPROVED',
      },
    });
    console.log('✅ Admin user created');
    console.log(`   Email:    ${adminEmail}`);
    console.log(`   Password: ${adminPassword}`);
    console.log('   ⚠️  Change this password after first login!');
  } else {
    console.log(`Admin already exists: ${adminEmail}`);
  }

  const supEmail = 'supervisor@company.com';
  const existingSup = await prisma.user.findUnique({ where: { email: supEmail } });
  if (!existingSup) {
    const company = await prisma.company.create({
      data: {
        name: 'Demo Company',
        official_email: 'company@demo.com',
        approval_status: 'APPROVED',
      },
    });
    await prisma.user.create({
      data: {
        full_name: 'Demo Supervisor',
        email: supEmail,
        password_hash: await bcrypt.hash('Super123!', 10),
        role: 'SUPERVISOR',
        verification_status: 'APPROVED',
        institution_access_approval: 'APPROVED',
        supervisorProfile: {
          create: {
            companyId: company.id,
          },
        },
      },
    });
    console.log('✅ Demo supervisor created');
    console.log(`   Email:    ${supEmail}`);
    console.log('   Password: Super123!');
  } else {
    console.log(`Supervisor already exists: ${supEmail}`);
  }

  // Shared demo university for coordinator + student (matches login demo emails @haramaya.edu)
  let demoUniversity = await prisma.university.findFirst({
    where: { official_email: 'official@haramaya.edu' },
  });
  if (!demoUniversity) {
    demoUniversity = await prisma.university.create({
      data: {
        name: 'Haramaya University',
        official_email: 'official@haramaya.edu',
        approval_status: 'APPROVED',
      },
    });
    console.log('✅ Demo university created (Haramaya University)');
  } else {
    console.log(`Demo university already exists: ${demoUniversity.name}`);
  }

  const coordEmail = 'coordinator@haramaya.edu';
  const coordExists = await prisma.user.findUnique({ where: { email: coordEmail } });
  if (!coordExists) {
    await prisma.user.create({
      data: {
        full_name: 'Demo Coordinator',
        email: coordEmail,
        password_hash: await bcrypt.hash('Coord123!', 10),
        role: 'COORDINATOR',
        verification_status: 'APPROVED',
        institution_access_approval: 'APPROVED',
        coordinatorProfile: {
          create: {
            universityId: demoUniversity.id,
            phone_number: null,
          },
        },
      },
    });
    console.log('✅ Demo coordinator created');
    console.log(`   Email:    ${coordEmail}`);
    console.log('   Password: Coord123!');
  } else {
    console.log(`Coordinator already exists: ${coordEmail}`);
  }

  const hodEmail = 'hod@haramaya.edu';
  /** Min 8 chars — matches login page validation */
  const hodPassword = 'Hod12345';
  const hodExists = await prisma.user.findUnique({ where: { email: hodEmail } });
  const hodHash = await bcrypt.hash(hodPassword, 10);
  if (!hodExists) {
    await prisma.user.create({
      data: {
        full_name: 'Demo Head of Department',
        email: hodEmail,
        password_hash: hodHash,
        role: Role.HOD,
        verification_status: 'APPROVED',
        institution_access_approval: 'APPROVED',
        hodProfile: {
          create: {
            universityId: demoUniversity.id,
            department: 'Computer Science',
          },
        },
      },
    });
    console.log('✅ Demo HOD created');
    console.log(`   Email:    ${hodEmail}`);
    console.log(`   Password: ${hodPassword}`);
  } else {
    await prisma.user.update({
      where: { email: hodEmail },
      data: { password_hash: hodHash },
    });
    console.log(`HOD already exists: ${hodEmail} (demo password refreshed to ${hodPassword})`);
  }

  const studentEmail = 'student@haramaya.edu';
  const studentExists = await prisma.user.findUnique({ where: { email: studentEmail } });
  if (!studentExists) {
    await prisma.user.create({
      data: {
        full_name: 'Demo Student',
        email: studentEmail,
        password_hash: await bcrypt.hash('Student123!', 10),
        role: 'STUDENT',
        verification_status: 'APPROVED',
        institution_access_approval: 'APPROVED',
        studentProfile: {
          create: {
            universityId: demoUniversity.id,
            registration_type: 'Official',
            department: 'Computer Science',
            internship_status: 'PENDING',
          },
        },
      },
    });
    console.log('✅ Demo student created');
    console.log(`   Email:    ${studentEmail}`);
    console.log('   Password: Student123!');
  } else {
    console.log(`Student already exists: ${studentEmail}`);
  }

  console.log('\n📌 Demo logins (frontend “Demo Login” menu):');
  console.log('   Admin:        admin@internlink.com / Admin@1234');
  console.log('   Supervisor:   supervisor@company.com / Super123!');
  console.log('   Coordinator:  coordinator@haramaya.edu / Coord123!');
  console.log('   HOD:          hod@haramaya.edu / Hod12345');
  console.log('   Student:      student@haramaya.edu / Student123!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
