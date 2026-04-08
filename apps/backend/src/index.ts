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
import aiRoutes from './routes/aiRoutes';
import activityRoutes from './routes/activityRoutes';
import coordinatorPortalRoutes from './routes/coordinatorRoutes';
import hodRoutes from './routes/hodRoutes';
import commonFeedRoutes from './routes/commonFeedRoutes';

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
app.use('/api/ai', aiRoutes);
app.use('/api/activity', activityRoutes);
app.use('/api/coordinator-portal', coordinatorPortalRoutes);
app.use('/api/hod', hodRoutes);
app.use('/api/common-feed', commonFeedRoutes);
// 3. Basic Health Check Route
app.get('/', (req: Request, res: Response) => {
    res.send('InternLink Backend API is Running...');
});

// 4. Start Server
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(` Server is running on http://localhost:${PORT}`);
});

// Trigger reload again
