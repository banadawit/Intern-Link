'use client';

import React, { useState, useEffect, Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { 
  Mail, 
  ArrowLeft, 
  RefreshCcw, 
  CheckCircle2, 
  Loader2, 
  XCircle, 
  AlertCircle,
  PartyPopper,
  Clock,
  ShieldCheck
} from 'lucide-react';
import { useAuth } from '@/lib/hooks/useAuth';

type VerificationStatus = 'idle' | 'verifying' | 'success' | 'error' | 'expired';

// Separate component that uses useSearchParams
function VerifyEmailContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { verifyEmail, resendVerification } = useAuth();
  
  const token = searchParams.get('token');
  const emailParam = searchParams.get('email');
  const roleParam = searchParams.get('role'); // 'coordinator' triggers pending-review redirect
  
  const [status, setStatus] = useState<VerificationStatus>(token ? 'verifying' : 'idle');
  const [isResending, setIsResending] = useState(false);
  const [countdown, setCountdown] = useState(0);
  const [errorMessage, setErrorMessage] = useState('');
  const [resendEmail, setResendEmail] = useState(emailParam || '');
  const [resendSuccess, setResendSuccess] = useState(false);

  // Auto-verify when page loads with token
  useEffect(() => {
    if (token && status === 'verifying') {
      handleVerifyToken();
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);

  // Handle countdown for resend
  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [countdown]);

  const handleVerifyToken = async () => {
    if (!token) return;
    
    setErrorMessage('');
    
    try {
      await verifyEmail(token);
      setStatus('success');
      
      // Coordinators go to pending-review; everyone else goes to login
      setTimeout(() => {
        if (roleParam === 'coordinator') {
          router.push('/register/pending-review');
        } else {
          router.push('/login?verified=true');
        }
      }, 3000);
      
    } catch (error: unknown) {
      const err = error as Error;
      const message = err.message || 'Verification failed. The link may be invalid or expired.';
      setErrorMessage(message);
      
      // Check if it's an expired token error
      if (message.toLowerCase().includes('expired')) {
        setStatus('expired');
      } else {
        setStatus('error');
      }
    }
  };

  const handleResend = async () => {
    if (!resendEmail) {
      setErrorMessage('Please enter your email address');
      return;
    }
    
    setIsResending(true);
    setErrorMessage('');
    setResendSuccess(false);
    
    try {
      await resendVerification(resendEmail);
      setResendSuccess(true);
      setCountdown(60); // 60 second cooldown
      setStatus('idle');
    } catch (error: unknown) {
      const err = error as Error;
      setErrorMessage(err.message || 'Failed to resend verification email');
    } finally {
      setIsResending(false);
    }
  };

  // Loading state while verifying
  if (status === 'verifying') {
    return (
      <div className="space-y-8 animate-fade-in text-center lg:text-left">
        <div className="flex flex-col items-center lg:items-start">
          <div className="h-16 w-16 rounded-2xl bg-primary-50 flex items-center justify-center mb-6">
            <Loader2 className="h-8 w-8 text-primary-600 animate-spin" />
          </div>
          <h1 className="text-3xl font-bold text-slate-900">Verifying your email</h1>
          <p className="mt-2 text-sm text-slate-500">
            Please wait while we verify your email address...
          </p>
        </div>
        
        <div className="bg-slate-50 border border-slate-100 rounded-2xl p-6">
          <div className="flex items-center justify-center gap-3">
            <Loader2 className="h-5 w-5 text-primary-600 animate-spin" />
            <span className="text-sm text-slate-600">Verifying...</span>
          </div>
        </div>
      </div>
    );
  }

  if (status === 'success') {
    return (
      <div className="space-y-8 animate-fade-in text-center lg:text-left">
        <div className="flex flex-col items-center lg:items-start">
          <div className="h-16 w-16 rounded-2xl bg-emerald-50 flex items-center justify-center mb-6">
            <PartyPopper className="h-8 w-8 text-emerald-600" />
          </div>
          <h1 className="text-3xl font-bold text-slate-900">Email verified! 🎉</h1>
          <p className="mt-2 text-sm text-slate-500">
            {roleParam === 'coordinator'
              ? 'Your email is confirmed. Redirecting to your submission status...'
              : 'Your email has been successfully verified. Redirecting to login...'}
          </p>
        </div>

        <div className="bg-emerald-50 border border-emerald-100 rounded-2xl p-6 space-y-3">
          <div className="flex items-center gap-3 text-emerald-700">
            <CheckCircle2 className="h-5 w-5 flex-shrink-0" />
            <span className="text-sm font-medium">Email confirmed successfully</span>
          </div>
          {roleParam === 'coordinator' ? (
            <div className="flex items-center gap-3 text-emerald-600">
              <ShieldCheck className="h-5 w-5 flex-shrink-0" />
              <span className="text-sm">Your registration is now pending administrator review</span>
            </div>
          ) : (
            <div className="flex items-center gap-3 text-emerald-600">
              <ShieldCheck className="h-5 w-5 flex-shrink-0" />
              <span className="text-sm">You can now access all features of InternLink</span>
            </div>
          )}
        </div>

        <div className="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
          <div className="h-full bg-emerald-500 rounded-full animate-progress-fast" style={{ width: '100%' }} />
        </div>

        <Link
          href={roleParam === 'coordinator' ? '/register/pending-review' : '/login'}
          className="flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-3.5 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700"
        >
          {roleParam === 'coordinator' ? 'View submission status' : 'Continue to Login'}
          <ArrowLeft className="h-4 w-4 rotate-180" />
        </Link>
      </div>
    );
  }

  // Error state (invalid token)
  if (status === 'error') {
    return (
      <div className="space-y-8 animate-fade-in text-center lg:text-left">
        <div className="flex flex-col items-center lg:items-start">
          <div className="h-16 w-16 rounded-2xl bg-red-50 flex items-center justify-center mb-6">
            <XCircle className="h-8 w-8 text-red-600" />
          </div>
          <h1 className="text-3xl font-bold text-slate-900">Verification failed</h1>
          <p className="mt-2 text-sm text-slate-500">
            We couldn&apos;t verify your email address
          </p>
        </div>

        <div className="bg-red-50 border border-red-100 rounded-2xl p-6 space-y-3">
          <div className="flex items-start gap-3 text-red-700">
            <AlertCircle className="h-5 w-5 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-medium">Verification Error</p>
              <p className="text-xs text-red-600 mt-1">{errorMessage}</p>
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <div className="space-y-2">
            <label className="text-sm font-semibold text-slate-700">
              Email Address
            </label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
              <input
                type="email"
                value={resendEmail}
                onChange={(e) => setResendEmail(e.target.value)}
                placeholder="your@email.com"
                className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
              />
            </div>
          </div>

          <button
            onClick={handleResend}
            disabled={isResending || countdown > 0 || !resendEmail}
            className="w-full flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-3.5 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700 disabled:opacity-50"
          >
            {isResending ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCcw className="h-4 w-4" />
            )}
            {countdown > 0 ? `Resend in ${countdown}s` : 'Request new verification link'}
          </button>

          {resendSuccess && (
            <div className="flex items-center gap-2 text-emerald-600 text-sm justify-center">
              <CheckCircle2 className="h-4 w-4" />
              Verification email sent! Check your inbox.
            </div>
          )}

          <Link
            href="/login"
            className="flex items-center justify-center gap-2 text-sm font-semibold text-slate-500 hover:text-slate-800 transition-colors"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to Login
          </Link>
        </div>
      </div>
    );
  }

  // Expired token state
  if (status === 'expired') {
    return (
      <div className="space-y-8 animate-fade-in text-center lg:text-left">
        <div className="flex flex-col items-center lg:items-start">
          <div className="h-16 w-16 rounded-2xl bg-yellow-50 flex items-center justify-center mb-6">
            <Clock className="h-8 w-8 text-yellow-600" />
          </div>
          <h1 className="text-3xl font-bold text-slate-900">Verification link expired</h1>
          <p className="mt-2 text-sm text-slate-500">
            The verification link has expired. Request a new one below.
          </p>
        </div>

        <div className="bg-yellow-50 border border-yellow-100 rounded-2xl p-6">
          <p className="text-sm text-yellow-700">
            Verification links expire after 24 hours for security reasons.
          </p>
        </div>

        <div className="space-y-4">
          <div className="space-y-2">
            <label className="text-sm font-semibold text-slate-700">
              Email Address
            </label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
              <input
                type="email"
                value={resendEmail}
                onChange={(e) => setResendEmail(e.target.value)}
                placeholder="your@email.com"
                className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
              />
            </div>
          </div>

          <button
            onClick={handleResend}
            disabled={isResending || countdown > 0 || !resendEmail}
            className="w-full flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-3.5 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700 disabled:opacity-50"
          >
            {isResending ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCcw className="h-4 w-4" />
            )}
            {countdown > 0 ? `Resend in ${countdown}s` : 'Send new verification link'}
          </button>

          {resendSuccess && (
            <div className="flex items-center gap-2 text-emerald-600 text-sm justify-center">
              <CheckCircle2 className="h-4 w-4" />
              Verification email sent! Check your inbox.
            </div>
          )}

          <Link
            href="/login"
            className="flex items-center justify-center gap-2 text-sm font-semibold text-slate-500 hover:text-slate-800 transition-colors"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to Login
          </Link>
        </div>
      </div>
    );
  }

  // Default state (no token - just showing verification sent message)
  return (
    <div className="space-y-8 animate-fade-in text-center lg:text-left">
      {/* Icon & Heading */}
      <div className="flex flex-col items-center lg:items-start">
        <div className="h-16 w-16 rounded-2xl bg-primary-50 flex items-center justify-center mb-6 animate-pulse-slow">
          <Mail className="h-8 w-8 text-primary-600" />
        </div>
        <h1 className="text-3xl font-bold text-slate-900">Check your email</h1>
        <p className="mt-2 text-sm text-slate-500 max-w-sm">
          We&apos;ve sent a verification link to{' '}
          <span className="font-medium text-primary-600">
            {resendEmail || 'your email address'}
          </span>
          .{' '}
          {roleParam === 'coordinator'
            ? 'Please verify your email first, then your registration will be submitted for admin review.'
            : 'Please click the link to activate your account.'}
        </p>
      </div>

      {/* Verification Status Card */}
      <div className="bg-slate-50 border border-slate-100 rounded-2xl p-6 space-y-4">
        <div className="flex items-center gap-3 text-sm text-slate-600">
          <CheckCircle2 className="h-5 w-5 text-emerald-500 flex-shrink-0" />
          <span>Verification email sent</span>
        </div>
        <div className="flex items-center gap-3 text-sm text-slate-600">
          <div className="h-5 w-5 rounded-full border-2 border-slate-200 border-t-primary-600 animate-spin" />
          <span>Awaiting your confirmation...</span>
        </div>
        
        {/* Tip for users */}
        <div className="mt-4 pt-4 border-t border-slate-200">
          <p className="text-xs text-slate-500 flex items-start gap-2">
            <AlertCircle className="h-3 w-3 flex-shrink-0 mt-0.5" />
            Didn&apos;t receive the email? Check your spam folder or request a new link below.
          </p>
        </div>
      </div>

      {/* Email Input for Resend (if email not in URL) */}
      {!emailParam && (
        <div className="space-y-2">
          <label className="text-sm font-semibold text-slate-700">
            Didn&apos;t receive the email?
          </label>
          <div className="relative">
            <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
            <input
              type="email"
              value={resendEmail}
              onChange={(e) => setResendEmail(e.target.value)}
              placeholder="Enter your email to resend"
              className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
            />
          </div>
        </div>
      )}

      {/* Action Buttons */}
      <div className="space-y-4">
        <button
          onClick={handleResend}
          disabled={isResending || countdown > 0 || !resendEmail}
          className="w-full flex items-center justify-center gap-2 rounded-xl border-2 border-slate-200 bg-white py-4 text-sm font-bold text-slate-700 transition-all hover:border-primary-600 hover:text-primary-600 disabled:opacity-50 disabled:hover:border-slate-200 disabled:hover:text-slate-700"
        >
          {isResending ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <RefreshCcw className="h-4 w-4" />
          )}
          {countdown > 0 ? `Resend in ${countdown}s` : 'Resend verification email'}
        </button>

        {resendSuccess && (
          <div className="flex items-center gap-2 text-emerald-600 text-sm justify-center">
            <CheckCircle2 className="h-4 w-4" />
            Verification email sent! Check your inbox.
          </div>
        )}

        <Link
          href="/login"
          className="flex items-center justify-center gap-2 text-sm font-semibold text-slate-500 hover:text-slate-800 transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to Login
        </Link>
      </div>

      {/* Institutional Footer */}
      <div className="pt-8 border-t border-slate-100">
        <p className="text-xs text-slate-400 leading-relaxed">
          Need help? Contact the{' '}
          <span className="font-bold text-slate-600">Haramaya University ICT Office</span>{' '}
          or email{' '}
          <a href="mailto:support@internlink.com" className="text-primary-600 hover:underline">
            support@internlink.com
          </a>
        </p>
      </div>
    </div>
  );
}

// Loading fallback while useSearchParams loads
function VerifyEmailFallback() {
  return (
    <div className="space-y-8 animate-fade-in text-center lg:text-left">
      <div className="flex flex-col items-center lg:items-start">
        <div className="h-16 w-16 rounded-2xl bg-primary-50 flex items-center justify-center mb-6">
          <Loader2 className="h-8 w-8 text-primary-600 animate-spin" />
        </div>
        <h1 className="text-3xl font-bold text-slate-900">Loading...</h1>
        <p className="mt-2 text-sm text-slate-500">Please wait while we prepare your verification</p>
      </div>
    </div>
  );
}

// Main page component with Suspense
export default function VerifyEmailPage() {
  return (
    <Suspense fallback={<VerifyEmailFallback />}>
      <VerifyEmailContent />
    </Suspense>
  );
}