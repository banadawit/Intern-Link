import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function approveAllStudents() {
  const result = await prisma.student.updateMany({
    where: { hod_approval_status: 'PENDING' },
    data: { hod_approval_status: 'APPROVED' }
  });
  console.log(`Updated ${result.count} students to APPROVED`);
  
  // Also ensure the corresponding Users are APPROVED in verification_status
  const students = await prisma.student.findMany({ select: { userId: true } });
  const userResult = await prisma.user.updateMany({
    where: { 
      id: { in: students.map(s => s.userId) },
      verification_status: 'PENDING'
    },
    data: { verification_status: 'APPROVED' }
  });
  console.log(`Updated ${userResult.count} users to APPROVED`);
}

approveAllStudents().catch(console.error).finally(() => prisma.$disconnect());
