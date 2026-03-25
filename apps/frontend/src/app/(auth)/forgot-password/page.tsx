'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { 
  Mail, 
  ArrowLeft, 
  Loader2, 
  CheckCircle2, 
  AlertCircle,
  Shield,
  Clock,
  MessageCircle
} from 'lucide-react';

// Types
type FormStatus = 'idle' | 'submitting' | 'success' | 'error' | 'rate_limited';

const ForgotPasswordPage = () => {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [status, setStatus] = useState<FormStatus>('idle');
  const [errorMessage, setErrorMessage] = useState('');
  const [rateLimitRemaining, setRateLimitRemaining] = useState(0);
  const [countdown, setCountdown] = useState(0);
  const [touched, setTouched] = useState(false);

  // Handle countdown for rate limiting
  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [countdown]);

  // Validate email format
  const validateEmail = (email: string) => {
    const emailRegex = /^[^\s@]+@([^\s@]+\.)+[^\s@]+$/;
    if (!email) return 'Email is required';
    if (!emailRegex.test(email)) return 'Please enter a valid email address';
    return '';
  };

  const emailError = validateEmail(email);
  const isValid = email && !emailError;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Validate email
    const validationError = validateEmail(email);
    if (validationError) {
      setErrorMessage(validationError);
      setStatus('error');
      return;
    }
    
    setStatus('submitting');
    setErrorMessage('');
    
    try {
      // Mock API call - replace with real endpoint
      // For security, always return success even if email doesn't exist (prevents user enumeration)
      const response = await new Promise<{ success: boolean; message?: string; rateLimitRemaining?: number }>((resolve) => {
        setTimeout(() => {
          // Simulate rate limiting check
          const storedRequests = localStorage.getItem('password_reset_requests');
          const requests = storedRequests ? JSON.parse(storedRequests) : [];
          const now = Date.now();
          const recentRequests = requests.filter((time: number) => now - time < 3600000); // Last hour
          
          if (recentRequests.length >= 3) {
            resolve({ 
              success: false, 
              message: 'Too many requests. Please try again later.',
              rateLimitRemaining: 0
            });
          } else {
            // Store this request
            requests.push(now);
            localStorage.setItem('password_reset_requests', JSON.stringify(requests));
            
            // Simulate successful email sending
            // In real implementation, you would send email even if user doesn't exist
            resolve({ 
              success: true,
              rateLimitRemaining: 3 - (recentRequests.length + 1)
            });
          }
        }, 1500);
      });
      
      if (response.success) {
        setStatus('success');
        setRateLimitRemaining(response.rateLimitRemaining || 2);
      } else {
        setStatus('rate_limited');
        setErrorMessage(response.message || 'Unable to process request');
        setCountdown(3600); // 1 hour cooldown
      }
      
    } catch (error) {
      setStatus('error');
      setErrorMessage('Network error. Please check your connection and try again.');
    }
  };

  const handleTryAgain = () => {
    setStatus('idle');
    setErrorMessage('');
    setTouched(false);
  };

  const handleResend = () => {
    setStatus('idle');
    setErrorMessage('');
    setTouched(false);
  };

  // Rate Limited State
  if (status === 'rate_limited') {
    const hours = Math.floor(countdown / 3600);
    const minutes = Math.floor((countdown % 3600) / 60);
    
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="text-center lg:text-left">
          <div className="h-16 w-16 rounded-2xl bg-red-50 flex items-center justify-center mb-6 mx-auto lg:mx-0">
            <Clock className="h-8 w-8 text-red-600" />
          </div>
          <h1 className="text-3xl font-bold text-slate-900">Too many attempts</h1>
          <p className="mt-2 text-sm text-slate-500">
            For security reasons, please wait before requesting another password reset.
          </p>
        </div>

        <div className="bg-red-50 border border-red-100 rounded-2xl p-6 space-y-3">
          <div className="flex items-center gap-3 text-red-700">
            <Shield className="h-5 w-5 flex-shrink-0" />
            <p className="text-sm font-medium">Rate limit exceeded</p>
          </div>
          <div className="flex items-center gap-3 text-red-600">
            <Clock className="h-5 w-5 flex-shrink-0" />
            <p className="text-sm">
              Please try again in{' '}
              {hours > 0 && `${hours} hour${hours > 1 ? 's' : ''} `}
              {minutes > 0 && `${minutes} minute${minutes > 1 ? 's' : ''}`}
            </p>
          </div>
        </div>

        <div className="space-y-4">
          <Link
            href="/login"
            className="flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-4 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700"
          >
            Return to Login
          </Link>
          <button
            onClick={handleTryAgain}
            className="w-full text-sm font-medium text-slate-500 hover:text-primary-600 transition-colors"
          >
            Try again later
          </button>
        </div>
      </div>
    );
  }

  // Success State
  if (status === 'success') {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="text-center lg:text-left">
          <div className="h-16 w-16 rounded-2xl bg-emerald-50 flex items-center justify-center mb-6 mx-auto lg:mx-0">
            <CheckCircle2 className="h-8 w-8 text-emerald-600" />
          </div>
          <h1 className="text-3xl font-bold text-slate-900">Check your email</h1>
          <p className="mt-2 text-sm text-slate-500 max-w-sm mx-auto lg:mx-0">
            We&apos;ve sent a password reset link to{' '}
            <span className="font-semibold text-primary-600 break-all">{email}</span>
          </p>
        </div>

        <div className="bg-emerald-50 border border-emerald-100 rounded-2xl p-6 space-y-4">
          <div className="flex items-start gap-3 text-emerald-700">
            <MessageCircle className="h-5 w-5 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-medium">What happens next?</p>
              <p className="text-xs text-emerald-600 mt-1">
                Click the link in the email to reset your password. The link will expire in 1 hour for security.
              </p>
            </div>
          </div>
          
          {rateLimitRemaining > 0 && (
            <div className="flex items-center gap-3 text-emerald-600 border-t border-emerald-200 pt-4">
              <Shield className="h-5 w-5 flex-shrink-0" />
              <p className="text-xs">
                You have {rateLimitRemaining} more reset request{rateLimitRemaining !== 1 ? 's' : ''} available.
              </p>
            </div>
          )}
          
          <div className="pt-2">
            <p className="text-xs text-emerald-600">
              <strong>Didn&apos;t receive the email?</strong> Check your spam folder or{' '}
              <button
                onClick={handleResend}
                className="font-medium underline hover:no-underline"
              >
                request another link
              </button>
            </p>
          </div>
        </div>

        <div className="space-y-4">
          <Link
            href="/login"
            className="flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-4 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700"
          >
            Return to Login
          </Link>
          <Link
            href="/register"
            className="flex items-center justify-center gap-2 text-sm font-medium text-slate-500 hover:text-primary-600 transition-colors"
          >
            Don&apos;t have an account? Sign up
          </Link>
        </div>
      </div>
    );
  }

  // Error State
  if (status === 'error') {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="text-center lg:text-left">
          <div className="h-16 w-16 rounded-2xl bg-red-50 flex items-center justify-center mb-6 mx-auto lg:mx-0">
            <AlertCircle className="h-8 w-8 text-red-600" />
          </div>
          <h1 className="text-3xl font-bold text-slate-900">Something went wrong</h1>
          <p className="mt-2 text-sm text-slate-500">
            We couldn&apos;t process your request
          </p>
        </div>

        <div className="bg-red-50 border border-red-100 rounded-2xl p-6">
          <p className="text-sm text-red-700 flex items-start gap-2">
            <AlertCircle className="h-4 w-4 flex-shrink-0 mt-0.5" />
            {errorMessage}
          </p>
        </div>

        <div className="space-y-4">
          <button
            onClick={handleTryAgain}
            className="w-full flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-4 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700"
          >
            Try Again
          </button>
          <Link
            href="/login"
            className="flex items-center justify-center gap-2 text-sm font-medium text-slate-500 hover:text-primary-600 transition-colors"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to Login
          </Link>
        </div>
      </div>
    );
  }

  // Default Form State
  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header Section */}
      <div className="text-center lg:text-left">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900">
          Forgot Password?
        </h1>
        <p className="mt-2 text-sm text-slate-500">
          No worries! Enter your email address and we&apos;ll send you a link to reset your password.
        </p>
      </div>

      {/* Help Text - Security Notice */}
      <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
        <div className="flex items-start gap-2">
          <Shield className="h-4 w-4 text-slate-400 flex-shrink-0 mt-0.5" />
          <p className="text-xs text-slate-500">
            For security, we&apos;ll only send reset links to registered email addresses. 
            The link will expire in 1 hour.
          </p>
        </div>
      </div>

      {/* Forgot Password Form */}
      <form onSubmit={handleSubmit} className="space-y-6">
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
              type="email"
              autoComplete="email"
              required
              placeholder="name@university.edu.et"
              className={`w-full pl-10 pr-4 py-3 rounded-xl border bg-white text-slate-900 placeholder:text-slate-400 transition-all duration-200
                focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500
                ${touched && emailError
                  ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20'
                  : 'border-slate-200 hover:border-slate-300'
                }`}
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                if (touched && emailError) {
                  setErrorMessage('');
                }
              }}
              onBlur={() => {
                setTouched(true);
                const error = validateEmail(email);
                if (error) {
                  setErrorMessage(error);
                  setStatus('error');
                } else {
                  setErrorMessage('');
                  setStatus('idle');
                }
              }}
              disabled={status === 'submitting'}
              aria-invalid={!!emailError && touched}
              aria-describedby={emailError ? 'email-error' : undefined}
            />
          </div>
          {touched && emailError && (
            <p id="email-error" className="text-xs text-red-600 flex items-center gap-1 mt-1">
              <AlertCircle className="h-3 w-3" />
              {emailError}
            </p>
          )}
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          disabled={status === 'submitting' || !isValid}
          className="w-full flex items-center justify-center rounded-xl bg-primary-600 py-3.5 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700 active:bg-primary-800 disabled:opacity-70 disabled:cursor-not-allowed"
        >
          {status === 'submitting' ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Sending reset link...
            </>
          ) : (
            'Send Reset Link'
          )}
        </button>
      </form>

      {/* Footer Links */}
      <div className="space-y-4 text-center">
        <Link 
          href="/login" 
          className="inline-flex items-center gap-2 text-sm font-semibold text-primary-600 hover:text-primary-700 transition-colors group"
        >
          <ArrowLeft className="h-4 w-4 transition-transform group-hover:-translate-x-0.5" />
          Back to Sign In
        </Link>
        
        <div className="pt-4 border-t border-slate-100">
          <p className="text-xs text-slate-400">
            Need additional help?{' '}
            <Link href="/contact" className="text-primary-600 hover:underline">
              Contact support
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default ForgotPasswordPage;