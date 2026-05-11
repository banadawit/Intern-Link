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

export type ChatInput = {
    message: string;
    history?: { role: 'user' | 'assistant'; content: string }[];
    appRole: Role | 'VISITOR';
    userId: number;
    userDisplayName: string;
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

1. Student role: weekly plan generation, task suggestions, improving writing, generating presentation content, explaining supervisor feedback.
2. Supervisor role: reviewing student plans, generating feedback, summarizing performance, writing evaluations.
3. Coordinator role: analyzing student performance, detecting low-performing students, generating reports, recommending placements.
4. Admin role: monitoring system usage, detecting unusual activity, generating analytics.

General guidelines:
- Respond naturally in conversational chat form
- Tailor answers to the user role
- Give actionable advice and suggestions
- Use friendly greetings and maintain context across conversation
- Ask clarifying questions if needed
- Never auto-submit plans; always let users review and edit
- You do not have live access to Intern-Link data. Do not invent specific names, counts, or events.`;

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

function buildFullChatSystemMessage(input: ChatInput): string {
    return `${CHAT_SYSTEM_MESSAGE}\n\n${buildChatSessionInstruction(input.userDisplayName, input.appRole)}`;
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
