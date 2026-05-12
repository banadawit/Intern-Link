/**
 * Ethiopian Universities Seeder
 * Run: npx ts-node prisma/seed_ethiopian_universities.ts
 *
 * Idempotent — safe to run multiple times.
 * Uses normalized_name for duplicate detection.
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/** Normalize a name for duplicate detection: lowercase, trim, collapse spaces */
function normalize(name: string): string {
  return name.toLowerCase().trim().replace(/\s+/g, ' ');
}

interface UniversityEntry {
  name: string;
  region?: string;
  website?: string;
  email_domain?: string;
  city?: string;
}

const ETHIOPIAN_UNIVERSITIES: UniversityEntry[] = [
  // ── Federal Universities ──────────────────────────────────────────────────
  { name: 'Addis Ababa University', region: 'Addis Ababa', city: 'Addis Ababa', website: 'https://www.aau.edu.et', email_domain: 'aau.edu.et' },
  { name: 'Addis Ababa Science and Technology University', region: 'Addis Ababa', city: 'Addis Ababa', website: 'https://www.aastu.edu.et', email_domain: 'aastu.edu.et' },
  { name: 'Adama Science and Technology University', region: 'Oromia', city: 'Adama', website: 'https://www.adama.edu.et', email_domain: 'adama.edu.et' },
  { name: 'Arba Minch University', region: 'SNNPR', city: 'Arba Minch', website: 'https://www.amu.edu.et', email_domain: 'amu.edu.et' },
  { name: 'Bahir Dar University', region: 'Amhara', city: 'Bahir Dar', website: 'https://www.bdu.edu.et', email_domain: 'bdu.edu.et' },
  { name: 'Debre Berhan University', region: 'Amhara', city: 'Debre Berhan', website: 'https://www.dbu.edu.et', email_domain: 'dbu.edu.et' },
  { name: 'Debre Markos University', region: 'Amhara', city: 'Debre Markos', website: 'https://www.dmu.edu.et', email_domain: 'dmu.edu.et' },
  { name: 'Debre Tabor University', region: 'Amhara', city: 'Debre Tabor', website: 'https://www.dtu.edu.et', email_domain: 'dtu.edu.et' },
  { name: 'Dilla University', region: 'SNNPR', city: 'Dilla', website: 'https://www.du.edu.et', email_domain: 'du.edu.et' },
  { name: 'Dire Dawa University', region: 'Dire Dawa', city: 'Dire Dawa', website: 'https://www.ddu.edu.et', email_domain: 'ddu.edu.et' },
  { name: 'Gondar University', region: 'Amhara', city: 'Gondar', website: 'https://www.uog.edu.et', email_domain: 'uog.edu.et' },
  { name: 'Haramaya University', region: 'Oromia', city: 'Haramaya', website: 'https://www.haramaya.edu.et', email_domain: 'haramaya.edu.et' },
  { name: 'Hawassa University', region: 'SNNPR', city: 'Hawassa', website: 'https://www.hu.edu.et', email_domain: 'hu.edu.et' },
  { name: 'Jigjiga University', region: 'Somali', city: 'Jigjiga', website: 'https://www.jju.edu.et', email_domain: 'jju.edu.et' },
  { name: 'Jimma University', region: 'Oromia', city: 'Jimma', website: 'https://www.ju.edu.et', email_domain: 'ju.edu.et' },
  { name: 'Mekelle University', region: 'Tigray', city: 'Mekelle', website: 'https://www.mu.edu.et', email_domain: 'mu.edu.et' },
  { name: 'Mizan-Tepi University', region: 'SNNPR', city: 'Mizan-Teferi', website: 'https://www.mtu.edu.et', email_domain: 'mtu.edu.et' },
  { name: 'Samara University', region: 'Afar', city: 'Samara', website: 'https://www.su.edu.et', email_domain: 'su.edu.et' },
  { name: 'Wolaita Sodo University', region: 'SNNPR', city: 'Wolaita Sodo', website: 'https://www.wsu.edu.et', email_domain: 'wsu.edu.et' },
  { name: 'Wollo University', region: 'Amhara', city: 'Dessie', website: 'https://www.wu.edu.et', email_domain: 'wu.edu.et' },
  // ── Additional Public Universities ────────────────────────────────────────
  { name: 'Aksum University', region: 'Tigray', city: 'Aksum', website: 'https://www.aku.edu.et', email_domain: 'aku.edu.et' },
  { name: 'Ambo University', region: 'Oromia', city: 'Ambo', website: 'https://www.ambou.edu.et', email_domain: 'ambou.edu.et' },
  { name: 'Assosa University', region: 'Benishangul-Gumuz', city: 'Assosa', website: 'https://www.asu.edu.et', email_domain: 'asu.edu.et' },
  { name: 'Bule Hora University', region: 'Oromia', city: 'Bule Hora', website: 'https://www.bhu.edu.et', email_domain: 'bhu.edu.et' },
  { name: 'Gambella University', region: 'Gambella', city: 'Gambella', website: 'https://www.gu.edu.et', email_domain: 'gu.edu.et' },
  { name: 'Injibara University', region: 'Amhara', city: 'Injibara', website: 'https://www.iu.edu.et', email_domain: 'iu.edu.et' },
  { name: 'Kebri Dehar University', region: 'Somali', city: 'Kebri Dehar', website: 'https://www.kdu.edu.et', email_domain: 'kdu.edu.et' },
  { name: 'Kotebe Metropolitan University', region: 'Addis Ababa', city: 'Addis Ababa', website: 'https://www.kmu.edu.et', email_domain: 'kmu.edu.et' },
  { name: 'Madda Walabu University', region: 'Oromia', city: 'Bale Robe', website: 'https://www.mwu.edu.et', email_domain: 'mwu.edu.et' },
  { name: 'Mettu University', region: 'Oromia', city: 'Mettu', website: 'https://www.mettu.edu.et', email_domain: 'mettu.edu.et' },
  { name: 'Oda Bultum University', region: 'Oromia', city: 'Chiro', website: 'https://www.obu.edu.et', email_domain: 'obu.edu.et' },
  { name: 'Raya University', region: 'Tigray', city: 'Maichew', website: 'https://www.raya.edu.et', email_domain: 'raya.edu.et' },
  { name: 'Semera University', region: 'Afar', city: 'Semera', website: 'https://www.semera.edu.et', email_domain: 'semera.edu.et' },
  { name: 'Wachemo University', region: 'SNNPR', city: 'Hossana', website: 'https://www.wachemo.edu.et', email_domain: 'wachemo.edu.et' },
  { name: 'Rift Valley University', region: 'Oromia', city: 'Addis Ababa', website: 'https://www.rvu.edu.et', email_domain: 'rvu.edu.et' },
  { name: 'Ethiopian Civil Service University', region: 'Addis Ababa', city: 'Addis Ababa', website: 'https://www.ecsu.edu.et', email_domain: 'ecsu.edu.et' },
  { name: 'Defense University', region: 'Oromia', city: 'Bishoftu', website: 'https://www.du.edu.et', email_domain: 'du.edu.et' },
  { name: 'Wolkite University', region: 'SNNPR', city: 'Wolkite', website: 'https://www.wku.edu.et', email_domain: 'wku.edu.et' },
  { name: 'Jinka University', region: 'SNNPR', city: 'Jinka', website: 'https://www.ju.edu.et', email_domain: 'ju.edu.et' },
  { name: 'Bonga University', region: 'SNNPR', city: 'Bonga', website: 'https://www.bu.edu.et', email_domain: 'bu.edu.et' },
  { name: 'Werabe University', region: 'SNNPR', city: 'Werabe', website: 'https://www.wu.edu.et', email_domain: 'wu.edu.et' },
  { name: 'Adigrat University', region: 'Tigray', city: 'Adigrat', website: 'https://www.agu.edu.et', email_domain: 'agu.edu.et' },
  { name: 'Axum University', region: 'Tigray', city: 'Axum', website: 'https://www.axumuni.edu.et', email_domain: 'axumuni.edu.et' },
  { name: 'Weldia University', region: 'Amhara', city: 'Weldia', website: 'https://www.wu.edu.et', email_domain: 'wu.edu.et' },
  { name: 'Debre Birhan University', region: 'Amhara', city: 'Debre Birhan', website: 'https://www.dbu.edu.et', email_domain: 'dbu.edu.et' },
  { name: 'Hossana University', region: 'SNNPR', city: 'Hossana', website: 'https://www.hu.edu.et', email_domain: 'hu.edu.et' },
  { name: 'Mizan University', region: 'SNNPR', city: 'Mizan-Teferi', website: 'https://www.mu.edu.et', email_domain: 'mu.edu.et' },
  { name: 'Tepi University', region: 'SNNPR', city: 'Tepi', website: 'https://www.tu.edu.et', email_domain: 'tu.edu.et' },
  // ── Private Universities ──────────────────────────────────────────────────
  { name: 'Unity University', region: 'Addis Ababa', city: 'Addis Ababa', website: 'https://www.unity.edu.et', email_domain: 'unity.edu.et' },
  { name: 'St. Mary\'s University', region: 'Addis Ababa', city: 'Addis Ababa', website: 'https://www.stmarys.edu.et', email_domain: 'stmarys.edu.et' },
  { name: 'Addis Ababa Medical College', region: 'Addis Ababa', city: 'Addis Ababa', website: 'https://www.aamc.edu.et', email_domain: 'aamc.edu.et' },
  { name: 'Rift Valley University College', region: 'Addis Ababa', city: 'Addis Ababa', website: 'https://www.rvu.edu.et', email_domain: 'rvu.edu.et' },
  { name: 'Ethiopian Institute of Technology - Mekelle', region: 'Tigray', city: 'Mekelle', website: 'https://www.eit.edu.et', email_domain: 'eit.edu.et' },
];

async function seedEthiopianUniversities() {
  console.log('🌍 Seeding Ethiopian Universities...\n');

  let created = 0;
  let skipped = 0;
  let updated = 0;

  for (const entry of ETHIOPIAN_UNIVERSITIES) {
    const normalizedName = normalize(entry.name);

    // Check for existing by normalized name match
    const existing = await prisma.university.findFirst({
      where: {
        OR: [
          { name: { equals: entry.name, mode: 'insensitive' } },
          { name: { equals: normalizedName, mode: 'insensitive' } },
        ],
      },
    });

    if (existing) {
      // Update with extra metadata if missing
      const needsUpdate =
        (!existing.address && entry.region) ||
        (!existing.verification_doc && entry.website);

      if (needsUpdate) {
        await prisma.university.update({
          where: { id: existing.id },
          data: {
            address: existing.address ?? (entry.city ? `${entry.city}, ${entry.region}, Ethiopia` : entry.region),
          },
        });
        updated++;
        console.log(`  ↻ Updated: ${entry.name}`);
      } else {
        skipped++;
        console.log(`  ⊘ Skipped (exists): ${entry.name}`);
      }
      continue;
    }

    // Generate a unique placeholder email for preloaded universities
    const emailDomain = entry.email_domain ?? `${normalizedName.replace(/\s+/g, '').replace(/[^a-z0-9]/g, '')}.edu.et`;
    const officialEmail = `info@${emailDomain}`;

    // Check if email is already taken
    const emailExists = await prisma.university.findUnique({ where: { official_email: officialEmail } });
    const finalEmail = emailExists
      ? `official.${Date.now()}@${emailDomain}`
      : officialEmail;

    await prisma.university.create({
      data: {
        name: entry.name,
        official_email: finalEmail,
        address: entry.city ? `${entry.city}, ${entry.region ?? 'Ethiopia'}, Ethiopia` : (entry.region ? `${entry.region}, Ethiopia` : 'Ethiopia'),
        approval_status: 'APPROVED', // Pre-verified Ethiopian universities
        verification_doc: null,
        rejection_reason: null,
      },
    });

    created++;
    console.log(`  ✅ Created: ${entry.name} (${entry.region ?? 'Ethiopia'})`);
  }

  console.log(`\n📊 Summary:`);
  console.log(`   Created:  ${created}`);
  console.log(`   Updated:  ${updated}`);
  console.log(`   Skipped:  ${skipped}`);
  console.log(`   Total:    ${ETHIOPIAN_UNIVERSITIES.length}`);
  console.log('\n✅ Ethiopian universities seeding complete!');
}

seedEthiopianUniversities()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
