'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { motion, useInView } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { ArrowRight, CheckCircle2, Sparkles, Users, Building2, GraduationCap, Star, Rocket, Shield, Clock, Mail } from 'lucide-react';

const CTASection = () => {
  const t = useTranslations('CTA');
  const [email, setEmail] = useState('');
  const [isSubmitted, setIsSubmitted] = useState(false);
  const ref = React.useRef(null);
  const isInView = useInView(ref, { once: true, amount: 0.3 });

  const stats = [
    { icon: Users,         valueKey: 'activeStudents',   value: '2,500+' },
    { icon: Building2,     valueKey: 'partnerCompanies', value: '85+'    },
    { icon: GraduationCap, valueKey: 'universities',     value: '15+'    },
    { icon: Star,          valueKey: 'satisfaction',     value: '4.9/5'  },
  ];

  const featureKeys = [
    'freeForStudents', 'noCreditCard', 'support247',
    'instantSetup', 'verifiedCompanies', 'secureEncrypted',
  ] as const;

  const handleNewsletterSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (email) {
      setIsSubmitted(true);
      setTimeout(() => setIsSubmitted(false), 3000);
      setEmail('');
    }
  };

  return (
    <section className="relative py-24 sm:py-32 overflow-hidden bg-white dark:bg-slate-950">
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-teal-100/50 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-emerald-100/30 rounded-full blur-3xl" />
      </div>

      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div ref={ref} initial={{ opacity: 0, y: 20 }} animate={isInView ? { opacity: 1, y: 0 } : {}} transition={{ duration: 0.5 }} className="relative overflow-hidden bg-gradient-to-br from-teal-600 via-teal-700 to-teal-800 px-6 py-16 text-center shadow-2xl rounded-3xl sm:px-16 lg:py-24">
          <div className="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl" />
          <div className="absolute bottom-0 left-0 w-64 h-64 bg-white/5 rounded-full blur-3xl" />
          <svg viewBox="0 0 1024 1024" className="absolute left-1/2 top-1/2 -z-10 h-[64rem] w-[64rem] -translate-x-1/2 [mask-image:radial-gradient(closest-side,white,transparent)]" aria-hidden="true">
            <circle cx="512" cy="512" r="512" fill="url(#cta-gradient)" fillOpacity="0.15" />
            <defs><radialGradient id="cta-gradient"><stop stopColor="white" /><stop offset={1} stopColor="#0D9488" /></radialGradient></defs>
          </svg>

          <div className="relative z-10">
            <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={isInView ? { opacity: 1, scale: 1 } : {}} transition={{ delay: 0.2 }} className="inline-flex items-center rounded-full bg-white/20 backdrop-blur-sm px-4 py-1.5 text-sm font-medium text-white mb-8">
              <Sparkles className="w-4 h-4 mr-2" />
              {t('badge')}
            </motion.div>

            <motion.h2 initial={{ opacity: 0, y: 20 }} animate={isInView ? { opacity: 1, y: 0 } : {}} transition={{ delay: 0.3 }} className="mx-auto max-w-2xl text-3xl font-bold tracking-tight text-white sm:text-4xl lg:text-5xl">
              {t('title')}{' '}
              <span className="relative inline-block">{t('titleHighlight')}</span>
            </motion.h2>

            <motion.p initial={{ opacity: 0, y: 20 }} animate={isInView ? { opacity: 1, y: 0 } : {}} transition={{ delay: 0.4 }} className="mx-auto mt-6 max-w-xl text-lg leading-relaxed text-teal-100">
              {t('subtitle')}
            </motion.p>

            {/* Stats */}
            <motion.div initial={{ opacity: 0, y: 20 }} animate={isInView ? { opacity: 1, y: 0 } : {}} transition={{ delay: 0.5 }} className="mt-12 flex flex-wrap items-center justify-center gap-6 md:gap-12">
              {stats.map((stat, idx) => {
                const Icon = stat.icon;
                return (
                  <div key={idx} className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
                      <Icon className="w-5 h-5 text-white" />
                    </div>
                    <div className="text-left">
                      <p className="text-xl font-bold text-white">{stat.value}</p>
                      <p className="text-xs text-teal-200">{t(`stats.${stat.valueKey}`)}</p>
                    </div>
                  </div>
                );
              })}
            </motion.div>

            {/* Feature pills */}
            <motion.div initial={{ opacity: 0, y: 20 }} animate={isInView ? { opacity: 1, y: 0 } : {}} transition={{ delay: 0.6 }} className="mt-8 flex flex-wrap items-center justify-center gap-3">
              {featureKeys.map((key) => (
                <div key={key} className="flex items-center gap-1.5 bg-white/10 rounded-full px-3 py-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-teal-200" />
                  <span className="text-xs text-teal-100">{t(`features.${key}`)}</span>
                </div>
              ))}
            </motion.div>

            {/* Newsletter */}
            <motion.div initial={{ opacity: 0, y: 20 }} animate={isInView ? { opacity: 1, y: 0 } : {}} transition={{ delay: 0.65 }} className="mt-8 max-w-md mx-auto">
              <form onSubmit={handleNewsletterSubmit} className="flex flex-col sm:flex-row gap-3">
                <div className="flex-1 relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-teal-300" />
                  <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder={t('newsletter.placeholder')} className="w-full pl-9 pr-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder:text-teal-200 focus:outline-none focus:ring-2 focus:ring-white/50" required />
                </div>
                <button type="submit" className="px-6 py-3 rounded-xl bg-white text-teal-600 font-semibold hover:bg-teal-50 transition-all hover:scale-105 active:scale-95">
                  {t('newsletter.subscribe')}
                </button>
              </form>
              {isSubmitted && (
                <motion.p initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="text-xs text-teal-200 mt-2 text-center">
                  ✓ {t('newsletter.success')}
                </motion.p>
              )}
            </motion.div>

            {/* Buttons */}
            <motion.div initial={{ opacity: 0, y: 20 }} animate={isInView ? { opacity: 1, y: 0 } : {}} transition={{ delay: 0.7 }} className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
              <Link href="/register" className="group inline-flex items-center justify-center gap-2 rounded-xl bg-white px-8 py-4 text-sm font-bold text-teal-600 shadow-lg hover:shadow-xl hover:bg-teal-50 transition-all hover:scale-105 active:scale-95">
                {t('getStarted')}
                <Rocket className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
              </Link>
              <Link href="/contact" className="group inline-flex items-center gap-2 rounded-xl px-6 py-4 text-sm font-semibold text-white hover:text-teal-100 transition-colors">
                {t('contactUs')}
                <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
              </Link>
            </motion.div>

            {/* Trust */}
            <motion.div initial={{ opacity: 0 }} animate={isInView ? { opacity: 1 } : {}} transition={{ delay: 0.8 }} className="mt-12 flex flex-col items-center gap-4">
              <div className="flex items-center gap-2">
                <Shield className="w-4 h-4 text-teal-200" />
                <p className="text-xs font-medium uppercase tracking-wider text-teal-200">Trusted & Verified Platform</p>
              </div>
              <div className="flex items-center gap-3">
                <div className="flex -space-x-1">
                  {[1,2,3,4].map((i) => <div key={i} className="w-6 h-6 rounded-full bg-white/20 ring-2 ring-teal-600" />)}
                </div>
                <p className="text-xs text-teal-200">Join <span className="font-semibold text-white">2,500+</span> active users</p>
                <div className="h-3 w-px bg-teal-400" />
                <div className="flex items-center gap-1">
                  <Clock className="w-3 h-3 text-teal-200" />
                  <p className="text-xs text-teal-200">Setup in 5 minutes</p>
                </div>
              </div>
            </motion.div>
          </div>
        </motion.div>

        {/* Contact row */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={isInView ? { opacity: 1, y: 0 } : {}} transition={{ delay: 1, duration: 0.5 }} className="mt-8 flex flex-wrap items-center justify-center gap-4">
          <div className="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" /></svg>
            <span>Live chat support</span>
          </div>
          <div className="w-1 h-1 rounded-full bg-slate-300 dark:bg-slate-600" />
          <div className="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400">
            <Mail className="w-4 h-4" />
            <span>{t('contact.email')}</span>
          </div>
          <div className="w-1 h-1 rounded-full bg-slate-300 dark:bg-slate-600" />
          <div className="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400">
            <Shield className="w-4 h-4" />
            <span>100% satisfaction guaranteed</span>
          </div>
        </motion.div>
      </div>
    </section>
  );
};

export default CTASection;
