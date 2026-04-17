'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Eye, EyeOff, Mail, Lock, Loader2, AlertCircle, CheckCircle2 } from 'lucide-react';
import { useAuth } from '@/lib/hooks/useAuth';
import type { AxiosError } from 'axios';

interface FormErrors {
  email?: string;
  password?: string;
  general?: string;
}

const LoginPage = () => {
  const router = useRouter();
  const { login } = useAuth();
  
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({ email: '', password: '' });
  const [errors, setErrors] = useState<FormErrors>({});
  const [touched, setTouched] = useState({ email: false, password: false });
  const [rememberMe, setRememberMe] = useState(false);
  const [successMessage, setSuccessMessage] = useState('');

  // Validation functions
  const validateEmail = (email: string) => {
    const emailRegex = /^[^\s@]+@([^\s@]+\.)+[^\s@]+$/;
    if (!email) return 'Email is required';
    if (!emailRegex.test(email)) return 'Please enter a valid email address';
    return '';
  };

  const validatePassword = (password: string) => {
    if (!password) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    return '';
  };

  // Real-time validation
  useEffect(() => {
    if (touched.email) {
      setErrors(prev => ({ ...prev, email: validateEmail(formData.email) }));
    }
  }, [formData.email, touched.email]);

  useEffect(() => {
    if (touched.password) {
      setErrors(prev => ({ ...prev, password: validatePassword(formData.password) }));
    }
  }, [formData.password, touched.password]);

  // Clear auth error when user types
  useEffect(() => {
    if (errors.general) {
      setErrors(prev => ({ ...prev, general: '' }));
    }
  }, [formData]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { id, value } = e.target;
    setFormData(prev => ({ ...prev, [id]: value }));
  };

  const handleBlur = (field: string) => {
    setTouched(prev => ({ ...prev, [field]: true }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Mark all fields as touched
    setTouched({ email: true, password: true });
    
    // Validate all fields
    const emailError = validateEmail(formData.email);
    const passwordError = validatePassword(formData.password);
    
    if (emailError || passwordError) {
      setErrors({
        email: emailError,
        password: passwordError,
      });
      return;
    }
    
    setIsLoading(true);
    setErrors({});
    setSuccessMessage('');

    try {
      await login(formData.email.trim(), formData.password, rememberMe);
      setSuccessMessage('Login successful! Redirecting...');

      const { user: loggedInUser } = useAuth.getState();
      const role = loggedInUser?.role;
      const institutionApproval = loggedInUser?.institutionAccessApproval;

      // Pending coordinator/HOD/supervisor — send to verification-pending instead of dashboard
      if (
        (role === 'COORDINATOR' || role === 'HOD' || role === 'SUPERVISOR') &&
        institutionApproval !== 'APPROVED'
      ) {
        const msg = encodeURIComponent(
          role === 'COORDINATOR'
            ? 'Your coordinator account is pending administrator approval. You will receive an email once approved.'
            : role === 'HOD'
            ? 'Your Head of Department account is pending coordinator approval. You will receive an email once approved.'
            : 'Your account is pending institutional approval.'
        );
        router.push(`/verification-pending?message=${msg}`);
        return;
      }

      const dest =
        role === 'ADMIN'
          ? '/admin'
          : role === 'SUPERVISOR'
            ? '/supervisor'
            : role === 'COORDINATOR'
              ? '/coordinator'
              : role === 'HOD'
                ? '/hod'
              : '/student';

      router.push(dest);
    } catch (err) {
      const ax = err as AxiosError<{
        message?: string;
        error?: string;
        requiresVerification?: boolean;
        email?: string;
        code?: string;
      }>;
      const data = ax.response?.data;
      const serverMsg =
        data?.message ||
        (typeof data?.error === 'string' ? data.error : undefined);

      if (data?.requiresVerification) {
        setErrors({
          general: serverMsg || 'Please verify your email before logging in. Check your inbox for the verification link.',
        });
        return;
      }

      if (
        data?.code === 'PENDING_ADMIN_REVIEW' ||
        data?.code === 'PENDING_COORDINATOR_REVIEW' ||
        data?.code === 'PENDING_HOD_REVIEW' ||
        data?.code === 'INSTITUTION_NOT_APPROVED' ||
        data?.code === 'INSTITUTION_MEMBER_NOT_APPROVED'
      ) {
        const pendingMessage = encodeURIComponent(
          serverMsg || 'Your account is waiting for institutional approval.'
        );
        router.push(`/verification-pending?message=${pendingMessage}`);
        return;
      }

      setErrors({
        general:
          serverMsg ||
          useAuth.getState().error ||
          'Invalid email or password. Please try again.',
      });
    } finally {
      setIsLoading(false);
    }
  };

  // Handle demo login for different roles (development only)
  const handleDemoLogin = (role: string) => {
    const demoCredentials = {
      // Must match `apps/backend/prisma/seed.ts` — run `npx prisma db seed` from `apps/backend` if any account is missing
      Admin: { email: 'admin@internlink.com', password: 'Admin@1234' },
      Coordinator: { email: 'coordinator@haramaya.edu', password: 'Coord123!' },
      HOD: { email: 'hod@haramaya.edu', password: 'Hod12345' },
      Supervisor: { email: 'supervisor@company.com', password: 'Super123!' },
      Student: { email: 'student@haramaya.edu', password: 'Student123!' },
    };
    
    const creds = demoCredentials[role as keyof typeof demoCredentials];
    if (creds) {
      setFormData({ email: creds.email, password: creds.password });
      setTouched({ email: true, password: true });
      setErrors({});
    }
  };

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header Section */}
      <div className="text-center lg:text-left">
        <h1 className="text-3xl md:text-4xl font-bold tracking-tight text-slate-900">
          Welcome Back
        </h1>
        <p className="mt-2 text-sm text-slate-500">
          Please enter your credentials to access your dashboard
        </p>
      </div>

      {/* Success Message */}
      {successMessage && (
        <div className="flex items-center gap-3 rounded-xl bg-emerald-50 p-4 text-emerald-700 border border-emerald-200 animate-slide-down">
          <CheckCircle2 className="h-5 w-5 flex-shrink-0" />
          <p className="text-sm font-medium">{successMessage}</p>
        </div>
      )}

      {/* General Error Message */}
      {errors.general && (
        <div className="flex items-center gap-3 rounded-xl bg-red-50 p-4 text-red-700 border border-red-200 animate-slide-down">
          <AlertCircle className="h-5 w-5 flex-shrink-0" />
          <p className="text-sm font-medium">{errors.general}</p>
        </div>
      )}

      {/* Login Form */}
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Email Field */}
        <div className="space-y-2">
          <label 
            htmlFor="email" 
            className="text-sm font-semibold text-slate-700"
          >
            Email Address
          </label>
          <div className="relative group">
            <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-primary-500 transition-colors" />
            <input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              required
              placeholder="name@university.edu.et"
              className={`w-full pl-10 pr-4 py-3 rounded-xl border bg-white text-slate-900 placeholder:text-slate-400 transition-all duration-200
                focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500
                ${errors.email && touched.email
                  ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20'
                  : 'border-slate-200 hover:border-slate-300'
                }`}
              value={formData.email}
              onChange={handleInputChange}
              onBlur={() => handleBlur('email')}
              disabled={isLoading}
              aria-invalid={!!errors.email && touched.email}
              aria-describedby={errors.email ? 'email-error' : undefined}
            />
          </div>
          {errors.email && touched.email && (
            <p id="email-error" className="text-xs text-red-600 flex items-center gap-1 mt-1">
              <AlertCircle className="h-3 w-3" />
              {errors.email}
            </p>
          )}
        </div>

        {/* Password Field */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <label 
              htmlFor="password" 
              className="text-sm font-semibold text-slate-700"
            >
              Password
            </label>
            <Link 
              href="/forgot-password" 
              className="text-xs font-medium text-primary-600 hover:text-primary-700 transition-colors"
            >
              Forgot password?
            </Link>
          </div>
          <div className="relative group">
            <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-primary-500 transition-colors" />
            <input
              id="password"
              name="password"
              type={showPassword ? 'text' : 'password'}
              autoComplete="current-password"
              required
              placeholder="••••••••"
              className={`w-full pl-10 pr-12 py-3 rounded-xl border bg-white text-slate-900 placeholder:text-slate-400 transition-all duration-200
                focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500
                ${errors.password && touched.password
                  ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20'
                  : 'border-slate-200 hover:border-slate-300'
                }`}
              value={formData.password}
              onChange={handleInputChange}
              onBlur={() => handleBlur('password')}
              disabled={isLoading}
              aria-invalid={!!errors.password && touched.password}
              aria-describedby={errors.password ? 'password-error' : undefined}
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors focus:outline-none focus:ring-2 focus:ring-primary-500 rounded-lg p-1"
              aria-label={showPassword ? 'Hide password' : 'Show password'}
            >
              {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
            </button>
          </div>
          {errors.password && touched.password && (
            <p id="password-error" className="text-xs text-red-600 flex items-center gap-1 mt-1">
              <AlertCircle className="h-3 w-3" />
              {errors.password}
            </p>
          )}
        </div>

        {/* Remember Me & Demo (Demo for development only) */}
        <div className="flex items-center justify-between">
          <label className="flex items-center gap-2 cursor-pointer group">
            <input
              type="checkbox"
              checked={rememberMe}
              onChange={(e) => setRememberMe(e.target.checked)}
              className="h-4 w-4 rounded border-slate-300 text-primary-600 focus:ring-primary-500 focus:ring-offset-0 cursor-pointer"
              disabled={isLoading}
            />
            <span className="text-sm text-slate-500 group-hover:text-slate-700 transition-colors">
              Remember me
            </span>
          </label>
          
          {/* Demo Login - Remove in production */}
          {process.env.NODE_ENV === 'development' && (
            <div className="relative group">
              <button
                type="button"
                className="text-xs text-slate-400 hover:text-primary-600 transition-colors"
                aria-label="Demo login options"
              >
                Demo Login
              </button>
              <div className="absolute right-0 top-full mt-2 w-48 bg-white rounded-lg shadow-lg border border-slate-200 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all z-10">
                <div className="py-2">
                  <button
                    type="button"
                    onClick={() => handleDemoLogin('Student')}
                    className="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 transition-colors"
                  >
                    🎓 Login as Student
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDemoLogin('Coordinator')}
                    className="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 transition-colors"
                  >
                    🏛️ Login as Coordinator
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDemoLogin('HOD')}
                    className="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 transition-colors"
                  >
                    📚 Login as HOD
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDemoLogin('Supervisor')}
                    className="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 transition-colors"
                  >
                    💼 Login as Supervisor
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDemoLogin('Admin')}
                    className="w-full text-left px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 transition-colors"
                  >
                    ⚙️ Login as Admin
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          disabled={isLoading || !!successMessage}
          className="w-full flex items-center justify-center rounded-xl bg-primary-600 py-3.5 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all duration-200 hover:bg-primary-700 hover:shadow-xl hover:shadow-primary-600/30 active:bg-primary-800 disabled:opacity-70 disabled:cursor-not-allowed disabled:hover:shadow-lg"
        >
          {isLoading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Verifying credentials...
            </>
          ) : (
            'Sign In to InternLink'
          )}
        </button>
      </form>

      {/* Footer Note */}
      <div className="pt-4 text-center">
        <p className="text-sm text-slate-500">
          Don&apos;t have an account?{' '}
          <Link 
            href="/register" 
            className="font-semibold text-primary-600 hover:text-primary-700 transition-colors underline underline-offset-4"
          >
            Create an account
          </Link>
        </p>
      </div>

      {/* Help Text */}
      <div className="text-center">
        <p className="text-xs text-slate-400">
          By signing in, you agree to our{' '}
          <Link href="/terms" className="hover:text-primary-600 transition-colors">
            Terms of Service
          </Link>{' '}
          and{' '}
          <Link href="/privacy" className="hover:text-primary-600 transition-colors">
            Privacy Policy
          </Link>
        </p>
      </div>
    </div>
  );
};

export default LoginPage;