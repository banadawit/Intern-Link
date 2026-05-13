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
        full_name: 'Admin',
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
    // Ensure company and supervisor profile exist and are linked
    let demoCompanyForSup = await prisma.company.findFirst({ where: { official_email: 'company@demo.com' } });
    if (!demoCompanyForSup) {
      demoCompanyForSup = await prisma.company.create({
        data: { name: 'Demo Company', official_email: 'company@demo.com', approval_status: 'APPROVED' },
      });
      console.log('✅ Demo Company created');
    } else if (demoCompanyForSup.approval_status !== 'APPROVED') {
      await prisma.company.update({ where: { id: demoCompanyForSup.id }, data: { approval_status: 'APPROVED' } });
    }
    const supProfile = await prisma.supervisor.findUnique({ where: { userId: existingSup.id } });
    if (!supProfile) {
      await prisma.supervisor.create({ data: { userId: existingSup.id, companyId: demoCompanyForSup.id } });
      console.log('✅ Supervisor profile repaired (company linked)');
    } else if (!supProfile.companyId) {
      await prisma.supervisor.update({ where: { userId: existingSup.id }, data: { companyId: demoCompanyForSup.id } });
      console.log('✅ Supervisor profile repaired (company linked)');
    } else {
      console.log(`Supervisor already exists: ${supEmail}`);
    }
    await prisma.user.update({
      where: { email: supEmail },
      data: { verification_status: 'APPROVED', institution_access_approval: 'APPROVED' },
    });
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
    // Ensure coordinator profile is linked to the university
    const coordProfile = await prisma.coordinator.findUnique({ where: { userId: coordExists.id } });
    if (!coordProfile) {
      await prisma.coordinator.create({ data: { userId: coordExists.id, universityId: demoUniversity.id } });
      console.log('✅ Coordinator profile repaired (university linked)');
    } else if (!coordProfile.universityId) {
      await prisma.coordinator.update({ where: { userId: coordExists.id }, data: { universityId: demoUniversity.id } });
      console.log('✅ Coordinator profile repaired (university linked)');
    } else {
      console.log(`Coordinator already exists: ${coordEmail}`);
    }
    await prisma.user.update({
      where: { email: coordEmail },
      data: { verification_status: 'APPROVED', institution_access_approval: 'APPROVED' },
    });
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

  // ── 10 extra demo students under the demo HOD ──────────────────────────────
  const hodProfile = await prisma.hodProfile.findUnique({ where: { userId: (await prisma.user.findUnique({ where: { email: hodEmail } }))!.id } });
  const demoCompany = await prisma.company.findFirst({ where: { official_email: 'company@demo.com' } });

  const demoStudents = [
    { n: 1,  name: 'Abebe Kebede',    email: 'student1@haramaya.edu',  placed: true  },
    { n: 2,  name: 'Tigist Alemu',    email: 'student2@haramaya.edu',  placed: true  },
    { n: 3,  name: 'Yonas Tadesse',   email: 'student3@haramaya.edu',  placed: true  },
    { n: 4,  name: 'Meron Haile',     email: 'student4@haramaya.edu',  placed: true  },
    { n: 5,  name: 'Dawit Girma',     email: 'student5@haramaya.edu',  placed: true  },
    { n: 6,  name: 'Selam Bekele',    email: 'student6@haramaya.edu',  placed: false },
    { n: 7,  name: 'Biruk Tesfaye',   email: 'student7@haramaya.edu',  placed: false },
    { n: 8,  name: 'Hana Worku',      email: 'student8@haramaya.edu',  placed: false },
    { n: 9,  name: 'Natnael Assefa',  email: 'student9@haramaya.edu',  placed: false },
    { n: 10, name: 'Lidya Solomon',   email: 'student10@haramaya.edu', placed: false },
  ];

  for (const s of demoStudents) {
    const existing = await prisma.user.findUnique({ where: { email: s.email } });
    if (existing) {
      console.log(`Student already exists: ${s.email}`);
      continue;
    }

    const newUser = await prisma.user.create({
      data: {
        full_name: s.name,
        email: s.email,
        password_hash: await bcrypt.hash('Student123!', 10),
        role: 'STUDENT',
        verification_status: 'APPROVED',
        institution_access_approval: 'APPROVED',
        studentProfile: {
          create: {
            universityId: demoUniversity.id,
            hodId: hodProfile?.id ?? null,
            registration_type: 'Official',
            department: 'Computer Science',
            studentId: `CS/2021/0${s.n.toString().padStart(2, '0')}`,
            hod_approval_status: 'APPROVED',
            internship_status: s.placed ? 'PLACED' : 'PENDING',
          },
        },
      },
      include: { studentProfile: true },
    });

    // For placed students, create an approved proposal + active assignment
    if (s.placed && demoCompany && hodProfile && newUser.studentProfile) {
      const proposal = await prisma.internshipProposal.create({
        data: {
          studentId: newUser.studentProfile.id,
          companyId: demoCompany.id,
          universityId: demoUniversity.id,
          status: 'APPROVED',
          proposal_type: 'University_Initiated',
          expected_duration_weeks: 12,
          responded_at: new Date(),
        },
      });

      await prisma.internshipAssignment.create({
        data: {
          studentId: newUser.studentProfile.id,
          companyId: demoCompany.id,
          status: 'ACTIVE',
          start_date: new Date(),
        },
      });

      // Seed one weekly plan so the student has something to work with
      await prisma.weeklyPlan.create({
        data: {
          studentId: newUser.studentProfile.id,
          week_number: 1,
          plan_description: 'Orientation week — getting familiar with the company environment, tools, and team members.',
          status: 'PENDING',
        },
      });

      console.log(`✅ Student ${s.name} created, placed at Demo Company, week 1 plan seeded`);
    } else {
      console.log(`✅ Student ${s.name} created (pending placement)`);
    }
  }

  console.log('\n📌 Demo student logins (all use password: Student123!):');
  for (const s of demoStudents) {
    console.log(`   ${s.name.padEnd(20)} ${s.email}  ${s.placed ? '(placed)' : '(pending)'}`);
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
