# Database Reset Script
# This script will completely reset your database and migrations

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Database Reset Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n⚠️  WARNING: This will delete ALL data in your database!" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to cancel, or press Enter to continue..." -ForegroundColor Yellow
Read-Host

# Step 1: Stop any running processes
Write-Host "`n1. Stopping any running Node processes..." -ForegroundColor Yellow
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Step 2: Clean Prisma cache
Write-Host "`n2. Cleaning Prisma cache..." -ForegroundColor Yellow
Remove-Item -Recurse -Force node_modules\.prisma -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# Step 3: Reset database
Write-Host "`n3. Resetting database..." -ForegroundColor Yellow
npx prisma db push --force-reset --accept-data-loss

# Step 4: Generate Prisma client
Write-Host "`n4. Generating Prisma client..." -ForegroundColor Yellow
npx prisma generate

# Step 5: Seed database
Write-Host "`n5. Seeding database with sample data..." -ForegroundColor Yellow
npm run seed

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✅ Database reset complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nYou can now start the server with: npm run dev" -ForegroundColor Cyan
