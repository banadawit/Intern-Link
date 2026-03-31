// lib/api/client.ts
import axios from 'axios';

/** Ensures requests hit /api/auth/... even if NEXT_PUBLIC_API_URL omits /api (common misconfiguration). */
function normalizeApiBase(): string {
  const raw = (process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000').trim().replace(/\/+$/, '');
  return raw.endsWith('/api') ? raw : `${raw}/api`;
}

const api = axios.create({
  baseURL: normalizeApiBase(),
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000,
});

function isPublicAuthPath(url: string | undefined): boolean {
  if (!url) return false;
  return (
    url.includes('/auth/login') ||
    url.includes('/auth/register') ||
    url.includes('/auth/forgot-password') ||
    url.includes('/auth/reset-password') ||
    url.includes('/auth/verify-email') ||
    url.includes('/auth/resend-verification')
  );
}

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token && !isPublicAuthPath(config.url)) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    // ✅ Don't set Content-Type for FormData (browser sets it with boundary)
    if (config.data instanceof FormData) {
      delete config.headers['Content-Type'];
    }
    
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      const url = String(error.config?.url ?? '');
      // Failed login/register should not trigger global session teardown or redirect
      if (isPublicAuthPath(url)) {
        return Promise.reject(error);
      }
      localStorage.removeItem('token');
      localStorage.removeItem('auth-storage');

      if (typeof window !== 'undefined' && !window.location.pathname.includes('/login')) {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export default api;