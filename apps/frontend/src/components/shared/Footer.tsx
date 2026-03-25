'use client';

import React from 'react';
import Link from 'next/link';
import { Mail, MapPin, Heart } from 'lucide-react';

const Footer = () => {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="bg-white border-t border-slate-200 py-12">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          
          {/* Logo */}
          <div>
            <Link href="/" className="inline-flex items-center gap-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary-600 text-white font-bold">
                I
              </div>
              <span className="text-lg font-bold text-slate-900">
                Intern<span className="text-primary-600">Link</span>
              </span>
            </Link>
            <p className="mt-4 text-sm text-slate-500">
              Smart Internship Management System for Ethiopian Universities
            </p>
          </div>

          {/* Quick Links */}
          <div>
            <h3 className="text-sm font-semibold text-slate-900 mb-4">Quick Links</h3>
            <ul className="space-y-2">
              <li><Link href="#how-it-works" className="text-sm text-slate-500 hover:text-primary-600">How it Works</Link></li>
              <li><Link href="#features" className="text-sm text-slate-500 hover:text-primary-600">Features</Link></li>
              <li><Link href="#testimonials" className="text-sm text-slate-500 hover:text-primary-600">Testimonials</Link></li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h3 className="text-sm font-semibold text-slate-900 mb-4">Support</h3>
            <ul className="space-y-2">
              <li><Link href="/help" className="text-sm text-slate-500 hover:text-primary-600">Help Center</Link></li>
              <li><Link href="/privacy" className="text-sm text-slate-500 hover:text-primary-600">Privacy Policy</Link></li>
              <li><Link href="/terms" className="text-sm text-slate-500 hover:text-primary-600">Terms</Link></li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h3 className="text-sm font-semibold text-slate-900 mb-4">Contact</h3>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-slate-500">
                <MapPin className="w-4 h-4 text-primary-600" />
                <span>Haramaya University</span>
              </div>
              <div className="flex items-center gap-2 text-sm text-slate-500">
                <Mail className="w-4 h-4 text-primary-600" />
                <span>support@internlink.edu.et</span>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom */}
        <div className="mt-8 pt-6 border-t border-slate-100 text-center">
          <p className="text-xs text-slate-400">
            © {currentYear} InternLink. Made with <Heart className="inline w-3 h-3 text-red-500" /> at Haramaya University
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;