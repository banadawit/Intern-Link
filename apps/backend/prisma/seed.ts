import { PrismaClient, Role } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const adminEmail = 'admin@internlink.com';
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
  } else {
    // Ensure password is always in sync with the seed value
    const hashedPassword = await bcrypt.hash(adminPassword, 10);
    await prisma.user.update({
      where: { email: adminEmail },
      data: { password_hash: hashedPassword },
    });
    console.log(`Admin already exists: ${adminEmail} (password refreshed)`);
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

  console.log('\n📌 Demo logins (frontend "Demo Login" menu):');
  console.log('   Admin:        admin@internlink.com / Admin@1234');
  console.log('   Supervisor:   supervisor@company.com / Super123!');
  console.log('   Coordinator:  coordinator@haramaya.edu / Coord123!');
  console.log('   HOD:          hod@haramaya.edu / Hod12345');
  console.log('   Student:      student@haramaya.edu / Student123!');

  // ==================== COMMON FEED SEED DATA ====================
  
  console.log('\n🌐 Seeding Common Feed data...');
  
  // Get all users for creating posts
  const allUsers = await prisma.user.findMany({
    include: {
      studentProfile: true,
      coordinatorProfile: true,
      supervisorProfile: true,
    },
  });

  const adminUser = allUsers.find(u => u.role === 'ADMIN');
  const coordUser = allUsers.find(u => u.role === 'COORDINATOR');
  const studentUser = allUsers.find(u => u.role === 'STUDENT');
  const supervisorUser = allUsers.find(u => u.role === 'SUPERVISOR');

  // Create sample posts
  const posts = [];

  if (adminUser) {
    const adminPost = await prisma.commonPost.create({
      data: {
        authorId: adminUser.id,
        postType: 'ANNOUNCEMENT',
        visibility: 'PUBLIC',
        title: 'Welcome to InternLink Common Feed!',
        content: '<p>We are excited to launch the Common Feed feature where all stakeholders can share updates, opportunities, and experiences. This platform is designed to foster collaboration and communication throughout your internship journey.</p><p>Feel free to share your thoughts, ask questions, and engage with the community!</p>',
        isPinned: true,
        viewCount: 0,
        likeCount: 0,
        commentCount: 0,
      },
    });
    posts.push(adminPost);
    console.log('✅ Admin announcement post created');
  }

  if (coordUser) {
    const coordPost = await prisma.commonPost.create({
      data: {
        authorId: coordUser.id,
        postType: 'ANNOUNCEMENT',
        visibility: 'UNIVERSITY',
        title: 'Important: Midterm Evaluation Deadline',
        content: '<p>Dear Students,</p><p>This is a reminder that the midterm evaluation deadline is approaching. Please ensure you submit your evaluations by <strong>April 15, 2026</strong>.</p><p>The evaluation should include:</p><ul><li>Weekly progress reports</li><li>Supervisor feedback</li><li>Self-assessment</li></ul><p>Contact the coordination office if you have any questions.</p>',
        targetUniversityId: demoUniversity.id,
        viewCount: 0,
        likeCount: 0,
        commentCount: 0,
      },
    });
    posts.push(coordPost);
    console.log('✅ Coordinator announcement post created');
  }

  if (supervisorUser) {
    const supPost = await prisma.commonPost.create({
      data: {
        authorId: supervisorUser.id,
        postType: 'OPPORTUNITY',
        visibility: 'PUBLIC',
        title: 'Software Engineering Internship - Summer 2026',
        content: '<p><strong>Demo Company</strong> is looking for talented software engineering interns for Summer 2026!</p><p><strong>Requirements:</strong></p><ul><li>Strong programming skills in JavaScript/TypeScript</li><li>Familiarity with React and Node.js</li><li>Good communication skills</li><li>Team player attitude</li></ul><p><strong>What we offer:</strong></p><ul><li>Hands-on experience with real projects</li><li>Mentorship from senior developers</li><li>Flexible working hours</li><li>Potential for full-time employment</li></ul><p>Interested? Send your CV to company@demo.com</p>',
        viewCount: 0,
        likeCount: 0,
        commentCount: 0,
      },
    });
    posts.push(supPost);
    console.log('✅ Supervisor opportunity post created');
  }

  if (studentUser) {
    const studentPost1 = await prisma.commonPost.create({
      data: {
        authorId: studentUser.id,
        postType: 'EXPERIENCE',
        visibility: 'PUBLIC',
        title: 'Week 1: First Impressions',
        content: '<p>Just completed my first week at the internship! Here are my key takeaways:</p><p><strong>What I learned:</strong></p><ul><li>Company culture and work environment</li><li>Team structure and communication channels</li><li>Project overview and my role</li></ul><p><strong>Challenges:</strong></p><ul><li>Adapting to the fast-paced environment</li><li>Learning new tools and technologies</li></ul><p>Overall, I\'m excited about the journey ahead! Looking forward to contributing more to the team.</p>',
        viewCount: 0,
        likeCount: 0,
        commentCount: 0,
      },
    });
    posts.push(studentPost1);

    const studentPost2 = await prisma.commonPost.create({
      data: {
        authorId: studentUser.id,
        postType: 'GENERAL_UPDATE',
        visibility: 'PUBLIC',
        title: 'Tips for New Interns',
        content: '<p>After a few weeks of internship, here are some tips I wish I knew from day one:</p><ol><li><strong>Ask questions</strong> - Don\'t hesitate to ask when you\'re unsure</li><li><strong>Take notes</strong> - Document everything you learn</li><li><strong>Network</strong> - Connect with colleagues and other interns</li><li><strong>Be proactive</strong> - Look for opportunities to contribute</li><li><strong>Maintain work-life balance</strong> - Take care of your health</li></ol><p>Hope this helps fellow interns! Feel free to add your own tips in the comments.</p>',
        viewCount: 0,
        likeCount: 0,
        commentCount: 0,
      },
    });
    posts.push(studentPost2);
    console.log('✅ Student experience posts created');
  }

  // Create sample comments
  if (posts.length > 0 && studentUser && coordUser) {
    const firstPost = posts[0];
    
    const comment1 = await prisma.postComment.create({
      data: {
        postId: firstPost.id,
        authorId: studentUser.id,
        content: 'This is great! Looking forward to sharing my internship journey here.',
      },
    });

    await prisma.postComment.create({
      data: {
        postId: firstPost.id,
        authorId: coordUser.id,
        content: 'Welcome! We encourage all students to actively participate and share their experiences.',
        parentId: comment1.id,
      },
    });

    await prisma.commonPost.update({
      where: { id: firstPost.id },
      data: { commentCount: 2 },
    });

    console.log('✅ Sample comments created');
  }

  // Create sample likes
  if (posts.length > 0 && allUsers.length > 0) {
    for (const post of posts.slice(0, 2)) {
      for (const user of allUsers.slice(0, 3)) {
        await prisma.postLike.create({
          data: {
            postId: post.id,
            userId: user.id,
          },
        }).catch(() => {}); // Ignore duplicates
      }
      
      await prisma.commonPost.update({
        where: { id: post.id },
        data: { likeCount: 3 },
      });
    }
    console.log('✅ Sample likes created');
  }

  console.log('\n✅ Common Feed seeding completed!');
  console.log(`   Created ${posts.length} sample posts`);
  console.log('   Created sample comments and likes');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
