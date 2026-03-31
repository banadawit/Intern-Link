import multer from 'multer';
import path from 'path';
import fs from 'fs';

// Ensure upload directories exist
const uploadDir = 'uploads/verification-docs';
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Configure storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname);
        cb(null, `verification-${uniqueSuffix}${ext}`);
    }
});

// File filter
const fileFilter = (req: any, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    const allowedMimes = [
        'application/pdf',
        'image/jpeg',
        'image/jpg',
        'image/png'
    ];
    
    if (allowedMimes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only PDF, JPG, and PNG files are allowed.'));
    }
};

// Create multer instance
export const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024, // 5MB limit
    }
});

// Single file upload middleware
export const uploadVerificationDocument = upload.single('verification_document');