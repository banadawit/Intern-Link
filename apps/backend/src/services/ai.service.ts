import OpenAI from 'openai';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { Role } from '@prisma/client';

/** Reads OPENAI_API_KEY with trim, optional quotes, and BOM stripped (common .env issues). */
export function getOpenAiApiKey(): string | undefined {
    return normalizeApiKeyEnv(process.env.OPENAI_API_KEY);
}

/** Google AI Studio / Gemini — free tier friendly for chat. */
export function getGeminiApiKey(): string | undefined {
    return normalizeApiKeyEnv(process.env.GEMINI_API_KEY ?? process.env.GOOGLE_GENERATIVE_AI_API_KEY);
}

function normalizeApiKeyEnv(raw: string | undefined): string | undefined {
    if (raw == null || typeof raw !== 'string') return undefined;
    let v = raw.trim().replace(/^\uFEFF/, '');
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
        v = v.slice(1, -1).trim();
    }
    return v.length > 0 ? v : undefined;
}

/** Model for JSON endpoints (weekly plan, feedback). */
const AI_MODEL = process.env.OPENAI_MODEL || 'gpt-4o-mini';

/** Model for conversational chat only (OpenAI path). */
const CHAT_MODEL = process.env.OPENAI_CHAT_MODEL || 'gpt-4o';

/** Gemini chat model (Google AI Studio). */
const GEMINI_CHAT_MODEL = process.env.GEMINI_CHAT_MODEL || 'gemini-2.5-flash';

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
    /** App role from JWT — drives system prompt */
    appRole: Role;
    userId: number;
    /** Display name from User.full_name — personalize greetings and role scope */
    userDisplayName: string;
};

export type ChatResult = {
    reply: string;
};

function getClient(): OpenAI {
    const key = getOpenAiApiKey();
    if (!key) {
        const err = new Error('AI_UNAVAILABLE') as Error & { code: string };
        err.code = 'AI_UNAVAILABLE';
        throw err;
    }
    return new OpenAI({ apiKey: key });
}

export function isAiConfigured(): boolean {
    return Boolean(getOpenAiApiKey()) || isAiMockEnabled();
}

/** Chat: Gemini (preferred if GEMINI_API_KEY) or OpenAI — AI_USE_MOCK does not supply chat. */
export function isChatAiConfigured(): boolean {
    return Boolean(getGeminiApiKey()) || Boolean(getOpenAiApiKey());
}

/** Shared system prompt for Gemini + OpenAI chat — Intern-Link domain and all roles */
const CHAT_SYSTEM_MESSAGE = `You are a smart AI assistant for the Intern-Link platform, which manages internships for students, supervisors, coordinators, and admins.

You understand the following:

1. Student role:
- Weekly plan generation
- Suggesting tasks based on skills and internship type
- Improving writing (plans, reports)
- Generating presentation content
- Explaining supervisor feedback

2. Supervisor role:
- Reviewing student plans
- Suggesting approve/reject decisions
- Generating feedback comments
- Summarizing student performance
- Helping write final evaluations

3. Coordinator role:
- Analyzing student performance across companies
- Detecting low-performing students or inactive supervisors
- Generating reports
- Recommending placements

4. Admin role:
- Monitoring system usage
- Detecting unusual activity
- Auto-moderating content
- Generating system analytics

General guidelines:
- Respond naturally, like a human, in conversational chat form
- Understand user role and tailor answers accordingly
- Give actionable advice and suggestions
- Use friendly greetings and maintain context across conversation
- Ask clarifying questions if needed to give more accurate answers
- Never auto-submit plans; always let users review and edit
- You do not have live access to Intern-Link database or logs. Do not invent specific names, counts, or events—if asked for data you cannot see, say so and suggest what to check in the app or ask the user to paste context

Examples:
Student: I'm a backend intern working with Node.js, what should I do this week?
Assistant: Here's a suggestion: implement your API endpoints, write unit tests for your backend, and prepare a mini demo for your supervisor. What week are you on?

Student: Can you improve my weekly plan draft?
Assistant: Sure! Please paste your plan, and I'll suggest improvements.

Supervisor: Generate feedback for student John Doe's weekly plan.
Assistant: John is making good progress. Recommend focusing more on testing and code documentation.

Coordinator: Show me students with low activity this week.
Assistant: 5 students have not submitted plans this week. You may want to follow up with them.

Admin: Any unusual activity this week?
Assistant: There was a spike in rejected plans on Wednesday. Consider reviewing the system logs for details.`;

function sanitizeChatDisplayName(name: string): string {
    return name.replace(/[\r\n\u0000]/g, ' ').trim().slice(0, 120) || 'there';
}

const ROLE_CHAT_FOCUS: Record<Role, { article: string; focus: string }> = {
    [Role.STUDENT]: {
        article: 'a student',
        focus:
            'student intern work only: weekly plans, tasks, skills, reports, presentations, and understanding supervisor feedback.',
    },
    [Role.SUPERVISOR]: {
        article: 'a supervisor',
        focus:
            'supervisor work only: reviewing student plans, feedback, approvals context, evaluations, and supporting your interns.',
    },
    [Role.COORDINATOR]: {
        article: 'a coordinator',
        focus:
            'coordinator work only: placements, cohorts, student support, and university-side reporting.',
    },
    [Role.HOD]: {
        article: 'a Head of Department',
        focus:
            'HOD work only: department-level student approvals, placements, company outreach, and internship progress for their department.',
    },
    [Role.ADMIN]: {
        article: 'an administrator',
        focus: 'admin work only: platform oversight, verification, analytics, and operational guidance.',
    },
};

function buildChatSessionInstruction(displayName: string, appRole: Role): string {
    const name = sanitizeChatDisplayName(displayName);
    const first = name.split(/\s+/)[0] || name;
    const r = ROLE_CHAT_FOCUS[appRole];
    return `Session context (user is already logged in—do not ask them to choose a role):
The user's name is "${name}". They are signed in to Intern-Link as ${r.article}.
Greet them naturally using their name when appropriate (e.g. "Hey ${first}!" or "Hi ${name}").
Help only with ${r.focus}
Do not ask "are you a student, supervisor, coordinator, or admin" or list every role. Stay in this role unless they explicitly ask about another role.`;
}

function buildFullChatSystemMessage(input: ChatInput): string {
    return `${CHAT_SYSTEM_MESSAGE}\n\n${buildChatSessionInstruction(input.userDisplayName, input.appRole)}`;
}

function mockWeeklyPlan(input: WeeklyPlanInput): WeeklyPlanResult {
    return {
        tasks: `- Focused work on ${input.field} (week ${input.week})\n- Check in with your supervisor\n- Practice: ${input.skills}`,
        goals: `Ship one small outcome and reflect on what you learned.`,
        deliverables: `Brief summary of progress and blockers (dev mode without OpenAI key).`,
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
    if (!getOpenAiApiKey() && isAiMockEnabled()) {
        return mockWeeklyPlan(input);
    }
    const openai = getClient();
    const userPrompt = `Generate a structured weekly internship plan.

Field: ${input.field}
Week number: ${input.week}
Skills (comma-separated or free text): ${input.skills}
Internship type: ${input.internshipType}

Return a JSON object with exactly these string fields:
- "tasks": bullet-style or numbered tasks for the week
- "goals": learning and delivery goals
- "deliverables": concrete outputs expected by end of week`;

    const completion = await openai.chat.completions.create({
        model: AI_MODEL,
        response_format: { type: 'json_object' },
        messages: [
            {
                role: 'system',
                content:
                    'You are an internship coach for InternLink. Respond only with valid JSON matching the user schema. Be practical and concise.',
            },
            { role: 'user', content: userPrompt },
        ],
    });

    const raw = completion.choices[0]?.message?.content;
    if (!raw) {
        throw new Error('Empty AI response');
    }
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    return {
        tasks: String(parsed.tasks ?? ''),
        goals: String(parsed.goals ?? ''),
        deliverables: String(parsed.deliverables ?? ''),
    };
}

export async function generateFeedback(input: FeedbackInput): Promise<FeedbackResult> {
    if (!getOpenAiApiKey() && isAiMockEnabled()) {
        return mockFeedback(input);
    }
    const openai = getClient();
    const ctx = [
        input.studentName ? `Student: ${input.studentName}` : null,
        input.week != null ? `Week: ${input.week}` : null,
        `Plan text:\n${input.plan}`,
    ]
        .filter(Boolean)
        .join('\n');

    const userPrompt = `Review the following student weekly internship plan and respond with JSON only.

${ctx}

Return a JSON object with exactly these string fields:
- "strengths"
- "weaknesses"
- "suggestions" (actionable for the student)`;

    const completion = await openai.chat.completions.create({
        model: AI_MODEL,
        response_format: { type: 'json_object' },
        messages: [
            {
                role: 'system',
                content:
                    'You are a professional workplace supervisor reviewing an intern weekly plan. Be constructive and specific. JSON only.',
            },
            { role: 'user', content: userPrompt },
        ],
    });

    const raw = completion.choices[0]?.message?.content;
    if (!raw) {
        throw new Error('Empty AI response');
    }
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    return {
        strengths: String(parsed.strengths ?? ''),
        weaknesses: String(parsed.weaknesses ?? ''),
        suggestions: String(parsed.suggestions ?? ''),
    };
}

const MAX_HISTORY = 20;
const MAX_MESSAGE_CHARS = 8000;

async function chatAssistantOpenAI(input: ChatInput, msg: string): Promise<ChatResult> {
    const openai = getClient();

    const history = (input.history ?? [])
        .slice(-MAX_HISTORY)
        .map((h) => ({
            role: h.role === 'assistant' ? ('assistant' as const) : ('user' as const),
            content: h.content.slice(0, MAX_MESSAGE_CHARS),
        }));

    const messages = [
        { role: 'system' as const, content: CHAT_SYSTEM_MESSAGE },
        ...history.map((h) =>
            h.role === 'assistant'
                ? ({ role: 'assistant' as const, content: h.content })
                : ({ role: 'user' as const, content: h.content })
        ),
        { role: 'user' as const, content: msg },
    ];

    const completion = await openai.chat.completions.create({
        model: CHAT_MODEL,
        messages,
    });

    const reply = completion.choices[0]?.message?.content?.trim();
    if (!reply) {
        throw new Error('Empty AI response');
    }
    return { reply };
}

async function chatAssistantGemini(input: ChatInput, msg: string): Promise<ChatResult> {
    const key = getGeminiApiKey();
    if (!key) {
        const err = new Error('AI_UNAVAILABLE') as Error & { code: string };
        err.code = 'AI_UNAVAILABLE';
        throw err;
    }

    const genAI = new GoogleGenerativeAI(key);
    const model = genAI.getGenerativeModel({
        model: GEMINI_CHAT_MODEL,
        systemInstruction: buildFullChatSystemMessage(input),
    });

    const prior = (input.history ?? []).slice(-MAX_HISTORY).map((h) => ({
        role: (h.role === 'assistant' ? 'model' : 'user') as 'user' | 'model',
        parts: [{ text: h.content.slice(0, MAX_MESSAGE_CHARS) }],
    }));

    const chat = model.startChat({ history: prior });
    const result = await chat.sendMessage(msg);
    const reply = result.response.text().trim();
    if (!reply) {
        throw new Error('Empty AI response');
    }
    return { reply };
}

/**
 * Chat: uses Gemini when GEMINI_API_KEY (or GOOGLE_GENERATIVE_AI_API_KEY) is set; otherwise OpenAI.
 * Set AI_CHAT_PROVIDER=openai to force OpenAI when both keys exist.
 */
export async function chatAssistant(input: ChatInput): Promise<ChatResult> {
    const msg = input.message.trim().slice(0, MAX_MESSAGE_CHARS);
    if (!msg) {
        throw new Error('Message is required');
    }

    const forceOpenAi = process.env.AI_CHAT_PROVIDER?.trim().toLowerCase() === 'openai';
    const preferGemini = getGeminiApiKey() && !forceOpenAi;

    if (preferGemini) {
        return chatAssistantGemini(input, msg);
    }
    return chatAssistantOpenAI(input, msg);
}
