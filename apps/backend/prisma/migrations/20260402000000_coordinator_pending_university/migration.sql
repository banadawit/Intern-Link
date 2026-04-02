-- Make universityId optional on Coordinator (late-creation workflow)
ALTER TABLE "Coordinator" ALTER COLUMN "universityId" DROP NOT NULL;

-- Add pending_university_name to store the name before admin approval
ALTER TABLE "Coordinator" ADD COLUMN "pending_university_name" TEXT;
