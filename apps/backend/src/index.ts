// src/index.ts
import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/authRoutes';

// 1. Load Environment Variables
dotenv.config();

const app: Application = express();

// 2. Middlewares
app.use(cors()); // Allows frontend to talk to backend
app.use(express.json()); // Allows server to read JSON data in requests

// 3. Routes Integration
app.use('/api/auth', authRoutes);

// 4. Basic Health Check Route
app.get('/', (req: Request, res: Response) => {
    res.send('InternLink Backend API is Running...');
});

// 5. Start Server
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(` Server is running on http://localhost:${PORT}`);
});