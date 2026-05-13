-- Expand FinalEvaluation: replace 2 scores with 10 individual criteria

ALTER TABLE "FinalEvaluation"
  ADD COLUMN IF NOT EXISTS "technical_skills"        DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS "problem_solving"         DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS "communication"           DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS "team_collaboration"      DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS "time_management"         DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS "adaptability"            DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS "professionalism"         DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS "initiative_creativity"   DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS "attendance_punctuality"  DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS "task_completion_quality" DECIMAL(5,2);

-- Migrate existing data: map old scores to new fields
UPDATE "FinalEvaluation" SET
  "technical_skills"        = "technical_score",
  "problem_solving"         = "technical_score",
  "communication"           = "soft_skill_score",
  "team_collaboration"      = "soft_skill_score",
  "time_management"         = "soft_skill_score",
  "adaptability"            = "soft_skill_score",
  "professionalism"         = "soft_skill_score",
  "initiative_creativity"   = "soft_skill_score",
  "attendance_punctuality"  = "soft_skill_score",
  "task_completion_quality" = "technical_score"
WHERE "technical_score" IS NOT NULL;

-- Set NOT NULL after migration
ALTER TABLE "FinalEvaluation"
  ALTER COLUMN "technical_skills"        SET NOT NULL,
  ALTER COLUMN "problem_solving"         SET NOT NULL,
  ALTER COLUMN "communication"           SET NOT NULL,
  ALTER COLUMN "team_collaboration"      SET NOT NULL,
  ALTER COLUMN "time_management"         SET NOT NULL,
  ALTER COLUMN "adaptability"            SET NOT NULL,
  ALTER COLUMN "professionalism"         SET NOT NULL,
  ALTER COLUMN "initiative_creativity"   SET NOT NULL,
  ALTER COLUMN "attendance_punctuality"  SET NOT NULL,
  ALTER COLUMN "task_completion_quality" SET NOT NULL;

-- Drop old columns
ALTER TABLE "FinalEvaluation"
  DROP COLUMN IF EXISTS "technical_score",
  DROP COLUMN IF EXISTS "soft_skill_score";
