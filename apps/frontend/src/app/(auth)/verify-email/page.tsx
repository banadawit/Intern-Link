'use client';

import React, { useState, useEffect, Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { Mail, ArrowLeft, RefreshCcw, CheckCircle2, Loader2, XCircle, AlertCircle, PartyPopper, Clock, ShieldCheck } from 'lucide-react';
import { useAuth } from '@/lib/hooks/useAuth';
import { useTranslations } from 'next-intl';

type VerificationStatus = 'idle' | 'verifying' | 'success' | 'error' | 'expired';

// Separate component that uses useSearchParams
function VerifyEmailContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { verifyEmail, resendVerification } = useAuth();
  const t = useTranslations('Auth.verifyEmail');
  
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
      
      // Coordinators, HoDs and Students go to pending-review; everyone else goes to login
      setTimeout(() => {
        if (roleParam === 'coordinator' || roleParam === 'hod' || roleParam === 'student' || roleParam === 'supervisor') {
          router.push(`/register/pending-review?role=${roleParam}`);
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
          <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">{t('verifying')}</h1>
          <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
            {t('verifyingSubtitle')}
          </p>
        </div>
        
        <div className="bg-slate-50 border border-slate-100 rounded-2xl p-6 dark:bg-slate-900 dark:border-slate-800">
          <div className="flex items-center justify-center gap-3">
            <Loader2 className="h-5 w-5 text-primary-600 animate-spin" />
            <span className="text-sm text-slate-600 dark:text-slate-300">{t('verifyingLabel')}</span>
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
          <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">{t('successTitle')} 🎉</h1>
          <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
            {roleParam === 'coordinator' || roleParam === 'hod' || roleParam === 'student' || roleParam === 'supervisor'
              ? t('successRedirectPending')
              : t('successRedirectLogin')}
          </p>
        </div>

        <div className="bg-emerald-50 border border-emerald-100 rounded-2xl p-6 space-y-3">
          <div className="flex items-center gap-3 text-emerald-700">
            <CheckCircle2 className="h-5 w-5 flex-shrink-0" />
            <span className="text-sm font-medium">{t('emailConfirmedSuccessfully')}</span>
          </div>
          {roleParam === 'coordinator' || roleParam === 'hod' || roleParam === 'student' || roleParam === 'supervisor' ? (
            <div className="flex items-center gap-3 text-emerald-600">
              <ShieldCheck className="h-5 w-5 flex-shrink-0" />
              <span className="text-sm">{t('registrationPendingReview')}</span>
            </div>
          ) : (
            <div className="flex items-center gap-3 text-emerald-600">
              <ShieldCheck className="h-5 w-5 flex-shrink-0" />
              <span className="text-sm">{t('canAccessAllFeatures')}</span>
            </div>
          )}
        </div>

        <div className="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden dark:bg-slate-800">
          <div className="h-full bg-emerald-500 rounded-full animate-progress-fast" style={{ width: '100%' }} />
        </div>

        <Link
          href={roleParam === 'coordinator' || roleParam === 'hod' || roleParam === 'student' || roleParam === 'supervisor' ? `/register/pending-review?role=${roleParam}` : '/login'}
          className="flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-3.5 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700"
        >
          {roleParam === 'coordinator' ? t('viewSubmissionStatus') : t('continueToLogin')}
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
          <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">{t('errorTitle')}</h1>
          <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
            We couldn&apos;t verify your email address
          </p>
        </div>

        <div className="bg-red-50 border border-red-100 rounded-2xl p-6 space-y-3">
          <div className="flex items-start gap-3 text-red-700">
            <AlertCircle className="h-5 w-5 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-medium">{t('verificationError')}</p>
              <p className="text-xs text-red-600 mt-1">{errorMessage}</p>
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <div className="space-y-2">
            <label className="text-sm font-semibold text-slate-700 dark:text-slate-200">
              {t('emailLabel')}
            </label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 dark:text-slate-500" />
              <input
                type="email"
                value={resendEmail}
                onChange={(e) => setResendEmail(e.target.value)}
                placeholder={t('emailPlaceholder')}
                className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 bg-white text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:placeholder:text-slate-500"
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
            {countdown > 0 ? t('resendCountdown', { countdown }) : t('requestNewLink')}
          </button>

          {resendSuccess && (
            <div className="flex items-center gap-2 text-emerald-600 text-sm justify-center">
              <CheckCircle2 className="h-4 w-4" />
              {t('resendSuccess')}
            </div>
          )}

          <Link
            href="/login"
            className="flex items-center justify-center gap-2 text-sm font-semibold text-slate-500 hover:text-slate-800 transition-colors dark:text-slate-400 dark:hover:text-slate-200"
          >
            <ArrowLeft className="h-4 w-4" />
            {t('backToLogin')}
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
          <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">{t('expiredTitle')}</h1>
          <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
            {t('expiredSubtitle')}
          </p>
        </div>

        <div className="bg-yellow-50 border border-yellow-100 rounded-2xl p-6">
          <p className="text-sm text-yellow-700">
            {t('expiredReason')}
          </p>
        </div>

        <div className="space-y-4">
          <div className="space-y-2">
            <label className="text-sm font-semibold text-slate-700 dark:text-slate-200">
              {t('emailLabel')}
            </label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 dark:text-slate-500" />
              <input
                type="email"
                value={resendEmail}
                onChange={(e) => setResendEmail(e.target.value)}
                placeholder={t('emailPlaceholder')}
                className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 bg-white text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:placeholder:text-slate-500"
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
            {countdown > 0 ? t('resendCountdown', { countdown }) : t('sendNewLink')}
          </button>

          {resendSuccess && (
            <div className="flex items-center gap-2 text-emerald-600 text-sm justify-center">
              <CheckCircle2 className="h-4 w-4" />
              {t('resendSuccess')}
            </div>
          )}

          <Link
            href="/login"
            className="flex items-center justify-center gap-2 text-sm font-semibold text-slate-500 hover:text-slate-800 transition-colors dark:text-slate-400 dark:hover:text-slate-200"
          >
            <ArrowLeft className="h-4 w-4" />
            {t('backToLogin')}
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
        <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">{t('checkEmailTitle')}</h1>
        <p className="mt-2 text-sm text-slate-500 max-w-sm dark:text-slate-400">
          {t('checkEmailSentTo')}{' '}
          <span className="font-medium text-primary-600">
            {resendEmail || t('yourEmailAddress')}
          </span>
          .{' '}
          {roleParam === 'coordinator'
            ? t('checkEmailRoleCoordinator')
            : roleParam === 'hod'
            ? t('checkEmailRoleHod')
            : roleParam === 'student'
            ? t('checkEmailRoleStudent')
            : roleParam === 'supervisor'
            ? t('checkEmailRoleSupervisor')
            : t('checkEmailRoleDefault')}
        </p>
      </div>

      {/* Verification Status Card */}
      <div className="bg-slate-50 border border-slate-100 rounded-2xl p-6 space-y-4 dark:bg-slate-900 dark:border-slate-800">
        <div className="flex items-center gap-3 text-sm text-slate-600 dark:text-slate-300">
          <CheckCircle2 className="h-5 w-5 text-emerald-500 flex-shrink-0" />
          <span>{t('verificationEmailSentStatus')}</span>
        </div>
        <div className="flex items-center gap-3 text-sm text-slate-600 dark:text-slate-300">
          <div className="h-5 w-5 rounded-full border-2 border-slate-200 border-t-primary-600 animate-spin" />
          <span>{t('awaitingConfirmation')}</span>
        </div>
        
        {/* Tip for users */}
        <div className="mt-4 pt-4 border-t border-slate-200 dark:border-slate-700">
          <p className="text-xs text-slate-500 flex items-start gap-2 dark:text-slate-400">
            <AlertCircle className="h-3 w-3 flex-shrink-0 mt-0.5" />
            {t('checkSpamTip')}
          </p>
        </div>
      </div>

      {/* Email Input for Resend (if email not in URL) */}
      {!emailParam && (
        <div className="space-y-2">
          <label className="text-sm font-semibold text-slate-700 dark:text-slate-200">
            {t('didntReceiveLabel')}
          </label>
          <div className="relative">
            <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 dark:text-slate-500" />
            <input
              type="email"
              value={resendEmail}
              onChange={(e) => setResendEmail(e.target.value)}
              placeholder={t('enterEmailToResend')}
              className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 bg-white text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:placeholder:text-slate-500"
            />
          </div>
        </div>
      )}

      {/* Action Buttons */}
      <div className="space-y-4">
        <button
          onClick={handleResend}
          disabled={isResending || countdown > 0 || !resendEmail}
          className="w-full flex items-center justify-center gap-2 rounded-xl border-2 border-slate-200 bg-white py-4 text-sm font-bold text-slate-700 transition-all hover:border-primary-600 hover:text-primary-600 disabled:opacity-50 disabled:hover:border-slate-200 disabled:hover:text-slate-700 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200 dark:disabled:hover:border-slate-700 dark:disabled:hover:text-slate-200"
        >
          {isResending ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <RefreshCcw className="h-4 w-4" />
          )}
          {countdown > 0 ? t('resendCountdown', { countdown }) : t('resendVerificationEmail')}
        </button>

        {resendSuccess && (
          <div className="flex items-center gap-2 text-emerald-600 text-sm justify-center">
            <CheckCircle2 className="h-4 w-4" />
            {t('resendSuccess')}
          </div>
        )}

        <Link
          href="/login"
          className="flex items-center justify-center gap-2 text-sm font-semibold text-slate-500 hover:text-slate-800 transition-colors dark:text-slate-400 dark:hover:text-slate-200"
        >
          <ArrowLeft className="h-4 w-4" />
          {t('backToLogin')}
        </Link>
      </div>

      {/* Institutional Footer */}
      <div className="pt-8 border-t border-slate-100 dark:border-slate-800">
        <p className="text-xs text-slate-400 leading-relaxed dark:text-slate-500">
          {t('needHelpContact')}{' '}
          <span className="font-bold text-slate-600 dark:text-slate-300">{t('ictOffice')}</span>{' '}
          {t('orEmail')}{' '}
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
        <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">Loading...</h1>
        <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">Please wait while we prepare your verification</p>
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