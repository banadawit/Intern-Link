'use client';

import React from 'react';
import Link from 'next/link';
import { Mail, MapPin, Heart } from 'lucide-react';

const Footer = () => {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="relative overflow-hidden border-t border-slate-700/60 bg-slate-950 py-14 text-slate-200">
      <div className="pointer-events-none absolute inset-0 -z-10">
        <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-primary-500/40 to-transparent" />
        <div className="absolute -top-20 left-1/4 h-56 w-56 rounded-full bg-primary-700/10 blur-3xl" />
        <div className="absolute -bottom-24 right-1/4 h-56 w-56 rounded-full bg-info-700/10 blur-3xl" />
      </div>
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 gap-10 md:grid-cols-4">
          
          {/* Logo */}
          <div>
            <Link href="/" className="inline-flex items-center gap-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary-600 font-bold text-white shadow-lg shadow-primary-700/40">
                I
              </div>
              <span className="text-lg font-bold text-white">
                Intern<span className="text-primary-600">Link</span>
              </span>
            </Link>
            <p className="mt-4 text-sm text-slate-400">
              Smart Internship Management System for Ethiopian Universities
            </p>
          </div>

          {/* Quick Links */}
          <div>
            <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-slate-100">Quick Links</h3>
            <ul className="space-y-2">
              <li><Link href="#how-it-works" className="text-sm text-slate-400 transition-colors hover:text-primary-400">How it Works</Link></li>
              <li><Link href="#features" className="text-sm text-slate-400 transition-colors hover:text-primary-400">Features</Link></li>
              <li><Link href="#testimonials" className="text-sm text-slate-400 transition-colors hover:text-primary-400">Testimonials</Link></li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-slate-100">Support</h3>
            <ul className="space-y-2">
              <li><Link href="/help" className="text-sm text-slate-400 transition-colors hover:text-primary-400">Help Center</Link></li>
              <li><Link href="/privacy" className="text-sm text-slate-400 transition-colors hover:text-primary-400">Privacy Policy</Link></li>
              <li><Link href="/terms" className="text-sm text-slate-400 transition-colors hover:text-primary-400">Terms</Link></li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h3 className="mb-4 text-sm font-semibold uppercase tracking-wide text-slate-100">Contact</h3>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-slate-400">
                <MapPin className="h-4 w-4 text-primary-400" />
                <span>Haramaya University</span>
              </div>
              <div className="flex items-center gap-2 text-sm text-slate-400">
                <Mail className="h-4 w-4 text-primary-400" />
                <span>support@internlink.edu.et</span>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom */}
        <div className="mt-10 border-t border-slate-800 pt-6 text-center">
          <p className="text-xs text-slate-500">
            © {currentYear} InternLink. Made with <Heart className="inline h-3 w-3 text-red-500" /> at Haramaya University
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;