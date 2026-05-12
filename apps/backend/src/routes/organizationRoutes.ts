/**
 * Public organization search routes
 * Used during registration for autocomplete and duplicate detection.
 * No authentication required — these are public lookup endpoints.
 */

import { Router } from 'express';
import {
  searchUniversities,
  getApprovedUniversities,
  checkUniversityDuplicate,
  searchCompanies,
  checkCompanyDuplicate,
} from '../controllers/universitySearchController';

const router = Router();

// ── University endpoints ──────────────────────────────────────────────────────
// GET  /universities/search?q=haramaya&limit=10  — autocomplete search
// GET  /universities/approved                    — full list for dropdowns
// POST /universities/check-duplicate             — fuzzy duplicate check
router.get('/universities/search', searchUniversities);
router.get('/universities/approved', getApprovedUniversities);
router.post('/universities/check-duplicate', checkUniversityDuplicate);

// ── Company endpoints ─────────────────────────────────────────────────────────
// GET  /companies/search?q=demo&limit=10         — autocomplete search
// POST /companies/check-duplicate                — fuzzy duplicate check
router.get('/companies/search', searchCompanies);
router.post('/companies/check-duplicate', checkCompanyDuplicate);

export default router;
