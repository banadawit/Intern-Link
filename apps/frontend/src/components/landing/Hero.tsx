'use client';

import React, { useState, useEffect } from 'react';
import { AnimatePresence, motion, useAnimation, useInView } from 'framer-motion';
import { useRef } from 'react';
import { useTranslations } from 'next-intl';

const Hero = () => {
  const t = useTranslations('Hero');
  const [isHovered, setIsHovered] = useState(false);
  const [activeRole, setActiveRole] = useState(0);
  const [mockupTilt, setMockupTilt] = useState({ x: 0, y: 0 });
  const [spotlight, setSpotlight] = useState({ x: 50, y: 50 });
  const controls = useAnimation();
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, amount: 0.3 });

  useEffect(() => {
    if (isInView) {
      controls.start('visible');
    }
  }, [controls, isInView]);

  useEffect(() => {
    const interval = setInterval(() => {
      setActiveRole((prev) => (prev + 1) % 4);
    }, 2400);
    return () => clearInterval(interval);
  }, []);

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.2,
      },
    },
  };

  const itemVariants = {
    hidden: { y: 20, opacity: 0 },
    visible: {
      y: 0,
      opacity: 1,
      transition: { duration: 0.5, ease: [0.4, 0, 0.2, 1] as const },
    },
  };

  const stats = [
    { value: '50+', label: t('stats.partnerCompanies'), color: 'primary' },
    { value: '2,000+', label: t('stats.activeStudents'), color: 'success' },
    { value: '98%', label: t('stats.placementRate'), color: 'warning' },
    { value: '24/7', label: t('stats.support'), color: 'info' },
  ];

  const roleHighlights = [
    { title: t('roles.students'), subtitle: t('roles.studentsSubtitle'), tone: 'bg-teal-50 text-teal-700 ring-teal-600/20' },
    { title: t('roles.coordinators'), subtitle: t('roles.coordinatorsSubtitle'), tone: 'bg-green-50 text-green-700 ring-green-600/20' },
    { title: t('roles.supervisors'), subtitle: t('roles.supervisorsSubtitle'), tone: 'bg-yellow-50 text-yellow-700 ring-yellow-600/20' },
    { title: t('roles.admins'), subtitle: t('roles.adminsSubtitle'), tone: 'bg-blue-50 text-blue-700 ring-blue-600/20' },
  ];

  const handleMockupMouseMove = (event: React.MouseEvent<HTMLDivElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();
    const x = ((event.clientX - rect.left) / rect.width) * 100;
    const y = ((event.clientY - rect.top) / rect.height) * 100;
    setSpotlight({ x, y });

    const rotateY = ((x - 50) / 50) * 4;
    const rotateX = -((y - 50) / 50) * 4;
    setMockupTilt({ x: rotateX, y: rotateY });
  };

  const handleMockupMouseLeave = () => {
    setMockupTilt({ x: 0, y: 0 });
    setSpotlight({ x: 50, y: 50 });
  };

  return (
    <section 
      ref={ref}
      className="relative overflow-hidden bg-white pb-14 pt-20 sm:pb-16 sm:pt-24 lg:pb-24 lg:pt-32 dark:bg-slate-950"
    >
      {/* Animated Background Elements */}
      <div className="absolute inset-0 -z-10">
        {/* Grid Pattern */}
        <div className="absolute inset-0 bg-white bg-[linear-gradient(to_right,#f1f5f9_1px,transparent_1px),linear-gradient(to_bottom,#f1f5f9_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)] dark:bg-slate-950 dark:bg-[linear-gradient(to_right,#1e293b_1px,transparent_1px),linear-gradient(to_bottom,#1e293b_1px,transparent_1px)]" />
        
        {/* Gradient Blobs */}
        <div className="absolute -top-40 -right-40 h-80 w-80 rounded-full bg-teal-100/40 blur-3xl" />
        <div className="absolute -bottom-40 -left-40 h-80 w-80 rounded-full bg-teal-50/60 blur-3xl" />
        
        {/* Animated Dots */}
        <div className="absolute inset-0 bg-[radial-gradient(#e2e8f0_1px,transparent_1px)] bg-[size:20px_20px] [mask-image:radial-gradient(ellipse_80%_50%_at_50%_50%,#000_60%,transparent_100%)]" />
      </div>

      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate={controls}
          className="flex flex-col items-center gap-10 lg:flex-row lg:items-start lg:gap-12 xl:gap-16"
        >
          {/* Left Side: Content */}
          <div className="flex-1 text-center lg:text-left">
            <motion.div variants={itemVariants}>
            </motion.div>

            <motion.h1 
              variants={itemVariants}
              className="text-3xl font-extrabold tracking-tight text-slate-900 sm:text-5xl md:text-6xl lg:text-5xl xl:text-6xl dark:text-slate-100"
            >
              {t('title')}{' '}
              <span className="relative inline-block">
                <span className="relative z-10 bg-gradient-to-r from-teal-600 to-teal-800 bg-clip-text text-transparent">
                  {t('titleHighlight')}
                </span>
                <svg className="absolute -bottom-2 left-0 w-full h-3 text-teal-200/60 -z-0" viewBox="0 0 100 10" preserveAspectRatio="none">
                  <path d="M0,5 Q10,2 20,5 T40,5 T60,5 T80,5 T100,5" stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" />
                </svg>
              </span>
            </motion.h1>

            <motion.p 
              variants={itemVariants}
              className="mx-auto mt-5 max-w-2xl text-base leading-relaxed text-slate-600 sm:text-lg lg:mx-0 dark:text-slate-300"
            >
              {t('subtitle')}
            </motion.p>

            <motion.div variants={itemVariants} className="mt-5">
              <AnimatePresence mode="wait">
                <motion.div
                  key={roleHighlights[activeRole].title}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  transition={{ duration: 0.25 }}
                  className="mt-3"
                >
                  <div
                    className={`inline-flex flex-col rounded-xl px-4 py-3 text-left ring-1 ring-inset ${roleHighlights[activeRole].tone}`}
                  >
                    <span className="text-sm font-bold">{roleHighlights[activeRole].title}</span>
                    <span className="text-xs opacity-90">{roleHighlights[activeRole].subtitle}</span>
                  </div>
                </motion.div>
              </AnimatePresence>
            </motion.div>

            <motion.div 
              variants={itemVariants}
              className="mt-10 flex flex-col items-center gap-4 sm:flex-row lg:justify-start"
            >
              <a
                href="#get-started"
                onMouseEnter={() => setIsHovered(true)}
                onMouseLeave={() => setIsHovered(false)}
                className="group relative w-full sm:w-auto overflow-hidden rounded-lg bg-gradient-to-r from-teal-600 to-teal-700 px-8 py-4 text-sm font-semibold text-white shadow-lg transition-all duration-300 hover:shadow-xl hover:from-teal-700 hover:to-teal-800 focus:outline-none focus:ring-2 focus:ring-teal-500 focus:ring-offset-2"
              >
                <span className="relative z-10 flex items-center justify-center gap-2">
                  {t('getStarted')}
                  <svg
                    className={`h-5 w-5 transition-transform duration-300 ${
                      isHovered ? 'translate-x-1' : ''
                    }`}
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M13 7l5 5m0 0l-5 5m5-5H6"
                    />
                  </svg>
                </span>
                <div className="absolute inset-0 bg-gradient-to-r from-teal-500 to-teal-600 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              </a>

              <a
                href="#features"
                className="group w-full sm:w-auto rounded-lg border border-slate-200 bg-white px-8 py-4 text-sm font-semibold text-slate-700 shadow-soft transition-all duration-300 hover:border-teal-200 hover:bg-slate-50 hover:shadow-card-hover focus:outline-none focus:ring-2 focus:ring-teal-500 focus:ring-offset-2 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200 dark:hover:bg-slate-800"
              >
                <span className="flex items-center justify-center gap-2">
                  {t('learnMore')}
                  <svg
                    className="h-5 w-5 transition-transform duration-300 group-hover:translate-x-0.5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M17 8l4 4m0 0l-4 4m4-4H3"
                    />
                  </svg>
                </span>
              </a>
            </motion.div>

            {/* Enhanced Stats Section */}
            <motion.div 
              variants={itemVariants}
              className="mt-12 flex flex-wrap items-center justify-center gap-6 border-t border-slate-100 pt-8 lg:justify-start dark:border-slate-800"
            >
              {stats.map((stat, idx) => (
                <div key={idx} className="flex items-center gap-3">
                  <div>
                    <p className="text-2xl font-bold text-slate-900 dark:text-slate-100">{stat.value}</p>
                    <p className="text-sm text-slate-500 dark:text-slate-400">{stat.label}</p>
                  </div>
                  {idx < stats.length - 1 && (
                    <div className="hidden sm:block h-8 w-px bg-slate-200" />
                  )}
                </div>
              ))}
            </motion.div>

            <motion.div
              variants={itemVariants}
              className="mt-6 flex flex-wrap items-center justify-center gap-2 lg:justify-start"
            >
              {['Smart Matching', 'Live Approvals', 'Report Automation'].map((pill) => (
                <span
                  key={pill}
                    className="rounded-full border border-slate-200 bg-white px-3 py-1 text-xs font-medium text-slate-600 shadow-soft transition-colors hover:border-teal-300 hover:text-teal-700 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300"
                >
                  {pill}
                </span>
              ))}
            </motion.div>

            {/* Trust Badges */}
            <motion.div 
              variants={itemVariants}
              className="mt-8 hidden items-center justify-center gap-4 lg:flex lg:justify-start"
            >
              <div className="flex -space-x-2">
                {[1, 2, 3, 4].map((i) => (
                  <div
                    key={i}
                    className="inline-block h-8 w-8 rounded-full bg-gradient-to-br from-slate-200 to-slate-300 ring-2 ring-white"
                  />
                ))}
              </div>
              <p className="text-sm text-slate-500">
                Trusted by <span className="font-semibold text-slate-700 dark:text-slate-200">15+ universities</span>
              </p>
            </motion.div>
          </div>

          {/* Right Side: Enhanced Visual Mockup */}
          <motion.div 
            variants={itemVariants}
            className="relative mt-6 w-full max-w-xl flex-1 self-center lg:mt-0 lg:self-start lg:max-w-none"
            onMouseMove={handleMockupMouseMove}
            onMouseLeave={handleMockupMouseLeave}
          >
            <div
              className="relative rounded-2xl border border-slate-200 bg-slate-50 p-3 shadow-xl transition-all duration-300 hover:shadow-2xl dark:border-slate-700 dark:bg-slate-900"
              style={{
                transform: `perspective(1200px) rotateX(${mockupTilt.x}deg) rotateY(${mockupTilt.y}deg)`,
              }}
            >
              <div
                className="pointer-events-none absolute inset-0 rounded-2xl opacity-70 transition-opacity duration-200"
                style={{
                  background: `radial-gradient(320px circle at ${spotlight.x}% ${spotlight.y}%, rgba(13,148,136,0.16), transparent 55%)`,
                }}
              />
              <div className="overflow-hidden rounded-xl border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-950">
                {/* Mockup Header with Dynamic Elements */}
                <div className="flex items-center justify-between border-b border-slate-100 bg-gradient-to-r from-slate-50 to-white px-4 py-3 dark:border-slate-800 dark:from-slate-900 dark:to-slate-950">
                  <div className="flex gap-1.5">
                    <div className="h-3 w-3 rounded-full bg-red-500 transition-colors cursor-pointer hover:bg-red-600" />
                    <div className="h-3 w-3 rounded-full bg-yellow-500 transition-colors cursor-pointer hover:bg-yellow-600" />
                    <div className="h-3 w-3 rounded-full bg-green-500 transition-colors cursor-pointer hover:bg-green-600" />
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="h-6 w-6 rounded-full bg-teal-100 p-1">
                      <div className="h-full w-full rounded-full bg-teal-600" />
                    </div>
                    <div className="h-4 w-24 rounded bg-slate-200 dark:bg-slate-700" />
                  </div>
                </div>

                {/* Enhanced Content Placeholder with Realistic UI Elements */}
                <div className="p-6">
                  <div className="space-y-4">
                    {/* Dashboard Header */}
                    <div className="flex items-center justify-between">
                      <div className="h-6 w-32 rounded bg-slate-100 animate-pulse dark:bg-slate-800" />
                      <div className="flex gap-2">
                        <div className="h-8 w-8 rounded bg-slate-50 border border-slate-200 dark:bg-slate-800 dark:border-slate-700" />
                        <div className="h-8 w-8 rounded bg-slate-50 border border-slate-200 dark:bg-slate-800 dark:border-slate-700" />
                      </div>
                    </div>

                    {/* Stats Grid */}
                    <div className="grid grid-cols-3 gap-3">
                      {[1, 2, 3].map((i) => (
                        <div key={i} className="h-20 rounded-lg border border-slate-100 bg-gradient-to-br from-slate-50 to-white p-2 dark:border-slate-700 dark:from-slate-900 dark:to-slate-800">
                          <div className="h-2 w-12 rounded bg-slate-200 mb-2 dark:bg-slate-700" />
                          <div className="h-6 w-16 rounded bg-slate-100 dark:bg-slate-800" />
                        </div>
                      ))}
                    </div>

                    {/* Activity Feed */}
                    <div className="rounded-lg border border-teal-100 bg-teal-50/30 p-4 dark:border-teal-900/50 dark:bg-teal-950/20">
                      <div className="flex items-center gap-3">
                        <div className="h-8 w-8 rounded-full bg-teal-100 flex items-center justify-center">
                          <div className="h-2 w-2 rounded-full bg-teal-600" />
                        </div>
                        <div className="flex-1">
                          <div className="h-3 w-3/4 rounded bg-teal-100 mb-2 dark:bg-teal-900/60" />
                          <div className="h-2 w-1/2 rounded bg-teal-50 dark:bg-teal-900/40" />
                        </div>
                      </div>
                    </div>

                    {/* Recent Activity */}
                    <div className="space-y-2">
                      <div className="flex items-center gap-3">
                        <div className="h-6 w-6 rounded-full bg-green-100" />
                        <div className="flex-1">
                          <div className="h-2 w-full rounded bg-slate-100 dark:bg-slate-700" />
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        <div className="h-6 w-6 rounded-full bg-yellow-100" />
                        <div className="flex-1">
                          <div className="h-2 w-3/4 rounded bg-slate-100 dark:bg-slate-700" />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Floating Badges with Animations */}
              <motion.div
                initial={{ opacity: 0, x: 20, y: -20 }}
                animate={{ opacity: 1, x: 0, y: 0 }}
                transition={{ delay: 0.5, duration: 0.5 }}
                className="absolute -top-6 -right-6 rounded-xl bg-white p-3 shadow-modal border border-slate-100 hidden md:block dark:bg-slate-900 dark:border-slate-700"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-green-100 text-green-600">
                    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <div>
                    <p className="text-xs font-medium text-slate-500 dark:text-slate-400">Final Report</p>
                    <p className="text-sm font-bold text-slate-900 dark:text-slate-100">Verified & Stamped</p>
                  </div>
                </div>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, x: -20, y: 20 }}
                animate={{ opacity: 1, x: 0, y: 0 }}
                transition={{ delay: 0.7, duration: 0.5 }}
                className="absolute -bottom-6 -left-6 rounded-xl bg-white p-3 shadow-modal border border-slate-100 hidden md:block dark:bg-slate-900 dark:border-slate-700"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-teal-100 text-teal-600">
                    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                    </svg>
                  </div>
                  <div>
                    <p className="text-xs font-medium text-slate-500 dark:text-slate-400">Weekly Plan</p>
                    <p className="text-sm font-bold text-slate-900 dark:text-slate-100">Submitted & Approved</p>
                  </div>
                </div>
              </motion.div>
            </div>

            {/* Decorative Elements */}
            <div className="absolute -z-10 -top-10 -right-10 h-40 w-40 rounded-full bg-teal-100/30 blur-3xl" />
            <div className="absolute -z-10 -bottom-10 -left-10 h-40 w-40 rounded-full bg-teal-50/50 blur-3xl" />
          </motion.div>
        </motion.div>
      </div>

      {/* Scroll Indicator */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1, duration: 0.5 }}
        className="absolute bottom-8 left-1/2 -translate-x-1/2 hidden lg:block"
      >
        <div className="flex flex-col items-center gap-2">
          <span className="text-xs text-slate-400">Scroll to explore</span>
          <div className="h-10 w-5 rounded-full border border-slate-300 flex justify-center">
            <motion.div
              animate={{ y: [0, 12, 0] }}
              transition={{ duration: 1.5, repeat: Infinity, ease: 'easeInOut' }}
              className="mt-2 h-2 w-1 rounded-full bg-teal-500"
            />
          </div>
        </div>
      </motion.div>
    </section>
  );
};

export default Hero;