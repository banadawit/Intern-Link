import express from 'express';
import { authenticate } from '../middlewares/authMiddleware';
import {
  saveFileMetadata,
  deleteFile,
  getUserFiles,
} from '../controllers/fileController';

const router = express.Router();

// All routes require authentication
router.use(authenticate);

// Save file metadata after frontend upload
router.post('/save-metadata', saveFileMetadata);

// Delete file
router.delete('/:fileId', deleteFile);

// Get user files
router.get('/my-files', getUserFiles);

export default router;
