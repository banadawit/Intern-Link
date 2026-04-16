# Database Reset Instructions

## Problem
You're experiencing migration conflicts and need to reset the database from scratch.

## Solution: Manual Reset (Recommended)

Follow these steps **in order**:

### Step 1: Stop All Running Processes
1. **Close your terminal** where `npm run dev` is running
2. Press `Ctrl+C` to stop the server
3. Wait 5 seconds for the process to fully stop

### Step 2: Clean Prisma Cache
Open a **NEW terminal** and run:
```bash
cd apps/backend
Remove-Item -Recurse -Force node_modules\.prisma
```

### Step 3: Reset Database
```bash
npx prisma db push --force-reset --accept-data-loss
```

This will:
- ✅ Drop all tables
- ✅ Recreate schema from scratch
- ✅ Apply current schema.prisma

### Step 4: Generate Prisma Client
```bash
npx prisma generate
```

### Step 5: Seed Database
```bash
npm run seed
```

This will create:
- ✅ Demo users (Admin, Coordinator, Supervisor, Student, HOD)
- ✅ 5 sample posts
- ✅ Sample comments and likes

### Step 6: Start Server
```bash
npm run dev
```

---

## Alternative: Automated Script

If you prefer, run the automated script:

```bash
cd apps/backend
powershell -ExecutionPolicy Bypass -File reset-database.ps1
```

---

## Verification

After reset, you should see:
```
✅ Admin user created
✅ Demo supervisor created
✅ Demo university created
✅ Demo coordinator created
✅ Demo HOD created
✅ Demo student created
✅ Admin announcement post created
✅ Coordinator announcement post created
✅ Supervisor opportunity post created
✅ Student experience posts created
✅ Sample comments created
✅ Sample likes created
```

---

## Test Accounts

After reset, login with:

| Role | Email | Password |
|------|-------|----------|
| Admin | ayanafileorg@gmail.com | 12121212 |
| Coordinator | coordinator@haramaya.edu | Coord123! |
| Supervisor | supervisor@company.com | Super123! |
| Student | student@haramaya.edu | Student123! |
| HOD | hod@haramaya.edu | Hod12345 |

---

## Troubleshooting

### Error: "EPERM: operation not permitted"
**Solution:** The file is locked by a running process.
1. Close ALL terminals
2. Wait 10 seconds
3. Open a NEW terminal
4. Try again

### Error: "Cannot connect to database"
**Solution:** Check your `.env` file has correct `DATABASE_URL`

### Error: "Migration failed"
**Solution:** Use `db push` instead of `migrate`:
```bash
npx prisma db push --force-reset --accept-data-loss
```

---

## What Gets Reset

✅ All tables dropped  
✅ All data deleted  
✅ Schema recreated from scratch  
✅ Fresh Prisma client generated  
✅ Sample data seeded  

---

## What Stays

✅ Your code files  
✅ Your schema.prisma  
✅ Your migrations folder (for reference)  
✅ Your .env configuration  

---

## Next Steps

1. Start backend: `npm run dev`
2. Start frontend: `cd ../frontend && npm run dev`
3. Login with test accounts
4. Check Common Feed at `/common-feed`

---

**Status:** Ready to reset! Follow the steps above.
