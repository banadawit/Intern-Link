-- Add must_change_password flag to User table
ALTER TABLE "User" ADD COLUMN "must_change_password" BOOLEAN NOT NULL DEFAULT false;
