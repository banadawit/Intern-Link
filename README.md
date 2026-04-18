# Intern-Link

Intern-Link is a full-stack internship management platform that connects students, universities, and companies in one workflow.

It includes:
- A Node.js + Express backend API with Prisma/PostgreSQL
- A Next.js web application for role-based dashboards and operations
- A Flutter mobile application for mobile-first access

## Table of Contents

- [Project Overview](#project-overview)
- [Monorepo Structure](#monorepo-structure)
- [Core Features](#core-features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Run the Applications](#run-the-applications)
- [Database and Seeding](#database-and-seeding)
- [Mobile App Notes](#mobile-app-notes)
- [Scripts Reference](#scripts-reference)
- [API Overview](#api-overview)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Project Overview

Intern-Link manages the end-to-end internship lifecycle:
- Institution and company onboarding
- Role-based access for Admin, Coordinator, HOD, Supervisor, and Student
- Student placement and progress tracking
- Weekly plans, reports, and feedback loops
- Notifications and communication channels
- AI-assisted planning and chat features (optional via API keys)

## Monorepo Structure

```text
Intern-Link/
  apps/
    backend/            # Express + Prisma API
    frontend/           # Next.js web app
    intern_mobile_app/  # Flutter mobile app
  docs/                 # Project documentation (reserved)
  infrastructure/       # Infra assets (reserved)
  packages/             # Shared packages (reserved)
  tests/                # Cross-app tests (reserved)
  package.json          # Root scripts for orchestrating apps
```

## Core Features

- Multi-role authentication and authorization
- Internship placement and assignment management
- Weekly planning and supervisor feedback workflows
- Common feed and activity tracking
- Notifications and email-based flows
- AI-powered assistant endpoints for selected workflows

## Tech Stack

Backend:
- Node.js + TypeScript
- Express
- Prisma ORM
- PostgreSQL

Web Frontend:
- Next.js
- React
- TypeScript
- Tailwind CSS

Mobile Frontend:
- Flutter
- Riverpod
- Dio/HTTP

## Getting Started

### Prerequisites

Install the following tools:
- Node.js 18+ (LTS recommended)
- npm 9+
- PostgreSQL 14+ (or managed Postgres, e.g. Supabase)
- Flutter SDK (stable channel) for mobile development

### 1) Install dependencies

From repository root:

```bash
npm install
```

Install app dependencies:

```bash
npm install --prefix apps/backend
npm install --prefix apps/frontend
```

For mobile app:

```bash
cd apps/intern_mobile_app
flutter pub get
```

### 2) Configure environment files

Copy the templates and fill in values:

```bash
copy apps\\backend\\.env.example apps\\backend\\.env
copy apps\\frontend\\.env.example apps\\frontend\\.env.local
```

### 3) Set up database

From `apps/backend`:

```bash
npx prisma generate
npx prisma db push
npm run seed
```

### 4) Start services

From repository root (backend + frontend together):

```bash
npm run dev
```

Backend default URL: `http://localhost:5000`

Frontend default URL: `http://localhost:3000`

## Environment Configuration

### Backend (`apps/backend/.env`)

Minimum required values:

```env
PORT=5000
DATABASE_URL="postgresql://user:password@localhost:5432/intern_link"
JWT_SECRET=your_jwt_secret_here
NODE_ENV="development"
```

Optional AI-related values:

```env
# Gemini
GEMINI_API_KEY=
# GOOGLE_GENERATIVE_AI_API_KEY=
# GEMINI_CHAT_MODEL=gemini-2.5-flash

# OpenAI
OPENAI_API_KEY=
# OPENAI_MODEL=gpt-4o-mini
# OPENAI_CHAT_MODEL=gpt-4o

# Force provider or mock mode
# AI_CHAT_PROVIDER=openai
# AI_USE_MOCK=true
```

Additional optional integrations used by backend services:

```env
# Email (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=
SMTP_PASS=
ADMIN_NOTIFICATION_EMAIL=
ADMIN_NOTIFICATION_EMAILS=

# Frontend URL for email links
FRONTEND_URL=http://localhost:3000

# File uploads (optional)
SUPABASE_URL=
SUPABASE_KEY=
```

### Frontend (`apps/frontend/.env.local`)

```env
NEXT_PUBLIC_API_URL=http://localhost:5000/api
```

## Run the Applications

### Run backend + frontend together

From repository root:

```bash
npm run dev
```

### Run backend only

```bash
cd apps/backend
npm run dev
```

### Run frontend only

```bash
cd apps/frontend
npm run dev
```

### Run mobile app

```bash
cd apps/intern_mobile_app
flutter run
```

## Database and Seeding

Backend uses Prisma with PostgreSQL.

Typical setup (inside `apps/backend`):

```bash
npx prisma generate
npx prisma db push
npm run seed
```

If you need a full reset, see:
- `apps/backend/RESET_DATABASE.md`
- `apps/backend/reset-database.ps1`

## Mobile App Notes

- Default mobile API base points to Android emulator loopback:
  - `http://10.0.2.2:5000/api`
- You can override the base URL at build/run time with Dart define:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:5000/api
```

If you are using a physical device, replace `localhost` with your machine LAN IP.

## Scripts Reference

### Root

- `npm run dev`: Runs backend and frontend concurrently

### Backend (`apps/backend`)

- `npm run dev`: Start backend in development
- `npm run build`: Compile TypeScript
- `npm run start`: Run compiled server (`dist/index.js`)
- `npm run seed`: Seed database data

### Frontend (`apps/frontend`)

- `npm run dev`: Start Next.js dev server
- `npm run build`: Build production bundle
- `npm run start`: Start production server
- `npm run lint`: Run ESLint

## API Overview

Base URL:
- `http://localhost:5000`

Health check:
- `GET /`

Main route groups:
- `/api/auth`
- `/api/admin`
- `/api/universities`
- `/api/companies`
- `/api/students`
- `/api/placements`
- `/api/progress`
- `/api/reports`
- `/api/feed`
- `/api/supervisor`
- `/api/coordinator`
- `/api/coordinator-portal`
- `/api/ai`
- `/api/activity`
- `/api/hod`
- `/api/common-feed`
- `/api/chat`
- `/api/notifications`

## Troubleshooting

Common issues:
- Port conflicts on `3000` or `5000`: stop conflicting processes or change ports.
- Prisma/client errors after schema updates: run `npx prisma generate` again.
- Database reset and migration conflicts: follow `apps/backend/RESET_DATABASE.md`.
- Flutter on Windows + OneDrive can sometimes lock plugin symlinks; retry `flutter pub get` if needed.

## Contributing

1. Create a feature branch.
2. Keep changes scoped and documented.
3. Run app-level lint/build checks before opening a pull request.
4. Open a PR with a clear summary, testing notes, and screenshots for UI changes.

## License

No license file is currently defined in this repository.
If you plan to make this open source, add a `LICENSE` file (for example MIT or Apache-2.0).
