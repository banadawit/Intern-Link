import OpenAI from 'openai';
import { Role } from '@prisma/client';

function normalizeApiKeyEnv(raw: string | undefined): string | undefined {
    if (raw == null || typeof raw !== 'string') return undefined;
    let v = raw.trim().replace(/^\uFEFF/, '');
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
        v = v.slice(1, -1).trim();
    }
    return v.length > 0 ? v : undefined;
}

export function getGroqApiKey(): string | undefined {
    return normalizeApiKeyEnv(process.env.GROQ_API_KEY);
}

const AI_MODEL = process.env.GROQ_MODEL || 'llama-3.3-70b-versatile';
const CHAT_MODEL = process.env.GROQ_CHAT_MODEL || 'llama-3.3-70b-versatile';

function isAiMockEnabled(): boolean {
    const v = process.env.AI_USE_MOCK?.trim().toLowerCase();
    return v === '1' || v === 'true' || v === 'yes';
}

export type WeeklyPlanInput = {
    field: string;
    week: number;
    skills: string;
    internshipType: string;
};

export type WeeklyPlanResult = {
    tasks: string;
    goals: string;
    deliverables: string;
};

export type FeedbackInput = {
    plan: string;
    studentName?: string;
    week?: number;
};

export type FeedbackResult = {
    strengths: string;
    weaknesses: string;
    suggestions: string;
};

export type StudentContext = {
    companyName?: string;
    supervisorName?: string;
    projectName?: string;
    projectDescription?: string;
    weeklyPlans?: {
        weekNumber: number;
        description: string;
        status: string;
        feedback?: string;
        dailySubmissions?: { date: string; notes?: string }[];
    }[];
};

export type SupervisorContext = {
    companyName?: string;
    placedStudents?: {
        name: string;
        email: string;
        projectName?: string;
        pendingPlans: number;
        approvedPlans: number;
        rejectedPlans: number;
        lastPlanDescription?: string;
    }[];
    pendingProposalsCount?: number;
    pendingPlansCount?: number;
};

export type HodContext = {
    universityName?: string;
    department?: string;
    totalStudents?: number;
    pendingApprovals?: number;
    approvedStudents?: number;
    placedStudents?: number;
    recentPendingStudents?: { name: string; email: string }[];
};

export type ChatInput = {
    message: string;
    history?: { role: 'user' | 'assistant'; content: string }[];
    appRole: Role | 'VISITOR';
    userId: number;
    userDisplayName: string;
    studentContext?: StudentContext;
    supervisorContext?: SupervisorContext;
    hodContext?: HodContext;
};

export type ChatResult = {
    reply: string;
};

function getClient(): OpenAI {
    const key = getGroqApiKey();
    if (!key) {
        const err = new Error('AI_UNAVAILABLE') as Error & { code: string };
        err.code = 'AI_UNAVAILABLE';
        throw err;
    }
    return new OpenAI({
        apiKey: key,
        baseURL: 'https://api.groq.com/openai/v1',
    });
}

export function isAiConfigured(): boolean {
    return Boolean(getGroqApiKey()) || isAiMockEnabled();
}

export function isChatAiConfigured(): boolean {
    return Boolean(getGroqApiKey());
}

const CHAT_SYSTEM_MESSAGE = `You are a smart AI assistant for the Intern-Link platform, which manages internships for students, supervisors, coordinators, and admins.

**Your roles:**
1. 🎓 **Student role**: weekly plan generation, task suggestions, improving writing, generating presentation content, explaining supervisor feedback, tracking daily progress.
2. 👔 **Supervisor role**: reviewing student plans, generating feedback, summarizing performance, writing evaluations.
3. 🏫 **Coordinator role**: analyzing student performance, detecting low-performing students, generating reports, recommending placements.
4. 🏛️ **Admin role**: monitoring system usage, detecting unusual activity, generating analytics.

**Formatting guidelines (always follow these):**
- Use **bold** for section titles, key terms, and important information
- Use bullet points (•) for lists of tasks, tips, or items
- Use numbered lists for step-by-step instructions or ordered plans
- Add relevant emojis to section headings and key points to make responses visually engaging
- Leave blank lines between sections for readability
- Keep responses concise but complete
- Use friendly, encouraging language

**General guidelines:**
- Respond naturally in conversational chat form
- Tailor answers to the user role
- Give actionable advice and suggestions
- Ask clarifying questions if needed
- Never auto-submit plans; always let users review and edit
- You do not have live access to Intern-Link data unless it is provided in the context below`;

function sanitizeChatDisplayName(name: string): string {
    return name.replace(/[\r\n\u0000]/g, ' ').trim().slice(0, 120) || 'there';
}

const ROLE_CHAT_FOCUS: Record<Role, { article: string; focus: string }> = {
    [Role.STUDENT]: {
        article: 'a student',
        focus: 'student intern work only: weekly plans, tasks, skills, reports, presentations, and understanding supervisor feedback.',
    },
    [Role.SUPERVISOR]: {
        article: 'a supervisor',
        focus: 'supervisor work only: reviewing student plans, feedback, approvals, evaluations, and supporting your interns.',
    },
    [Role.COORDINATOR]: {
        article: 'a coordinator',
        focus: 'coordinator work only: placements, cohorts, student support, and university-side reporting.',
    },
    [Role.HOD]: {
        article: 'a Head of Department',
        focus: 'HOD work only: department-level student approvals, placements, company outreach, and internship progress.',
    },
    [Role.ADMIN]: {
        article: 'an administrator',
        focus: 'admin work only: platform oversight, verification, analytics, and operational guidance.',
    },
};

function buildChatSessionInstruction(displayName: string, appRole: Role | 'VISITOR'): string {
    const name = sanitizeChatDisplayName(displayName);
    const first = name.split(/\s+/)[0] || name;

    if (appRole === 'VISITOR') {
        return `Session context: The user is a visitor on the Intern-Link landing page. Greet them naturally and help only with general information about Intern-Link.`;
    }

    const r = ROLE_CHAT_FOCUS[appRole];
    return `Session context (user is already logged in):
The user's name is "${name}". They are signed in as ${r.article}.
Greet them naturally using their name (e.g. "Hey ${first}!").
Help only with ${r.focus}
Do not ask them to choose a role. Stay in this role unless they explicitly ask about another.`;
}

function buildStudentContextBlock(ctx: StudentContext): string {
    const lines: string[] = ['--- Student Internship Context (live data) ---'];

    if (ctx.companyName) lines.push(`🏢 Company: ${ctx.companyName}`);
    if (ctx.supervisorName) lines.push(`👔 Supervisor: ${ctx.supervisorName}`);
    if (ctx.projectName) lines.push(`📁 Assigned project: ${ctx.projectName}`);
    if (ctx.projectDescription) lines.push(`📝 Project description: ${ctx.projectDescription}`);

    if (ctx.weeklyPlans && ctx.weeklyPlans.length > 0) {
        lines.push('\n📅 Recent weekly plans (most recent first):');
        for (const p of ctx.weeklyPlans) {
            const statusEmoji = p.status === 'APPROVED' ? '✅' : p.status === 'REJECTED' ? '❌' : '⏳';
            lines.push(`  ${statusEmoji} Week ${p.weekNumber} [${p.status}]: ${p.description.slice(0, 300)}${p.description.length > 300 ? '…' : ''}`);
            if (p.feedback) lines.push(`    💬 Supervisor feedback: ${p.feedback}`);
            if (p.dailySubmissions && p.dailySubmissions.length > 0) {
                lines.push(`    📆 Daily check-ins:`);
                for (const d of p.dailySubmissions) {
                    lines.push(`      • ${d.date}${d.notes ? ': ' + d.notes.slice(0, 150) : ' (checked in)'}`);
                }
            }
        }
    } else {
        lines.push('📭 No weekly plans submitted yet.');
    }

    lines.push('--- End of context ---');
    return lines.join('\n');
}

function buildSupervisorContextBlock(ctx: SupervisorContext): string {
    const lines: string[] = ['--- Supervisor Context (live data) ---'];
    if (ctx.companyName) lines.push(`🏢 Company: ${ctx.companyName}`);
    if (ctx.pendingProposalsCount !== undefined) lines.push(`📥 Pending proposals: ${ctx.pendingProposalsCount}`);
    if (ctx.pendingPlansCount !== undefined) lines.push(`📋 Pending weekly plans to review: ${ctx.pendingPlansCount}`);

    if (ctx.placedStudents && ctx.placedStudents.length > 0) {
        lines.push(`\n👥 Placed interns (${ctx.placedStudents.length}):`);
        for (const s of ctx.placedStudents) {
            lines.push(`  👤 ${s.name} (${s.email})`);
            if (s.projectName) lines.push(`     📁 Project: ${s.projectName}`);
            lines.push(`     Plans: ✅ ${s.approvedPlans} approved · ⏳ ${s.pendingPlans} pending · ❌ ${s.rejectedPlans} rejected`);
            if (s.lastPlanDescription) lines.push(`     Latest plan: ${s.lastPlanDescription.slice(0, 150)}${s.lastPlanDescription.length > 150 ? '…' : ''}`);
        }
    } else {
        lines.push('📭 No placed interns yet.');
    }
    lines.push('--- End of context ---');
    return lines.join('\n');
}

function buildHodContextBlock(ctx: HodContext): string {
    const lines: string[] = ['--- Head of Department Context (live data) ---'];
    if (ctx.universityName) lines.push(`🏛️ University: ${ctx.universityName}`);
    if (ctx.department) lines.push(`📚 Department: ${ctx.department}`);
    if (ctx.totalStudents !== undefined) lines.push(`👥 Total students in department: ${ctx.totalStudents}`);
    if (ctx.pendingApprovals !== undefined) lines.push(`⏳ Pending student approvals: ${ctx.pendingApprovals}`);
    if (ctx.approvedStudents !== undefined) lines.push(`✅ Approved students: ${ctx.approvedStudents}`);
    if (ctx.placedStudents !== undefined) lines.push(`🏢 Students placed at companies: ${ctx.placedStudents}`);
    if (ctx.recentPendingStudents && ctx.recentPendingStudents.length > 0) {
        lines.push(`\n🔔 Students awaiting approval:`);
        for (const s of ctx.recentPendingStudents) {
            lines.push(`  • ${s.name} (${s.email})`);
        }
    }
    lines.push('--- End of context ---');
    return lines.join('\n');
}

function buildFullChatSystemMessage(input: ChatInput): string {
    let base = `${CHAT_SYSTEM_MESSAGE}\n\n${buildChatSessionInstruction(input.userDisplayName, input.appRole)}`;

    if (input.appRole === 'STUDENT' && input.studentContext) {
        base += `\n\n${buildStudentContextBlock(input.studentContext)}`;
        base += `\n\n**When responding to this student, always:**
- Reference their actual project ("${input.studentContext.projectName ?? 'your project'}") by name
- Reference their supervisor ("${input.studentContext.supervisorName ?? 'your supervisor'}") by name when relevant
- Use their weekly plan history to give personalised suggestions
- Format responses with **bold headings**, bullet points, and emojis
- Be proactive: suggest next steps, ask about blockers, celebrate progress`;
    }

    if (input.appRole === 'SUPERVISOR' && input.supervisorContext) {
        base += `\n\n${buildSupervisorContextBlock(input.supervisorContext)}`;
        base += `\n\n**When responding to this supervisor, always:**
- Reference their company ("${input.supervisorContext.companyName ?? 'your company'}") and interns by name
- Help review weekly plans, generate feedback, and track intern progress
- Suggest actions for pending proposals or plans
- Format responses with **bold headings**, bullet points, and emojis`;
    }

    if (input.appRole === 'HOD' && input.hodContext) {
        base += `\n\n${buildHodContextBlock(input.hodContext)}`;
        base += `\n\n**When responding to this Head of Department, always:**
- Reference their university ("${input.hodContext.universityName ?? 'your university'}") and department ("${input.hodContext.department ?? 'your department'}")
- Help manage student approvals, placements, and department oversight
- Provide insights on student progress and placement rates
- Format responses with **bold headings**, bullet points, and emojis`;
    }

    return base;
}

function mockWeeklyPlan(input: WeeklyPlanInput): WeeklyPlanResult {
    return {
        tasks: `- Focused work on ${input.field} (week ${input.week})\n- Check in with your supervisor\n- Practice: ${input.skills}`,
        goals: `Ship one small outcome and reflect on what you learned.`,
        deliverables: `Brief summary of progress and blockers (mock mode — no Groq key).`,
    };
}

function mockFeedback(input: FeedbackInput): FeedbackResult {
    const snippet = input.plan.trim().slice(0, 300);
    return {
        strengths: `The plan shows direction. Snippet: "${snippet}${input.plan.length > 300 ? '…' : ''}"`,
        weaknesses: 'Add more measurable outcomes for the week.',
        suggestions: 'List one risk and one question for your supervisor.',
    };
}

export async function generateWeeklyPlan(input: WeeklyPlanInput): Promise<WeeklyPlanResult> {
    if (!getGroqApiKey() && isAiMockEnabled()) return mockWeeklyPlan(input);

    const groq = getClient();
    const completion = await groq.chat.completions.create({
        model: AI_MODEL,
        response_format: { type: 'json_object' },
        messages: [
            {
                role: 'system',
                content: 'You are an internship coach for InternLink. Respond only with valid JSON matching the user schema. Be practical and concise.',
            },
            {
                role: 'user',
                content: `Generate a structured weekly internship plan.

Field: ${input.field}
Week number: ${input.week}
Skills: ${input.skills}
Internship type: ${input.internshipType}

Return a JSON object with exactly these string fields:
- "tasks": bullet-style tasks for the week
- "goals": learning and delivery goals
- "deliverables": concrete outputs expected by end of week`,
            },
        ],
    });

    const raw = completion.choices[0]?.message?.content;
    if (!raw) throw new Error('Empty AI response');
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    return {
        tasks: String(parsed.tasks ?? ''),
        goals: String(parsed.goals ?? ''),
        deliverables: String(parsed.deliverables ?? ''),
    };
}

export async function generateFeedback(input: FeedbackInput): Promise<FeedbackResult> {
    if (!getGroqApiKey() && isAiMockEnabled()) return mockFeedback(input);

    const groq = getClient();
    const ctx = [
        input.studentName ? `Student: ${input.studentName}` : null,
        input.week != null ? `Week: ${input.week}` : null,
        `Plan text:\n${input.plan}`,
    ].filter(Boolean).join('\n');

    const completion = await groq.chat.completions.create({
        model: AI_MODEL,
        response_format: { type: 'json_object' },
        messages: [
            {
                role: 'system',
                content: 'You are a professional workplace supervisor reviewing an intern weekly plan. Be constructive and specific. JSON only.',
            },
            {
                role: 'user',
                content: `Review the following student weekly internship plan and respond with JSON only.\n\n${ctx}\n\nReturn a JSON object with exactly these string fields:\n- "strengths"\n- "weaknesses"\n- "suggestions" (actionable for the student)`,
            },
        ],
    });

    const raw = completion.choices[0]?.message?.content;
    if (!raw) throw new Error('Empty AI response');
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    return {
        strengths: String(parsed.strengths ?? ''),
        weaknesses: String(parsed.weaknesses ?? ''),
        suggestions: String(parsed.suggestions ?? ''),
    };
}

const MAX_HISTORY = 20;
const MAX_MESSAGE_CHARS = 8000;

export async function chatAssistant(input: ChatInput): Promise<ChatResult> {
    const msg = input.message.trim().slice(0, MAX_MESSAGE_CHARS);
    if (!msg) throw new Error('Message is required');

    const groq = getClient();

    const history = (input.history ?? [])
        .slice(-MAX_HISTORY)
        .map((h) => ({
            role: h.role === 'assistant' ? ('assistant' as const) : ('user' as const),
            content: h.content.slice(0, MAX_MESSAGE_CHARS),
        }));

    const completion = await groq.chat.completions.create({
        model: CHAT_MODEL,
        messages: [
            { role: 'system', content: buildFullChatSystemMessage(input) },
            ...history,
            { role: 'user', content: msg },
        ],
    });

    const reply = completion.choices[0]?.message?.content?.trim();
    if (!reply) throw new Error('Empty AI response');
    return { reply };
}

export type HodSuggestionInput = {
    contextText: string;
};

export type CoordinatorReportInput = {
    contextText: string;
};

function mockHodSuggestion(input: HodSuggestionInput): string {
    return `Mock HOD guidance (no Groq key):\n\nReview ${input.contextText.slice(0, 120)}…\n- Confirm eligibility and documentation\n- Align with department placement policy\n- Follow up on pending items`;
}

function mockCoordinatorReport(input: CoordinatorReportInput): string {
    return `Mock coordinator report (no Groq key):\n\nContext summary: ${input.contextText.slice(0, 200)}…\n- Track outstanding placements\n- Engage supervisors on delayed feedback\n- Share weekly status with university leadership`;
}

export async function generateHodSuggestion(input: HodSuggestionInput): Promise<string> {
    if (!getGroqApiKey() && isAiMockEnabled()) return mockHodSuggestion(input);

    const groq = getClient();
    const completion = await groq.chat.completions.create({
        model: AI_MODEL,
        messages: [
            {
                role: 'system',
                content:
                    'You are a Head of Department advising on internship student progress and approvals. Be concise, professional, actionable. Plain text only (no JSON).',
            },
            {
                role: 'user',
                content: `Student / department context:\n${input.contextText}\n\nProvide focused HOD guidance (approvals, risks, next steps).`,
            },
        ],
    });
    const text = completion.choices[0]?.message?.content?.trim();
    if (!text) throw new Error('Empty AI response');
    return text;
}

export async function generateCoordinatorReport(input: CoordinatorReportInput): Promise<string> {
    if (!getGroqApiKey() && isAiMockEnabled()) return mockCoordinatorReport(input);

    const groq = getClient();
    const completion = await groq.chat.completions.create({
        model: AI_MODEL,
        messages: [
            {
                role: 'system',
                content:
                    'You are a university internship coordinator. Produce a short operational report: priorities, follow-ups, and risks. Plain text only (no JSON).',
            },
            {
                role: 'user',
                content: input.contextText,
            },
        ],
    });
    const text = completion.choices[0]?.message?.content?.trim();
    if (!text) throw new Error('Empty AI response');
    return text;
}
