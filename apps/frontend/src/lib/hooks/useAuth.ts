// lib/hooks/useAuth.ts
'use client';

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import api from '../api/client';

interface User {
  id: string;
  email: string;
  fullName: string;
  role: 'SuperAdmin' | 'Coordinator' | 'Supervisor' | 'Student';
  isVerified: boolean;
  profile?: {
    universityId?: string;
    universityName?: string;
    companyId?: string;
    companyName?: string;
    studentId?: string;
  };
}

interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  error: string | null;
  
  // Actions
  login: (email: string, password: string, rememberMe?: boolean) => Promise<void>;
  logout: () => void;
  register: (data: RegisterData) => Promise<void>;
  verifyEmail: (token: string) => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  updatePassword: (token: string, password: string) => Promise<void>;
  clearError: () => void;
}

interface RegisterData {
  email: string;
  password: string;
  fullName: string;
  role: string;
  organizationDetails?: {
    universityId?: string;
    companyId?: string;
    universityName?: string;
    companyName?: string;
  };
  verificationDocument?: File;
}

// Zustand store with persistence
export const useAuth = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isLoading: false,
      error: null,

      login: async (email, password, rememberMe = false) => {
        set({ isLoading: true, error: null });
        
        try {
          // Mock API call - replace with real endpoint
          const response = await new Promise<{ user: User; token: string }>((resolve) => {
            setTimeout(() => {
              // Mock response based on email domain for testing
              let user: User;
              
              if (email.includes('admin')) {
                user = {
                  id: '1',
                  email,
                  fullName: 'System Admin',
                  role: 'SuperAdmin',
                  isVerified: true,
                };
              } else if (email.includes('coordinator') || email.includes('@haramaya.edu')) {
                user = {
                  id: '2',
                  email,
                  fullName: 'Dr. Abebe Kebede',
                  role: 'Coordinator',
                  isVerified: true,
                  profile: {
                    universityId: 'uni-1',
                    universityName: 'Haramaya University',
                  },
                };
              } else if (email.includes('supervisor') || email.includes('@company.com')) {
                user = {
                  id: '3',
                  email,
                  fullName: 'Tigist Bekele',
                  role: 'Supervisor',
                  isVerified: true,
                  profile: {
                    companyId: 'comp-1',
                    companyName: 'Ethio Telecom',
                  },
                };
              } else {
                user = {
                  id: '4',
                  email,
                  fullName: 'John Doe',
                  role: 'Student',
                  isVerified: true,
                  profile: {
                    universityId: 'uni-1',
                    universityName: 'Haramaya University',
                    studentId: 'STU-2024-001',
                  },
                };
              }
              
              resolve({
                user,
                token: 'mock-jwt-token-' + Date.now(),
              });
            }, 1500);
          });
          
          set({
            user: response.user,
            token: response.token,
            isLoading: false,
          });
          
          // Store token in localStorage for API calls
          if (rememberMe) {
            localStorage.setItem('token', response.token);
          }
          
        } catch (error) {
          set({
            error: error instanceof Error ? error.message : 'Login failed',
            isLoading: false,
          });
          throw error;
        }
      },

      logout: () => {
        set({ user: null, token: null });
        localStorage.removeItem('token');
        localStorage.removeItem('auth-storage'); // Clear persisted state
      },

      register: async (data) => {
        set({ isLoading: true, error: null });
        
        try {
          // Mock registration - replace with real API
          await new Promise((resolve) => setTimeout(resolve, 1500));
          
          // After registration, user needs to verify email
          set({ isLoading: false });
          
        } catch (error) {
          set({
            error: error instanceof Error ? error.message : 'Registration failed',
            isLoading: false,
          });
          throw error;
        }
      },

      verifyEmail: async (token) => {
        set({ isLoading: true, error: null });
        
        try {
          await new Promise((resolve) => setTimeout(resolve, 1000));
          set({ isLoading: false });
        } catch (error) {
          set({
            error: error instanceof Error ? error.message : 'Verification failed',
            isLoading: false,
          });
          throw error;
        }
      },

      resetPassword: async (email) => {
        set({ isLoading: true, error: null });
        
        try {
          await new Promise((resolve) => setTimeout(resolve, 1000));
          set({ isLoading: false });
        } catch (error) {
          set({
            error: error instanceof Error ? error.message : 'Password reset failed',
            isLoading: false,
          });
          throw error;
        }
      },

      updatePassword: async (token, password) => {
        set({ isLoading: true, error: null });
        
        try {
          await new Promise((resolve) => setTimeout(resolve, 1000));
          set({ isLoading: false });
        } catch (error) {
          set({
            error: error instanceof Error ? error.message : 'Password update failed',
            isLoading: false,
          });
          throw error;
        }
      },

      clearError: () => set({ error: null }),
    }),
    {
      name: 'auth-storage', // localStorage key
      partialize: (state) => ({ user: state.user, token: state.token }), // Only persist these
    }
  )
);

// Helper hook to check if user is authenticated
export const useIsAuthenticated = () => {
  const { user, token } = useAuth();
  return !!user && !!token;
};

// Helper hook to check user role
export const useUserRole = () => {
  const { user } = useAuth();
  return user?.role;
};

// Helper hook to check if user has specific role
export const useHasRole = (roles: string | string[]) => {
  const { user } = useAuth();
  const role = user?.role;
  
  if (!role) return false;
  
  const roleArray = Array.isArray(roles) ? roles : [roles];
  return roleArray.includes(role);
};