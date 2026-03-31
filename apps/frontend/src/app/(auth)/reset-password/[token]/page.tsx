'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { 
  Lock, 
  Eye, 
  EyeOff, 
  Loader2, 
  CheckCircle2, 
  ShieldCheck,
  AlertCircle,
  XCircle,
  Check,
  Key,
  Clock,
  Shield
} from 'lucide-react';

import { useAuth } from '@/lib/hooks/useAuth';

// Types
type PasswordStatus = 'idle' | 'validating' | 'valid' | 'invalid' | 'expired';
type StrengthLevel = 0 | 1 | 2 | 3 | 4;

interface PasswordRequirements {
  length: boolean;
  uppercase: boolean;
  lowercase: boolean;
  number: boolean;
  special: boolean;
}

const ResetPasswordPage = () => {
  const params = useParams();
  const router = useRouter();
  const { resetPassword } = useAuth();
  const token = params?.token as string;
  
  const [tokenStatus, setTokenStatus] = useState<PasswordStatus>('validating');
  const [tokenError, setTokenError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [touched, setTouched] = useState({ password: false, confirm: false });
  
  const [formData, setFormData] = useState({
    password: '',
    confirmPassword: '',
  });

  // Validate token on mount — just check it exists and has valid length
  // Real validation happens when submitting (backend will reject invalid/expired tokens)
  useEffect(() => {
    if (!token) {
      setTokenStatus('invalid');
      setTokenError('No reset token provided');
      return;
    }
    // Token exists, allow the form to show
    setTokenStatus('valid');
  }, [token]);

  // Password strength calculation
  const calculateStrength = useCallback((password: string): StrengthLevel => {
    let score = 0;
    if (password.length >= 8) score++;
    if (password.match(/[A-Z]/)) score++;
    if (password.match(/[a-z]/)) score++;
    if (password.match(/[0-9]/)) score++;
    if (password.match(/[^A-Za-z0-9]/)) score++;
    return score as StrengthLevel;
  }, []);

  // Check password requirements
  const checkRequirements = useCallback((password: string): PasswordRequirements => {
    return {
      length: password.length >= 8,
      uppercase: /[A-Z]/.test(password),
      lowercase: /[a-z]/.test(password),
      number: /[0-9]/.test(password),
      special: /[^A-Za-z0-9]/.test(password),
    };
  }, []);

  const strength = calculateStrength(formData.password);
  const requirements = checkRequirements(formData.password);
  const allRequirementsMet = Object.values(requirements).every(Boolean);
  
  const strengthConfig = {
    0: { label: 'Very Weak', color: 'bg-red-500', textColor: 'text-red-500', message: 'Enter a password' },
    1: { label: 'Weak', color: 'bg-orange-500', textColor: 'text-orange-500', message: 'Too short' },
    2: { label: 'Fair', color: 'bg-yellow-500', textColor: 'text-yellow-500', message: 'Could be stronger' },
    3: { label: 'Good', color: 'bg-primary-500', textColor: 'text-primary-500', message: 'Almost there' },
    4: { label: 'Strong', color: 'bg-emerald-500', textColor: 'text-emerald-500', message: 'Excellent!' },
  };

  const passwordsMatch = formData.password === formData.confirmPassword;
  const isFormValid = tokenStatus === 'valid' && allRequirementsMet && passwordsMatch && formData.password.length > 0;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isFormValid) return;

    setIsLoading(true);

    try {
      await resetPassword(token, formData.password);
      setIsSuccess(true);
      setTimeout(() => router.push('/login?reset=success'), 3000);
    } catch (err: any) {
      const message = err?.message || '';
      if (message.toLowerCase().includes('expired')) {
        setTokenStatus('expired');
      } else {
        setTokenStatus('invalid');
      }
      setTokenError(message || 'Failed to reset password. Please request a new link.');
    } finally {
      setIsLoading(false);
    }
  };

  // Token validation loading state
  if (tokenStatus === 'validating') {
    return (
      <div className="space-y-8 animate-fade-in text-center lg:text-left">
        <div className="flex flex-col items-center lg:items-start">
          <div className="h-16 w-16 rounded-2xl bg-primary-50 flex items-center justify-center mb-6">
            <Loader2 className="h-8 w-8 text-primary-600 animate-spin" />
          </div>
          <h1 className="text-3xl font-bold text-slate-900">Validating reset link</h1>
          <p className="mt-2 text-sm text-slate-500">
            Please wait while we verify your password reset request...
          </p>
        </div>
        
        <div className="bg-slate-50 border border-slate-100 rounded-2xl p-6">
          <div className="flex items-center justify-center gap-3">
            <Key className="h-5 w-5 text-primary-600 animate-pulse" />
            <span className="text-sm text-slate-600">Checking security token...</span>
          </div>
        </div>
      </div>
    );
  }

  // Invalid or expired token state
  if (tokenStatus === 'invalid' || tokenStatus === 'expired') {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="text-center lg:text-left">
          <div className="h-16 w-16 rounded-2xl bg-red-50 flex items-center justify-center mb-6 mx-auto lg:mx-0">
            {tokenStatus === 'expired' ? (
              <Clock className="h-8 w-8 text-red-600" />
            ) : (
              <XCircle className="h-8 w-8 text-red-600" />
            )}
          </div>
          <h1 className="text-3xl font-bold text-slate-900">
            {tokenStatus === 'expired' ? 'Reset link expired' : 'Invalid reset link'}
          </h1>
          <p className="mt-2 text-sm text-slate-500">
            {tokenStatus === 'expired' 
              ? 'This password reset link has expired. Please request a new one.'
              : 'The password reset link you used is invalid or has already been used.'}
          </p>
        </div>

        <div className="bg-red-50 border border-red-100 rounded-2xl p-6 space-y-3">
          <div className="flex items-start gap-3 text-red-700">
            <AlertCircle className="h-5 w-5 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-medium">What happened?</p>
              <p className="text-xs text-red-600 mt-1">{tokenError || 'Reset links expire after 1 hour for security reasons.'}</p>
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <Link
            href="/forgot-password"
            className="w-full flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-4 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700"
          >
            Request New Reset Link
          </Link>
          <Link
            href="/login"
            className="flex items-center justify-center gap-2 text-sm font-medium text-slate-500 hover:text-primary-600 transition-colors"
          >
            <Shield className="h-4 w-4" />
            Back to Login
          </Link>
        </div>
      </div>
    );
  }

  // Success state
  if (isSuccess) {
    return (
      <div className="space-y-8 animate-fade-in text-center lg:text-left">
        <div className="flex flex-col items-center lg:items-start">
          <div className="h-16 w-16 rounded-2xl bg-emerald-50 flex items-center justify-center mb-6">
            <CheckCircle2 className="h-8 w-8 text-emerald-600 animate-bounce" />
          </div>
          <h1 className="text-3xl font-bold text-slate-900">Password Reset Successfully!</h1>
          <p className="mt-2 text-sm text-slate-500">
            Your password has been updated. Redirecting you to login...
          </p>
        </div>

        <div className="bg-emerald-50 border border-emerald-100 rounded-2xl p-6 space-y-4">
          <div className="flex items-center gap-3 text-emerald-700">
            <ShieldCheck className="h-5 w-5 flex-shrink-0" />
            <p className="text-sm font-medium">Your account is now more secure</p>
          </div>
          <div className="flex items-center gap-3 text-emerald-600">
            <Check className="h-5 w-5 flex-shrink-0" />
            <p className="text-sm">You can now log in with your new password</p>
          </div>
        </div>

        <div className="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
          <div 
            className="h-full bg-emerald-500 rounded-full animate-progress-fast" 
            style={{ width: '100%', animation: 'progress 3s linear forwards' }}
          />
        </div>

        <Link
          href="/login"
          className="flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-4 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700"
        >
          Go to Login
        </Link>
      </div>
    );
  }

  // Main form (token is valid)
  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="text-center lg:text-left">
        <div className="h-12 w-12 rounded-xl bg-primary-50 flex items-center justify-center mb-4 mx-auto lg:mx-0">
          <Key className="h-6 w-6 text-primary-600" />
        </div>
        <h1 className="text-3xl font-bold tracking-tight text-slate-900">Set New Password</h1>
        <p className="mt-2 text-sm text-slate-500">
          Create a strong password for your account
        </p>
      </div>

      {/* Security Notice */}
      <div className="bg-slate-50 border border-slate-100 rounded-xl p-3">
        <div className="flex items-center gap-2 text-xs text-slate-500">
          <Shield className="h-3.5 w-3.5 flex-shrink-0" />
          <span>This link is valid for one-time use only</span>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* New Password Field */}
        <div className="space-y-3">
          <label className="text-sm font-semibold text-slate-700">
            New Password
          </label>
          <div className="relative group">
            <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-primary-500 transition-colors" />
            <input
              type={showPassword ? 'text' : 'password'}
              required
              className="w-full pl-10 pr-12 py-3 rounded-xl border border-slate-200 bg-white text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 transition-all"
              placeholder="Enter your new password"
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
              onBlur={() => setTouched(prev => ({ ...prev, password: true }))}
              disabled={isLoading}
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors"
              aria-label={showPassword ? 'Hide password' : 'Show password'}
            >
              {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
            </button>
          </div>

          {/* Password Requirements Checklist */}
          {touched.password && formData.password && (
            <div className="mt-3 p-3 bg-slate-50 rounded-xl border border-slate-100">
              <p className="text-xs font-semibold text-slate-600 mb-2">Password requirements:</p>
              <div className="grid grid-cols-2 gap-2">
                {Object.entries(requirements).map(([key, met]) => (
                  <div key={key} className="flex items-center gap-2">
                    {met ? (
                      <Check className="h-3 w-3 text-emerald-500" />
                    ) : (
                      <XCircle className="h-3 w-3 text-slate-300" />
                    )}
                    <span className={`text-xs ${met ? 'text-slate-600' : 'text-slate-400'}`}>
                      {key === 'length' && 'At least 8 characters'}
                      {key === 'uppercase' && 'Uppercase letter (A-Z)'}
                      {key === 'lowercase' && 'Lowercase letter (a-z)'}
                      {key === 'number' && 'Number (0-9)'}
                      {key === 'special' && 'Special character (!@#$%)'}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Password Strength Meter */}
        {formData.password && (
          <div className="space-y-2">
            <div className="flex justify-between items-center">
              <span className="text-xs font-semibold text-slate-600">Password Strength</span>
              <span className={`text-xs font-bold ${strengthConfig[strength].textColor}`}>
                {strengthConfig[strength].label}
              </span>
            </div>
            <div className="h-2 w-full bg-slate-100 rounded-full overflow-hidden">
              <div 
                className={`h-full rounded-full transition-all duration-500 ${strengthConfig[strength].color}`}
                style={{ width: `${(strength / 4) * 100}%` }}
              />
            </div>
            <p className={`text-xs ${strengthConfig[strength].textColor}`}>
              {strengthConfig[strength].message}
            </p>
          </div>
        )}

        {/* Confirm Password Field */}
        <div className="space-y-2">
          <label className="text-sm font-semibold text-slate-700">
            Confirm Password
          </label>
          <div className="relative group">
            <ShieldCheck className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-primary-500 transition-colors" />
            <input
              type={showConfirmPassword ? 'text' : 'password'}
              required
              className={`w-full pl-10 pr-12 py-3 rounded-xl border bg-white text-slate-900 placeholder:text-slate-400 transition-all
                focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500
                ${touched.confirm && !passwordsMatch && formData.confirmPassword
                  ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20'
                  : 'border-slate-200 hover:border-slate-300'
                }`}
              placeholder="Confirm your new password"
              value={formData.confirmPassword}
              onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
              onBlur={() => setTouched(prev => ({ ...prev, confirm: true }))}
              disabled={isLoading}
            />
            <button
              type="button"
              onClick={() => setShowConfirmPassword(!showConfirmPassword)}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors"
              aria-label={showConfirmPassword ? 'Hide password' : 'Show password'}
            >
              {showConfirmPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
            </button>
          </div>
          
          {touched.confirm && formData.confirmPassword && !passwordsMatch && (
            <p className="text-xs text-red-600 flex items-center gap-1 mt-1 animate-slide-down">
              <AlertCircle className="h-3 w-3" />
              Passwords do not match
            </p>
          )}
          
          {touched.confirm && passwordsMatch && formData.confirmPassword && (
            <p className="text-xs text-emerald-600 flex items-center gap-1 mt-1 animate-slide-down">
              <Check className="h-3 w-3" />
              Passwords match
            </p>
          )}
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          disabled={isLoading || !isFormValid}
          className="w-full flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-4 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isLoading ? (
            <>
              <Loader2 className="h-4 w-4 animate-spin" />
              Updating password...
            </>
          ) : (
            <>
              <Key className="h-4 w-4" />
              Reset Password
            </>
          )}
        </button>
      </form>

      {/* Footer */}
      <div className="text-center">
        <Link 
          href="/login" 
          className="inline-flex items-center gap-2 text-sm font-semibold text-slate-500 hover:text-primary-600 transition-colors"
        >
          <Shield className="h-4 w-4" />
          Back to Login
        </Link>
      </div>

      {/* Add animation keyframes to globals.css */}
      <style jsx>{`
        @keyframes progress {
          0% { width: 100%; }
          100% { width: 0%; }
        }
        .animate-progress-fast {
          animation: progress 3s linear forwards;
        }
      `}</style>
    </div>
  );
};

export default ResetPasswordPage;