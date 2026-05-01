const { PrismaClient } = require("@prisma/client");
const p = new PrismaClient();
async function main() {
  // Get full student details with placement status
  const students = await p.student.findMany({
    include: {
      user: { select: { id: true, email: true, full_name: true } },
      assignments: { where: { status: "ACTIVE" }, take: 1, include: { company: { select: { name: true } } } },
      weeklyPlans: { orderBy: { week_number: "desc" }, take: 3, include: { daySubmissions: true } },
      proposals: { orderBy: { submitted_at: "desc" }, take: 2, include: { company: { select: { name: true } } } },
      finalEvaluation: true,
      finalReport: true,
    },
    take: 5
  });
  for (const s of students) {
    console.log(`\n--- Student: ${s.user.full_name} (${s.user.email}) ---`);
    console.log(`  internship_status: ${s.internship_status}, hod_approval: ${s.hod_approval_status}`);
    console.log(`  active_assignment: ${s.assignments[0]?.company?.name ?? "none"}`);
    console.log(`  weekly_plans: ${s.weeklyPlans.map(p => `W${p.week_number}:${p.status}`).join(", ") || "none"}`);
    console.log(`  proposals: ${s.proposals.map(p => `${p.company.name}:${p.status}`).join(", ") || "none"}`);
    console.log(`  evaluation: ${s.finalEvaluation ? `tech=${s.finalEvaluation.technical_score} soft=${s.finalEvaluation.soft_skill_score}` : "none"}`);
    console.log(`  report: ${s.finalReport ? s.finalReport.pdf_url.substring(0, 40) : "none"}`);
  }
  await p.$disconnect();
}
main().catch(e => { console.error(e.message); process.exit(1); });
