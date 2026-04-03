-- Add HOD to Role enum
ALTER TYPE "Role" ADD VALUE 'HOD';

-- Create HodProfile table
CREATE TABLE "HodProfile" (
    "id"           SERIAL       NOT NULL,
    "userId"       INTEGER      NOT NULL,
    "universityId" INTEGER      NOT NULL,
    "department"   TEXT         NOT NULL,
    "employeeId"   TEXT,

    CONSTRAINT "HodProfile_pkey" PRIMARY KEY ("id")
);

-- Unique constraint: one profile per user
CREATE UNIQUE INDEX "HodProfile_userId_key" ON "HodProfile"("userId");

-- Foreign keys
ALTER TABLE "HodProfile" ADD CONSTRAINT "HodProfile_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "HodProfile" ADD CONSTRAINT "HodProfile_universityId_fkey"
    FOREIGN KEY ("universityId") REFERENCES "University"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
