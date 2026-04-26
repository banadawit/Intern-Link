import prisma from '../config/db';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const BASE_URL = 'http://localhost:5000/api';

async function testE2E() {
    console.log('🚀 Starting End-to-End Flow Testing...');

    try {
        // --- STEP 0: SETUP ADMIN & INFRA ---
        console.log('\n--- Step 0: Setup Admin & Infrastructure ---');
        
        // Ensure Admin exists
        const adminEmail = 'admin@test.com';
        const hashedPassword = await bcrypt.hash('admin123', 10);
        let admin = await prisma.user.upsert({
            where: { email: adminEmail },
            update: { verification_status: 'APPROVED', institution_access_approval: 'APPROVED' },
            create: {
                email: adminEmail,
                password_hash: hashedPassword,
                full_name: 'Global Admin',
                role: 'ADMIN',
                verification_status: 'APPROVED',
                institution_access_approval: 'APPROVED'
            }
        });
        const adminToken = jwt.sign({ userId: admin.id, role: admin.role }, process.env.JWT_SECRET || 'secret', { expiresIn: '1h' });

        // Create University
        const uni = await prisma.university.upsert({
            where: { official_email: 'uni@test.edu' },
            update: { approval_status: 'APPROVED' },
            create: { name: 'Test University', official_email: 'uni@test.edu', address: 'City', approval_status: 'APPROVED' }
        });

        // Create Company
        const company = await prisma.company.upsert({
            where: { official_email: 'company@test.com' },
            update: { approval_status: 'APPROVED' },
            create: { name: 'Test Tech Corp', official_email: 'company@test.com', address: 'Remote', approval_status: 'APPROVED' }
        });

        // Setup Coordinator (Required for HOD registration logic)
        const coordEmail = 'coord@test.edu';
        let coordUser = await prisma.user.upsert({
            where: { email: coordEmail },
            update: { verification_status: 'APPROVED', institution_access_approval: 'APPROVED' },
            create: {
                email: coordEmail,
                password_hash: hashedPassword,
                full_name: 'Uni Coordinator',
                role: 'COORDINATOR',
                verification_status: 'APPROVED',
                institution_access_approval: 'APPROVED'
            }
        });
        await prisma.coordinator.upsert({
            where: { userId: coordUser.id },
            update: { universityId: uni.id },
            create: { userId: coordUser.id, universityId: uni.id }
        });

        // Setup HoD
        const hodEmail = 'hod@test.edu';
        let hodUser = await prisma.user.upsert({
            where: { email: hodEmail },
            update: { verification_status: 'APPROVED', institution_access_approval: 'APPROVED' },
            create: {
                email: hodEmail,
                password_hash: hashedPassword,
                full_name: 'Dr. John HoD',
                role: 'HOD',
                verification_status: 'APPROVED',
                institution_access_approval: 'APPROVED'
            }
        });
        const hodProfile = await prisma.hodProfile.upsert({
            where: { userId: hodUser.id },
            update: { universityId: uni.id, department: 'CS' },
            create: { userId: hodUser.id, universityId: uni.id, department: 'CS' }
        });
        const hodToken = jwt.sign({ userId: hodUser.id, role: hodUser.role }, process.env.JWT_SECRET || 'secret', { expiresIn: '1h' });

        // Setup Supervisor
        const supEmail = 'supervisor@test.com';
        let supUser = await prisma.user.upsert({
            where: { email: supEmail },
            update: { verification_status: 'APPROVED', institution_access_approval: 'APPROVED' },
            create: {
                email: supEmail,
                password_hash: hashedPassword,
                full_name: 'Jane Supervisor',
                role: 'SUPERVISOR',
                verification_status: 'APPROVED',
                institution_access_approval: 'APPROVED'
            }
        });
        const supervisorProfile = await prisma.supervisor.upsert({
            where: { userId: supUser.id },
            update: { companyId: company.id },
            create: { userId: supUser.id, companyId: company.id }
        });
        const supToken = jwt.sign({ userId: supUser.id, role: supUser.role }, process.env.JWT_SECRET || 'secret', { expiresIn: '1h' });

        // --- STEP 1: STUDENT REGISTERS ---
        console.log('\n--- Step 1: Student Registers ---');
        const studentEmail = `student_${Date.now()}@test.edu`;
        const regRes = await fetch(`${BASE_URL}/auth/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: studentEmail,
                password: 'student123',
                full_name: 'Alice Student',
                role: 'STUDENT',
                university_id: uni.id,
                hod_id: hodProfile.id,
                department: 'CS',
                student_id: `SID${Date.now()}`
            })
        });
        const regData: any = await regRes.json();
        if (!regRes.ok) throw new Error(`Registration failed: ${JSON.stringify(regData)}`);
        console.log('✅ Student registered successfully.');
        
        // Manually approve student email verification in DB
        await prisma.user.update({
            where: { email: studentEmail },
            data: { verification_status: 'APPROVED' }
        });

        const studentProfile = await prisma.student.findFirst({ where: { user: { email: studentEmail } } });
        if (!studentProfile) throw new Error('Student profile not found in DB after registration.');

        // --- STEP 2: HOD APPROVES STUDENT ---
        console.log('\n--- Step 2: HoD Approves Student ---');
        const approveRes = await fetch(`${BASE_URL}/hod/verify-student`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${hodToken}` },
            body: JSON.stringify({
                studentId: studentProfile.id,
                status: 'APPROVED'
            })
        });
        const approveData: any = await approveRes.json();
        if (!approveRes.ok) throw new Error(`HoD Approval failed: ${JSON.stringify(approveData)}`);
        console.log('✅ HoD approved student.');

        // --- Step 1.1: Student Login ---
        console.log(`\n--- Step 1.1: Student Login (${studentEmail}) ---`);
        const loginRes = await fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: studentEmail, password: 'student123' })
        });
        const loginData: any = await loginRes.json();
        if (!loginRes.ok) throw new Error(`Student login failed: ${JSON.stringify(loginData)}`);
        const studentToken = loginData.data.token;
        console.log('✅ Student logged in successfully.');

        // --- STEP 3: HOD SENDS PROPOSAL ---
        console.log('\n--- Step 3: HoD Sends Proposal ---');
        const propRes = await fetch(`${BASE_URL}/placements/proposals`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${hodToken}` },
            body: JSON.stringify({
                studentId: studentProfile.id,
                companyId: company.id,
                expected_duration_weeks: 12,
                expected_outcomes: 'Learn E2E Testing'
            })
        });
        const propData: any = await propRes.json();
        if (!propRes.ok) throw new Error(`Proposal submission failed: ${JSON.stringify(propData)}`);
        const proposalId = propData.data.id;
        console.log(`✅ HoD sent proposal (ID: ${proposalId}).`);

        // --- STEP 4: SUPERVISOR RESPONDS (APPROVE) ---
        console.log('\n--- Step 4: Supervisor Approves Proposal ---');
        const respondRes = await fetch(`${BASE_URL}/placements/respond/${proposalId}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${supToken}` },
            body: JSON.stringify({
                status: 'APPROVED'
            })
        });
        const respondData: any = await respondRes.json();
        if (!respondRes.ok) throw new Error(`Supervisor response failed: ${JSON.stringify(respondData)}`);
        console.log('✅ Supervisor approved proposal.');

        // --- STEP 5: VERIFY ASSIGNMENT ---
        console.log('\n--- Step 5: Verify Student Assignment ---');
        const assignment = await prisma.internshipAssignment.findFirst({
            where: { studentId: studentProfile.id, status: 'ACTIVE' }
        });
        if (!assignment) throw new Error('Internship assignment was not created automatically.');
        console.log(`✅ Student is now PLACED and assigned (ID: ${assignment.id}).`);

        // --- STEP 6: STUDENT SUBMITS WEEKLY PLAN ---
        console.log('\n--- Step 6: Student Submits Weekly Plan ---');
        const planRes = await fetch(`${BASE_URL}/progress/submit`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${studentToken}` },
            body: JSON.stringify({
                week_number: 1,
                plan_description: 'Building E2E tests for the backend.'
            })
        });
        const planData: any = await planRes.json();
        if (!planRes.ok) throw new Error(`Plan submission failed: ${JSON.stringify(planData)}`);
        const planId = planData.plan.id;
        console.log(`✅ Student submitted weekly plan (ID: ${planId}).`);

        // --- STEP 7: SUPERVISOR APPROVES PLAN ---
        console.log('\n--- Step 7: Supervisor Reviews Plan ---');
        const reviewRes = await fetch(`${BASE_URL}/progress/review/${planId}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${supToken}` },
            body: JSON.stringify({
                status: 'APPROVED',
                remarks: 'Good plan, keep it up.',
                attendance: true
            })
        });
        const reviewData: any = await reviewRes.json();
        if (!reviewRes.ok) throw new Error(`Plan review failed: ${JSON.stringify(reviewData)}`);
        console.log('✅ Supervisor approved weekly plan.');

        // --- STEP 8: STUDENT SUBMITS CHECK-IN ---
        console.log('\n--- Step 8: Student Submits Daily Check-in ---');
        const todayStr = new Date().toISOString().split('T')[0];
        const checkinRes = await fetch(`${BASE_URL}/progress/plan/${planId}/days`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${studentToken}` },
            body: JSON.stringify({
                workDate: todayStr
            })
        });
        const checkinData: any = await checkinRes.json();
        if (!checkinRes.ok) throw new Error(`Check-in failed: ${JSON.stringify(checkinData)}`);
        console.log('✅ Student submitted daily check-in.');

        // --- STEP 9: SUPERVISOR GIVES FINAL EVALUATION ---
        console.log('\n--- Step 9: Supervisor Final Evaluation ---');
        const evalRes = await fetch(`${BASE_URL}/supervisor/evaluation`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${supToken}` },
            body: JSON.stringify({
                studentId: studentProfile.id,
                technical_score: 95,
                soft_skill_score: 90,
                comments: 'Excellent performance throughout the internship.'
            })
        });
        const evalData: any = await evalRes.json();
        if (!evalRes.ok) throw new Error(`Final evaluation failed: ${JSON.stringify(evalData)}`);
        console.log('✅ Supervisor submitted final evaluation.');

        console.log('\n✨ ALL E2E STEPS COMPLETED SUCCESSFULLY! ✨');

    } catch (error: any) {
        console.error('\n❌ E2E FLOW BROKEN:', error.message);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

testE2E();
