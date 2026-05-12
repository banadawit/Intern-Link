import { Router } from 'express';
import { submitSupportRequest } from '../controllers/supportController';

const router = Router();

// Public — no auth required so locked-out users can reach support
router.post('/', submitSupportRequest);

export default router;
