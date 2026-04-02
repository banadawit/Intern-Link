/**
 * Must be imported first from index.ts so OPENAI_API_KEY and DATABASE_URL
 * are set before any route, Prisma, or AI service module runs.
 */
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

const backendRoot = path.resolve(__dirname, '..');
const envCandidates = [
    path.join(process.cwd(), '.env'),
    path.join(process.cwd(), 'apps', 'backend', '.env'),
    path.join(backendRoot, '.env'),
    path.join(backendRoot, '.env.local'),
];

const seen = new Set<string>();
for (const file of envCandidates) {
    const abs = path.resolve(file);
    if (seen.has(abs)) continue;
    seen.add(abs);
    if (fs.existsSync(file)) {
        dotenv.config({ path: file, override: true });
    }
}

if (process.env.NODE_ENV !== 'production') {
    const strip = (s: string | undefined) =>
        s
            ? s
                  .trim()
                  .replace(/^\uFEFF/, '')
                  .replace(/^["']|["']$/g, '')
                  .trim()
            : '';
    const hasOpenAi = Boolean(strip(process.env.OPENAI_API_KEY));
    const hasGemini = Boolean(
        strip(process.env.GEMINI_API_KEY) || strip(process.env.GOOGLE_GENERATIVE_AI_API_KEY)
    );
    if (!hasOpenAi && !hasGemini) {
        console.warn(
            '[InternLink] No AI key: set GEMINI_API_KEY (https://aistudio.google.com/apikey) and/or OPENAI_API_KEY in apps/backend/.env, then restart.'
        );
    }
}

export {};
