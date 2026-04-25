import prisma from '../config/db';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const BASE_URL = 'http://localhost:5000/api';

async function testUnhappyPaths() {
    console.log('🚀 Starting Unhappy Paths Testing...');

    try {
        // --- SETUP ---
        const hashedPassword = await bcrypt.hash('password123', 10);
        const adminEmail = 'admin_unhappy@test.com';
        const admin = await prisma.user.upsert({
            where: { email: adminEmail },
            update: {},
            create: { email: adminEmail, password_hash: hashedPassword, full_name: 'Admin', role: 'ADMIN', verification_status: 'APPROVED', institution_access_approval: 'APPROVED' }
        });
        const adminToken = jwt.sign({ userId: admin.id, role: admin.role }, process.env.JWT_SECRET || 'secret');

        const uni = await prisma.university.upsert({
            where: { official_email: 'uni_unhappy@test.edu' },
            update: {},
            create: { name: 'Unhappy University', official_email: 'uni_unhappy@test.edu', address: 'City', approval_status: 'APPROVED' }
        });

        const company = await prisma.company.upsert({
            where: { official_email: 'corp_unhappy@test.com' },
            update: {},
            create: { name: 'Unhappy Corp', official_email: 'corp_unhappy@test.com', address: 'Remote', approval_status: 'APPROVED' }
        });

        const supUser = await prisma.user.upsert({
            where: { email: 'sup_unhappy@test.com' },
            update: {},
            create: { email: 'sup_unhappy@test.com', password_hash: hashedPassword, full_name: 'Supervisor', role: 'SUPERVISOR', verification_status: 'APPROVED', institution_access_approval: 'APPROVED' }
        });
        await prisma.supervisor.upsert({
            where: { userId: supUser.id },
            update: {},
            create: { userId: supUser.id, companyId: company.id }
        });
        const supToken = jwt.sign({ userId: supUser.id, role: supUser.role }, process.env.JWT_SECRET || 'secret');

        const hodUser = await prisma.user.upsert({
            where: { email: 'hod_unhappy@test.edu' },
            update: {},
            create: { email: 'hod_unhappy@test.edu', password_hash: hashedPassword, full_name: 'HOD', role: 'HOD', verification_status: 'APPROVED', institution_access_approval: 'APPROVED' }
        });
        const hodProfile = await prisma.hodProfile.upsert({
            where: { userId: hodUser.id },
            update: {},
            create: { userId: hodUser.id, universityId: uni.id, department: 'CS' }
        });
        const hodToken = jwt.sign({ userId: hodUser.id, role: hodUser.role }, process.env.JWT_SECRET || 'secret');

        const studentEmail = `unhappy_student@test.edu`;
        const studentUser = await prisma.user.upsert({
            where: { email: studentEmail },
            update: {},
            create: { email: studentEmail, password_hash: hashedPassword, full_name: 'Student', role: 'STUDENT', verification_status: 'APPROVED', institution_access_approval: 'APPROVED' }
        });
        const studentProfile = await prisma.student.upsert({
            where: { userId: studentUser.id },
            update: { hod_approval_status: 'APPROVED' },
            create: { userId: studentUser.id, universityId: uni.id, registration_type: 'Official', hod_approval_status: 'APPROVED' }
        });
        const studentToken = jwt.sign({ userId: studentUser.id, role: studentUser.role }, process.env.JWT_SECRET || 'secret');

        // Ensure student is PLACED for plan tests
        await prisma.student.update({ where: { id: studentProfile.id }, data: { internship_status: 'PLACED' } });
        
        const existingAssignment = await prisma.internshipAssignment.findFirst({
            where: { studentId: studentProfile.id, companyId: company.id }
        });
        
        if (!existingAssignment) {
            await prisma.internshipAssignment.create({
                data: { studentId: studentProfile.id, companyId: company.id, start_date: new Date(), status: 'ACTIVE' }
            });
        } else if (existingAssignment.status !== 'ACTIVE') {
            await prisma.internshipAssignment.update({
                where: { id: existingAssignment.id },
                data: { status: 'ACTIVE' }
            });
        }

        // --- TEST 1: Student submits plan twice for same week ---
        console.log('\n❌ Case 1: Student submits plan twice for same week');
        const plan1Res = await fetch(`${BASE_URL}/progress/submit`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${studentToken}` },
            body: JSON.stringify({ week_number: 10, plan_description: 'First attempt' })
        });
        const plan1Data: any = await plan1Res.json();
        console.log(`Plan 1: ${plan1Res.status} - ${plan1Data.message}`);

        const plan2Res = await fetch(`${BASE_URL}/progress/submit`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${studentToken}` },
            body: JSON.stringify({ week_number: 10, plan_description: 'Second attempt' })
        });
        const plan2Data: any = await plan2Res.json();
        console.log(`Plan 2: ${plan2Res.status} - ${plan2Data.message}`);
        if (plan2Res.status === 201) throw new Error('FAIL: Duplicate plan allowed!');
        console.log('✅ PASS: Duplicate plan blocked.');

        const planId = plan1Data.data?.plan?.id || plan1Data.plan?.id;

        // --- TEST 2: Supervisor rejects without feedback ---
        console.log('\n❌ Case 2: Supervisor rejects without feedback');
        const rejectRes = await fetch(`${BASE_URL}/progress/review/${planId}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${supToken}` },
            body: JSON.stringify({ status: 'REJECTED', remarks: '' })
        });
        const rejectData: any = await rejectRes.json();
        console.log(`Reject: ${rejectRes.status} - ${rejectData.message}`);
        if (rejectRes.status === 200) throw new Error('FAIL: Rejection allowed without feedback!');
        console.log('✅ PASS: Rejection without feedback blocked.');

        // --- TEST 3: Duplicate check-in in same day ---
        console.log('\n❌ Case 3: Duplicate check-in in same day');
        // First approve the plan so check-in is allowed
        await prisma.weeklyPlan.update({ where: { id: planId }, data: { status: 'APPROVED' } });
        
        const todayStr = new Date().toISOString().split('T')[0];
        const checkin1Res = await fetch(`${BASE_URL}/progress/plan/${planId}/days`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${studentToken}` },
            body: JSON.stringify({ workDate: todayStr })
        });
        console.log(`Check-in 1: ${checkin1Res.status}`);

        const checkin2Res = await fetch(`${BASE_URL}/progress/plan/${planId}/days`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${studentToken}` },
            body: JSON.stringify({ workDate: todayStr })
        });
        const checkin2Data: any = await checkin2Res.json();
        console.log(`Check-in 2: ${checkin2Res.status} - ${checkin2Data.message}`);
        if (checkin2Res.status === 201) throw new Error('FAIL: Duplicate check-in allowed!');
        console.log('✅ PASS: Duplicate check-in blocked.');

        // --- TEST 4: HoD sends proposal for unapproved student ---
        console.log('\n❌ Case 4: HoD sends proposal for unapproved student');
        const unapprovedStudentEmail = `unapproved@test.edu`;
        const unapprovedUser = await prisma.user.upsert({
            where: { email: unapprovedStudentEmail },
            update: {},
            create: { email: unapprovedStudentEmail, password_hash: hashedPassword, full_name: 'Unapproved', role: 'STUDENT', verification_status: 'APPROVED', institution_access_approval: 'APPROVED' }
        });
        const unapprovedProfile = await prisma.student.upsert({
            where: { userId: unapprovedUser.id },
            update: { hod_approval_status: 'PENDING' },
            create: { userId: unapprovedUser.id, universityId: uni.id, registration_type: 'Official', hod_approval_status: 'PENDING' }
        });

        const propRes = await fetch(`${BASE_URL}/placements/proposals`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${hodToken}` },
            body: JSON.stringify({ studentId: unapprovedProfile.id, companyId: company.id })
        });
        const propData: any = await propRes.json();
        console.log(`Proposal: ${propRes.status} - ${propData.message}`);
        if (propRes.status === 201) throw new Error('FAIL: Proposal allowed for unapproved student!');
        console.log('✅ PASS: Unapproved student blocked from placement.');

        // --- TEST 5: Access another user's data (Security) ---
        console.log('\n❌ Case 5: Access another student\'s plan (Security)');
        const victimEmail = 'victim@test.edu';
        const victimUser = await prisma.user.upsert({
            where: { email: victimEmail },
            update: {},
            create: { email: victimEmail, password_hash: hashedPassword, full_name: 'Victim', role: 'STUDENT', verification_status: 'APPROVED', institution_access_approval: 'APPROVED' }
        });
        const victimProfile = await prisma.student.upsert({
            where: { userId: victimUser.id },
            update: {},
            create: { userId: victimUser.id, universityId: uni.id, registration_type: 'Official' }
        });
        const victimPlan = await prisma.weeklyPlan.create({
            data: { studentId: victimProfile.id, week_number: 1, plan_description: 'Victim Secret Plan', status: 'PENDING' }
        });

        const hackRes = await fetch(`${BASE_URL}/progress/plan/${victimPlan.id}/days`, {
            method: 'GET',
            headers: { 'Authorization': `Bearer ${studentToken}` }
        });
        const hackData: any = await hackRes.json();
        console.log(`Hack Attempt: ${hackRes.status} - ${hackData.message}`);
        if (hackRes.status === 200) throw new Error('FAIL: Accessed another student\'s plan!');
        console.log('✅ PASS: Unauthorized access blocked.');

        console.log('\n✨ ALL UNHAPPY PATH TESTS PASSED! ✨');

    } catch (error: any) {
        console.error('\n❌ UNHAPPY PATH TEST FAILED:', error.message);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

testUnhappyPaths();
