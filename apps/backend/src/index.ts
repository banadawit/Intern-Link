// src/index.ts
import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/authRoutes';

import adminRoutes from './routes/adminRoutes';
import companyRoutes from './routes/companyRoutes';
import universityRoutes from './routes/universityRoutes';
import studentRoutes from './routes/studentRoutes';
import placementRoutes from './routes/placementRoutes';
import progressRoutes from './routes/progressRoutes';
import reportRoutes from './routes/reportRoutes';
import feedRoutes from './routes/feedRoutes';

// 1. Load Environment Variables
dotenv.config();

const app: Application = express();

// 2. Middlewares
app.use(cors()); // Allows frontend to talk to backend
app.use(express.json()); // Allows server to read JSON data in requests

// 3. Routes Integration
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/universities', universityRoutes);
app.use('/api/companies', companyRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/placements', placementRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/feed', feedRoutes);
// 4. Basic Health Check Route
app.get('/', (req: Request, res: Response) => {
    res.send('InternLink Backend API is Running...');
});

// 5. Start Server
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(` Server is running on http://localhost:${PORT}`);
});