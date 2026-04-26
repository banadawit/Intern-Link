// app/(auth)/layout.tsx
'use client'; // Add this if using client-side auth

import React from 'react';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { useAuth } from '@/lib/hooks/useAuth';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user } = useAuth();
  const router = useRouter();

  // If already logged in, redirect to appropriate dashboard
  useEffect(() => {
    let storedUser: { role?: string; institutionAccessApproval?: string } | null = null;
    try {
      const raw = localStorage.getItem("auth-storage");
      if (raw) storedUser = JSON.parse(raw)?.state?.user ?? null;
    } catch { storedUser = null; }

    const token = localStorage.getItem("token");
    if (!token || !storedUser?.role) return;

    if (
      (storedUser.role === 'COORDINATOR' || storedUser.role === 'HOD' || storedUser.role === 'SUPERVISOR') &&
      storedUser.institutionAccessApproval !== 'APPROVED'
    ) return;

    // Students with pending HoD approval stay on pending page
    if (storedUser.role === 'STUDENT' && (storedUser as any).hodApprovalStatus === 'PENDING') return;

    const dest: Record<string, string> = {
      ADMIN: '/admin', COORDINATOR: '/coordinator', HOD: '/hod',
      SUPERVISOR: '/supervisor', STUDENT: '/student',
    };
    if (dest[storedUser.role]) router.replace(dest[storedUser.role]);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className="min-h-screen grid lg:grid-cols-2 bg-white">
      {/* Left Side: The Form */}
      <div className="flex flex-col justify-center px-8 py-12 sm:px-12 lg:px-20 xl:px-32">
        <div className="mb-8">
          <Link 
            href="/" 
            className="inline-flex items-center text-sm font-medium text-slate-500 hover:text-primary-600 transition-colors"
          >
            <ArrowLeft className="mr-2 h-4 w-4" />
            Back to Home
          </Link>
        </div>
        
        <div className="w-full max-w-md mx-auto">
          {children}
        </div>
      </div>

      {/* Right Side: Visual/Branding (Hidden on Mobile) */}
      <div className="hidden lg:block relative bg-slate-900 overflow-hidden">
        {/* Abstract Background Decoration */}
        <div className="absolute inset-0 bg-gradient-to-br from-primary-600/20 to-slate-900 z-10" />
        <div className="absolute inset-0 bg-[url('/assets/images/auth-pattern.svg')] opacity-10" />
        
        <div className="relative z-20 h-full flex flex-col justify-center p-16 text-white">
          <div className="flex items-center gap-3 mb-8">
            <div className="h-12 w-12 rounded-2xl bg-primary-600 flex items-center justify-center text-2xl font-bold">I</div>
            <span className="text-3xl font-bold tracking-tight">InternLink</span>
          </div>
          
          <blockquote className="space-y-4">
            <p className="text-2xl font-medium leading-relaxed">
              &quot;Connecting the brightest minds of Haramaya University with the leading industries of Ethiopia.&quot;
            </p>
            <footer className="text-slate-400">
              — Official Career Management Portal
            </footer>
          </blockquote>
        </div>
      </div>
    </div>
  );
}