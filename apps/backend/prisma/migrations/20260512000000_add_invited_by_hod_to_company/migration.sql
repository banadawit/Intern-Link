-- Add invited_by_hod_id to Company to track which HOD sent the invitation
ALTER TABLE "Company"
    ADD COLUMN IF NOT EXISTS "invited_by_hod_id" INTEGER;

ALTER TABLE "Company"
    DROP CONSTRAINT IF EXISTS "Company_invited_by_hod_id_fkey";

ALTER TABLE "Company"
    ADD CONSTRAINT "Company_invited_by_hod_id_fkey"
    FOREIGN KEY ("invited_by_hod_id") REFERENCES "Hod"("id") ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX IF NOT EXISTS "Company_invited_by_hod_id_idx" ON "Company"("invited_by_hod_id");
