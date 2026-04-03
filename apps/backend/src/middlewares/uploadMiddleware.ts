import multer from 'multer';
import path from 'path';
import fs from 'fs';

// Ensure upload directory exists
const uploadDir = 'uploads/stamps';
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        // Filename format: stamp-1712345678.png
        cb(null, `stamp-${Date.now()}${path.extname(file.originalname)}`);
    }
});

export const uploadStamp = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
    fileFilter: (req, file, cb) => {
        const fileTypes = /jpeg|jpg|png/; // Only images for stamps
        const extname = fileTypes.test(path.extname(file.originalname).toLowerCase());
        if (extname) return cb(null, true);
        cb(new Error("Only images (JPG/PNG) are allowed for stamps"));
    }
});
export const uploadPresentation = multer({
    storage: multer.diskStorage({
        destination: 'uploads/presentations/',
        filename: (req, file, cb) => {
            cb(null, `plan-${Date.now()}${path.extname(file.originalname)}`);
        }
    }),
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit per SDD 2.6.2
});


// Generic upload middleware for common feed
export const upload = multer({
    storage: multer.memoryStorage(), // Store in memory for Supabase upload
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
    fileFilter: (req, file, cb) => {
        const allowedTypes = /jpeg|jpg|png|gif|webp|pdf|doc|docx|ppt|pptx/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        if (extname) return cb(null, true);
        cb(new Error("Invalid file type"));
    }
});
