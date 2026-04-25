/*
  Warnings:

  - You are about to drop the `HodProfile` table. If the table is not empty, all the data it contains will be lost.

*/
-- CreateEnum
CREATE TYPE "FileType" AS ENUM ('VERIFICATION_DOC', 'WEEKLY_PRESENTATION', 'COMPANY_STAMP', 'FINAL_REPORT', 'COMMON_FEED_IMAGE', 'COMMON_FEED_DOCUMENT');

-- DropForeignKey
ALTER TABLE "HodProfile" DROP CONSTRAINT "HodProfile_universityId_fkey";

-- DropForeignKey
ALTER TABLE "HodProfile" DROP CONSTRAINT "HodProfile_userId_fkey";

-- DropTable
DROP TABLE "HodProfile";

-- CreateTable
CREATE TABLE "files" (
    "id" TEXT NOT NULL,
    "userId" INTEGER,
    "organizationId" INTEGER,
    "type" "FileType" NOT NULL,
    "url" TEXT NOT NULL,
    "publicId" TEXT NOT NULL,
    "filename" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "size" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "files_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "files_userId_type_idx" ON "files"("userId", "type");

-- CreateIndex
CREATE INDEX "files_organizationId_type_idx" ON "files"("organizationId", "type");
