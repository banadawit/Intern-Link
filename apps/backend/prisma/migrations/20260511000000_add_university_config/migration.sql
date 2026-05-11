-- CreateTable
CREATE TABLE "UniversityConfig" (
    "id" SERIAL NOT NULL,
    "universityId" INTEGER NOT NULL,
    "studentRegistrationEnabled" BOOLEAN,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UniversityConfig_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "UniversityConfig_universityId_key" ON "UniversityConfig"("universityId");

-- AddForeignKey
ALTER TABLE "UniversityConfig" ADD CONSTRAINT "UniversityConfig_universityId_fkey" FOREIGN KEY ("universityId") REFERENCES "University"("id") ON DELETE CASCADE ON UPDATE CASCADE;
