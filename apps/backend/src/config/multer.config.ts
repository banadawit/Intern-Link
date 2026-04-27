import multer from 'multer';

// Use memory storage for Cloudinary uploads
const storage = multer.memoryStorage();

// File filter for images
const imageFileFilter = (req: any, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    const allowedMimes = ['image/jpeg', 'image/jpg', 'image/png'];
    
    if (allowedMimes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only JPG and PNG images are allowed.'));
    }
};

// File filter for documents
const documentFileFilter = (req: any, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    const allowedMimes = [
        'application/pdf',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    ];
    
    if (allowedMimes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only PDF and PPT files are allowed.'));
    }
};

// File filter for verification documents (PDF only)
const verificationFileFilter = (req: any, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    if (file.mimetype === 'application/pdf') {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only PDF files are allowed for verification.'));
    }
};

// Create multer instances
export const uploadImage = multer({
    storage,
    fileFilter: imageFileFilter,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

export const uploadDocument = multer({
    storage,
    fileFilter: documentFileFilter,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

export const uploadVerification = multer({
    storage,
    fileFilter: verificationFileFilter,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

// Middleware exports
export const uploadSingleImage = uploadImage.single('file');
export const uploadSingleDocument = uploadDocument.single('file');
export const uploadVerificationDocument = uploadVerification.single('verification_document');
export const uploadMultipleImages = uploadImage.array('images', 5);
export const uploadMultipleDocuments = uploadDocument.array('documents', 3);