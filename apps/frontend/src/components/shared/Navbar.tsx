"use client";

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';

const Navbar = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const pathname = usePathname();

  // Handle scroll effect
  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Close mobile menu when route changes
  useEffect(() => {
    setIsMobileMenuOpen(false);
  }, [pathname]);

  // Prevent body scroll when mobile menu is open
  useEffect(() => {
    if (isMobileMenuOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isMobileMenuOpen]);

  const navLinks = [
    { href: "#features", label: "Features" },
    { href: "#how-it-works", label: "How it Works" },
    { href: "#stats", label: "Impact" },
    { href: "#testimonials", label: "Testimonials" },
  ];

  const handleSmoothScroll = (e: React.MouseEvent<HTMLAnchorElement>, href: string) => {
    e.preventDefault();
    const targetId = href.replace('#', '');
    const element = document.getElementById(targetId);
    
    if (element) {
      const offset = 80; // Navbar height offset
      const elementPosition = element.getBoundingClientRect().top;
      const offsetPosition = elementPosition + window.pageYOffset - offset;
      
      window.scrollTo({
        top: offsetPosition,
        behavior: "smooth"
      });
    }
    
    setIsMobileMenuOpen(false);
  };

  const handleLogoClick = (e: React.MouseEvent<HTMLAnchorElement>) => {
    // If already on landing page, smoothly scroll to top hero.
    if (pathname === '/') {
      e.preventDefault();
      window.scrollTo({ top: 0, behavior: 'smooth' });
      window.history.replaceState(null, '', '/');
    }
    setIsMobileMenuOpen(false);
  };

  return (
    <>
      <nav 
        className={`fixed top-0 z-50 w-full transition-all duration-300 ${
          isScrolled 
            ? 'bg-white/90 backdrop-blur-md border-b border-slate-200 py-3 shadow-lg' 
            : 'bg-transparent py-5'
        }`}
      >
        <div className="container mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between">
            
            {/* Logo Section */}
            <Link href="/#home" onClick={handleLogoClick} className="flex items-center gap-2 group">
              <motion.div 
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary-600 to-primary-700 text-white shadow-soft transition-all group-hover:shadow-lg"
              >
                <span className="text-xl font-bold">I</span>
              </motion.div>
              <span className="text-xl font-bold tracking-tight text-slate-900">
                Intern<span className="bg-gradient-to-r from-primary-600 to-primary-700 bg-clip-text text-transparent">Link</span>
              </span>
            </Link>

            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center gap-6 lg:gap-8">
              {navLinks.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  onClick={(e) => handleSmoothScroll(e, link.href)}
                  className="relative text-sm font-medium text-slate-600 hover:text-primary-600 transition-colors group"
                >
                  {link.label}
                  <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-gradient-to-r from-primary-600 to-primary-700 transition-all duration-300 group-hover:w-full" />
                </a>
              ))}
            </div>

            {/* Auth Actions */}
            <div className="flex items-center gap-2 sm:gap-4">
              <Link 
                href="/login" 
                className="hidden sm:block text-sm font-semibold text-slate-700 hover:text-primary-600 transition-all duration-300 relative group"
              >
                Sign in
                <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-primary-600 transition-all duration-300 group-hover:w-full" />
              </Link>
              <Link 
                href="/register" 
                className="relative overflow-hidden rounded-lg bg-gradient-to-r from-primary-600 to-primary-700 px-4 py-2 text-xs font-semibold text-white shadow-soft transition-all duration-300 hover:shadow-lg hover:from-primary-700 hover:to-primary-800 active:scale-95 sm:px-5 sm:py-2.5 sm:text-sm"
              >
                <span className="relative z-10">Get Started</span>
                <div className="absolute inset-0 bg-gradient-to-r from-primary-500 to-primary-600 translate-y-full transition-transform duration-300 group-hover:translate-y-0" />
              </Link>
              
              {/* Mobile Menu Button */}
              <button
                onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                className="md:hidden relative w-10 h-10 flex items-center justify-center rounded-lg bg-slate-100 hover:bg-slate-200 transition-colors focus:outline-none focus:ring-2 focus:ring-primary-500"
                aria-label="Toggle menu"
              >
                <div className="w-5 flex flex-col items-center gap-1.5">
                  <span 
                    className={`block h-0.5 bg-slate-600 transition-all duration-300 ${
                      isMobileMenuOpen ? 'rotate-45 translate-y-2' : 'w-5'
                    }`}
                  />
                  <span 
                    className={`block h-0.5 bg-slate-600 transition-all duration-300 ${
                      isMobileMenuOpen ? 'opacity-0' : 'w-5'
                    }`}
                  />
                  <span 
                    className={`block h-0.5 bg-slate-600 transition-all duration-300 ${
                      isMobileMenuOpen ? '-rotate-45 -translate-y-2' : 'w-5'
                    }`}
                  />
                </div>
              </button>
            </div>

          </div>
        </div>
      </nav>

      {/* Mobile Menu Overlay */}
      <AnimatePresence>
        {isMobileMenuOpen && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              onClick={() => setIsMobileMenuOpen(false)}
              className="fixed inset-0 bg-black/50 z-40 md:hidden"
            />
            
            {/* Menu Panel */}
            <motion.div
              initial={{ x: '100%' }}
              animate={{ x: 0 }}
              exit={{ x: '100%' }}
              transition={{ type: 'tween', duration: 0.3 }}
              className="fixed right-0 top-0 h-full w-full max-w-sm bg-white z-50 md:hidden shadow-2xl"
            >
              <div className="flex flex-col h-full">
                {/* Mobile Menu Header */}
                <div className="flex items-center justify-between p-6 border-b border-slate-100">
                  <Link href="/#home" className="flex items-center gap-2" onClick={handleLogoClick}>
                    <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary-600 text-white">
                      <span className="text-xl font-bold">I</span>
                    </div>
                    <span className="text-xl font-bold tracking-tight text-slate-900">
                      Intern<span className="text-primary-600">Link</span>
                    </span>
                  </Link>
                  <button
                    onClick={() => setIsMobileMenuOpen(false)}
                    className="p-2 rounded-lg hover:bg-slate-100 transition-colors"
                    aria-label="Close menu"
                  >
                    <svg className="w-6 h-6 text-slate-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>

                {/* Mobile Navigation Links */}
                <div className="flex-1 overflow-y-auto py-8">
                  <div className="px-6 space-y-1">
                    {navLinks.map((link, index) => (
                      <motion.div
                        key={link.href}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: index * 0.05 }}
                      >
                        <a
                          href={link.href}
                          onClick={(e) => handleSmoothScroll(e, link.href)}
                          className="block rounded-lg py-3 text-base font-medium text-slate-700 transition-colors hover:bg-slate-50 hover:text-primary-600"
                        >
                          {link.label}
                        </a>
                      </motion.div>
                    ))}
                  </div>

                  {/* Mobile Auth Actions */}
                  <div className="mt-8 px-6 space-y-3">
                    <div className="relative">
                      <div className="absolute inset-0 flex items-center">
                        <div className="w-full border-t border-slate-200" />
                      </div>
                      <div className="relative flex justify-center text-xs uppercase">
                        <span className="bg-white px-2 text-slate-500">Get Started</span>
                      </div>
                    </div>
                    <Link
                      href="/login"
                      onClick={() => setIsMobileMenuOpen(false)}
                      className="block w-full text-center rounded-lg border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-700 hover:bg-slate-50 transition-colors"
                    >
                      Sign In
                    </Link>
                    <Link
                      href="/register"
                      onClick={() => setIsMobileMenuOpen(false)}
                      className="block w-full text-center rounded-lg bg-gradient-to-r from-primary-600 to-primary-700 px-4 py-3 text-sm font-semibold text-white shadow-soft hover:shadow-lg transition-all"
                    >
                      Create Account
                    </Link>
                  </div>

                  {/* Mobile Footer */}
                  <div className="mt-auto px-6 pt-8 pb-6">
                    <div className="text-center text-xs text-slate-400">
                      <p>© 2024 InternLink. All rights reserved.</p>
                    </div>
                  </div>
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </>
  );
};

export default Navbar;