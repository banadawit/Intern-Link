// lib/hooks/useAuth.ts
'use client';

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import api from '../api/client';
import { AxiosError } from 'axios';

interface User {
  id: number;
  email: string;
  fullName: string;
  role: 'ADMIN' | 'COORDINATOR' | 'HOD' | 'SUPERVISOR' | 'STUDENT';
  isVerified: boolean;
  institutionAccessApproval?: string;
  hodApprovalStatus?: string;
  profile?: {
    universityId?: number;
    universityName?: string;
    companyId?: number;
    companyName?: string;
    studentId?: string;
  };
}

interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  error: string | null;
  _hydrated: boolean;
  
  // Actions
  login: (email: string, password: string, rememberMe?: boolean) => Promise<void>;
  logout: () => void;
  register: (data: RegisterData) => Promise<void>;
  verifyEmail: (token: string) => Promise<void>;
  resendVerification: (email: string) => Promise<void>;
  forgotPassword: (email: string) => Promise<void>;
  resetPassword: (token: string, password: string) => Promise<void>;
  clearError: () => void;
}

type RegistrationRole = 'student' | 'coordinator' | 'hod' | 'supervisor';

interface RegisterData {
  email: string;
  password: string;
  fullName: string;
  role: RegistrationRole;
  // Role-specific fields
  universityName?: string;
  universityId?: number;
  hodId?: number;
  companyName?: string;
  department?: string;
  studentId?: string;
  employeeId?: string;
  position?: string;
  verificationDocument?: string;
}

// API Response Types
interface LoginResponse {
  success: boolean;
  data: {
    token: string;
    user: {
      id: number;
      email: string;
      fullName: string;
      role: 'ADMIN' | 'COORDINATOR' | 'HOD' | 'SUPERVISOR' | 'STUDENT';
      isVerified: boolean;
      institutionAccessApproval?: string;
      hodApprovalStatus?: string;
    };
  };
}

interface ApiErrorResponse {
  success: boolean;
  message: string;
  requiresVerification?: boolean;
  email?: string;
}

// Error type for API calls
type ApiError = AxiosError<ApiErrorResponse>;

// Zustand store with persistence
export const useAuth = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isLoading: false,
      error: null,
      _hydrated: false,

      // ============================================
      // LOGIN - Real API Call
      // ============================================
      login: async (email, password, rememberMe = false) => {
        set({ isLoading: true, error: null });
        
        try {
          const response = await api.post<LoginResponse>('/auth/login', { email, password });
          
          const { token, user } = response.data.data;
          
          set({
            user: {
              id: user.id,
              email: user.email,
              fullName: user.fullName,
              role: user.role,
              isVerified: user.isVerified,
              institutionAccessApproval: user.institutionAccessApproval,
              hodApprovalStatus: user.hodApprovalStatus,
            },
            token,
            isLoading: false,
          });

          // Always store token so api/client.ts interceptor can use it
          localStorage.setItem('token', token);

          // If not rememberMe, clear on tab close
          if (!rememberMe) {
            sessionStorage.setItem('token', token);
          }
          
        } catch (err) {
          const error = err as ApiError;
          const d = error.response?.data as { message?: string; error?: string } | undefined;
          const errorMessage =
            d?.message || d?.error || 'Invalid email or password. Please try again.';
          set({ error: errorMessage, isLoading: false });
          throw err;
        }
      },

      // ============================================
      // LOGOUT
      // ============================================
      logout: () => {
        set({ user: null, token: null });
        localStorage.removeItem('token');
        localStorage.removeItem('auth-storage');
      },

  // ============================================
  // REGISTER - Real API Call (JSON with Cloudinary URL)
  // ============================================
  register: async (data: RegisterData) => {
    set({ isLoading: true, error: null });
    
    try {
      const payload = {
        full_name: data.fullName,
        email: data.email,
        password: data.password,
        role: data.role.toUpperCase(),
        verification_document: data.verificationDocument, // Now a string URL
        
        // Role-specific fields
        ...(data.role === 'coordinator' && {
          university_name: data.universityName,
          position: data.position,
        }),
        ...(data.role === 'hod' && {
          university_id: data.universityId,
          department: data.department,
          employee_id: data.employeeId,
        }),
        ...(data.role === 'supervisor' && {
          company_name: data.companyName,
          position: data.position,
        }),
        ...(data.role === 'student' && {
          university_id: data.universityId,
          hod_id: data.hodId,
          student_id: data.studentId,
        }),
      };

      await api.post('/auth/register', payload);
      
      set({ isLoading: false });
      
    } catch (err) {
          const error = err as ApiError;
          const errorMessage = error.response?.data?.message || 'Registration failed. Please try again.';
          set({ 
            error: errorMessage, 
            isLoading: false 
          });
          throw new Error(errorMessage);
        }
      },

      // ============================================
      // VERIFY EMAIL - Real API Call
      // ============================================
      verifyEmail: async (token: string) => {
        set({ isLoading: true, error: null });

        try {
          await api.post('/auth/verify-email', { token });
          set({ isLoading: false });
          
        } catch (err) {
          const error = err as ApiError;
          const errorMessage = error.response?.data?.message || 'Verification failed. The link may be invalid or expired.';
          set({
            error: errorMessage,
            isLoading: false
          });
          throw new Error(errorMessage);
        }
      },

      // ============================================
      // RESEND VERIFICATION EMAIL - Real API Call
      // ============================================
      resendVerification: async (email: string) => {
        set({ isLoading: true, error: null });

        try {
          await api.post('/auth/resend-verification', { email });
          set({ isLoading: false });
          
        } catch (err) {
          const error = err as ApiError;
          const errorMessage = error.response?.data?.message || 'Failed to resend verification email';
          set({
            error: errorMessage,
            isLoading: false
          });
          throw new Error(errorMessage);
        }
      },

      // ============================================
      // FORGOT PASSWORD - Real API Call
      // ============================================
      forgotPassword: async (email: string) => {
        set({ isLoading: true, error: null });
        
        try {
          await api.post('/auth/forgot-password', { email });
          set({ isLoading: false });
          
        } catch (err) {
          const error = err as ApiError;
          const errorMessage = error.response?.data?.message || 'Password reset request failed';
          set({
            error: errorMessage,
            isLoading: false,
          });
          throw new Error(errorMessage);
        }
      },

      // ============================================
      // RESET PASSWORD - Real API Call
      // ============================================
      resetPassword: async (token: string, password: string) => {
        set({ isLoading: true, error: null });
        
        try {
          await api.post('/auth/reset-password', { token, newPassword: password });
          set({ isLoading: false });
          
        } catch (err) {
          const error = err as ApiError;
          const errorMessage = error.response?.data?.message || 'Password reset failed';
          set({
            error: errorMessage,
            isLoading: false,
          });
          throw new Error(errorMessage);
        }
      },

      clearError: () => set({ error: null }),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({ user: state.user, token: state.token }),
      onRehydrateStorage: () => (_state, error) => {
        if (!error) {
          useAuth.setState({ _hydrated: true });
        }
      },
    }
  )
);

// Helper hooks
export const useIsAuthenticated = () => {
  const { user, token } = useAuth();
  return !!user && !!token;
};

export const useUserRole = () => {
  const { user } = useAuth();
  return user?.role;
};

export const useHasRole = (roles: string | string[]) => {
  const { user } = useAuth();
  const role = user?.role;
  
  if (!role) return false;
  
  const roleArray = Array.isArray(roles) ? roles : [roles];
  return roleArray.includes(role);
};