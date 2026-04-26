// Load .env before any other local imports (imports are hoisted; this side-effect import must be first).
import './loadEnv';

import express, { Application, Request, Response } from 'express';
import path from 'path';
import cors from 'cors';
import authRoutes from './routes/authRoutes';

import adminRoutes from './routes/adminRoutes';
import companyRoutes from './routes/companyRoutes';
import universityRoutes from './routes/universityRoutes';
import studentRoutes from './routes/studentRoutes';
import placementRoutes from './routes/placementRoutes';
import progressRoutes from './routes/progressRoutes';
import reportRoutes from './routes/reportRoutes';
import feedRoutes from './routes/feedRoutes';
import supervisorRoutes from './routes/supervisorRoutes';
import coordinatorRoutes from './routes/coordinatorRoutes';
import coordinatorPortalRoutes from './routes/coordinatorPortalRoutes';
import aiRoutes from './routes/aiRoutes';
import activityRoutes from './routes/activityRoutes';
import hodRoutes from './routes/hodRoutes';
import commonFeedRoutes from './routes/commonFeedRoutes';

import { startReminderScheduler } from './services/reminderScheduler';
import chatRoutes from './routes/chatRoutes';
import notificationRoutes from './routes/notificationRoutes';
import { isMaintenanceMode } from './controllers/systemConfigController';

import { errorHandler } from './middlewares/errorMiddleware';

const app: Application = express();

// 1. Middlewares
app.use(cors()); // Allows frontend to talk to backend
app.use(express.json()); // Allows server to read JSON data in requests
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

// 2. Routes Integration
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/universities', universityRoutes);
app.use('/api/companies', companyRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/placements', placementRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/feed', feedRoutes);
app.use('/api/supervisor', supervisorRoutes);
app.use('/api/coordinator', coordinatorRoutes);
app.use('/api/coordinator-portal', coordinatorPortalRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/activity', activityRoutes);
app.use('/api/hod', hodRoutes);
app.use('/api/common-feed', commonFeedRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/notifications', notificationRoutes);
// 3. Basic Health Check Route
app.get('/', (req: Request, res: Response) => {
    res.send('InternLink Backend API is Running...');
});

// Public: maintenance status (no auth required — frontend checks this)
app.get('/api/maintenance-status', async (_req: Request, res: Response) => {
    try {
        const status = await isMaintenanceMode();
        res.json(status);
    } catch {
        res.json({ active: false, message: '' });
    }
});

// Public: registration open/closed status per role
app.get('/api/registration-status', async (_req: Request, res: Response) => {
    try {
        const maintenance = await isMaintenanceMode();
        if (maintenance.active) {
            return res.json({
                student: false, coordinator: false, hod: false, supervisor: false,
                maintenanceMessage: maintenance.message,
            });
        }
        const { isRegistrationOpen } = await import('./controllers/systemConfigController');
        const [student, coordinator, hod, supervisor] = await Promise.all([
            isRegistrationOpen('STUDENT'),
            isRegistrationOpen('COORDINATOR'),
            isRegistrationOpen('HOD'),
            isRegistrationOpen('SUPERVISOR'),
        ]);
        res.json({ student, coordinator, hod, supervisor });
    } catch {
        res.json({ student: true, coordinator: true, hod: true, supervisor: true });
    }
});

// 4. Error Handler (Must be last)
app.use(errorHandler);

// 5. Start Server
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(` Server is running on http://localhost:${PORT}`);
    startReminderScheduler();
});

// Trigger reload again
