'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { motion, useAnimation, useInView } from 'framer-motion';
import { useRef } from 'react';

const Hero = () => {
  const [isHovered, setIsHovered] = useState(false);
  const controls = useAnimation();
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, amount: 0.3 });

  useEffect(() => {
    if (isInView) {
      controls.start('visible');
    }
  }, [controls, isInView]);

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
    { value: '50+', label: 'Partner Companies', color: 'primary' },
    { value: '2,000+', label: 'Active Students', color: 'success' },
    { value: '98%', label: 'Placement Rate', color: 'warning' },
    { value: '24/7', label: 'Support', color: 'info' },
  ];

  return (
    <section 
      ref={ref}
      className="relative overflow-hidden bg-white pb-14 pt-20 sm:pb-16 sm:pt-24 lg:pb-24 lg:pt-32"
    >
      {/* Animated Background Elements */}
      <div className="absolute inset-0 -z-10">
        {/* Grid Pattern */}
        <div className="absolute inset-0 bg-white bg-[linear-gradient(to_right,#f1f5f9_1px,transparent_1px),linear-gradient(to_bottom,#f1f5f9_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)]" />
        
        {/* Gradient Blobs */}
        <div className="absolute -top-40 -right-40 h-80 w-80 rounded-full bg-primary-100/30 blur-3xl" />
        <div className="absolute -bottom-40 -left-40 h-80 w-80 rounded-full bg-primary-50/40 blur-3xl" />
        
        {/* Animated Dots */}
        <div className="absolute inset-0 bg-[radial-gradient(#e2e8f0_1px,transparent_1px)] bg-[size:20px_20px] [mask-image:radial-gradient(ellipse_80%_50%_at_50%_50%,#000_60%,transparent_100%)]" />
      </div>

      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate={controls}
          className="flex flex-col items-center gap-10 lg:flex-row lg:gap-12 xl:gap-16"
        >
          {/* Left Side: Content */}
          <div className="flex-1 text-center lg:text-left">
            <motion.div variants={itemVariants}>
              <div className="inline-flex items-center rounded-full bg-primary-50 px-4 py-1.5 text-sm font-medium text-primary-700 ring-1 ring-inset ring-primary-600/20 mb-6 shadow-soft">
                <span className="relative flex h-2 w-2 mr-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-primary-500"></span>
                </span>
                Official Platform for Ethiopian Universities
              </div>
            </motion.div>

            <motion.h1 
              variants={itemVariants}
              className="text-3xl font-extrabold tracking-tight text-slate-900 sm:text-5xl md:text-6xl lg:text-5xl xl:text-6xl"
            >
              Digitizing the Future of{' '}
              <span className="relative inline-block">
                <span className="relative z-10 bg-gradient-to-r from-primary-600 to-primary-800 bg-clip-text text-transparent">
                  Internships
                </span>
                <svg
                  className="absolute -bottom-2 left-0 w-full h-3 text-primary-200/50 -z-0"
                  viewBox="0 0 100 10"
                  preserveAspectRatio="none"
                >
                  <path
                    d="M0,5 Q10,2 20,5 T40,5 T60,5 T80,5 T100,5"
                    stroke="currentColor"
                    strokeWidth="2"
                    fill="none"
                    strokeLinecap="round"
                  />
                </svg>
              </span>
              <br />
              <span className="text-slate-900">in Ethiopia</span>
            </motion.h1>

            <motion.p 
              variants={itemVariants}
              className="mx-auto mt-5 max-w-2xl text-base leading-relaxed text-slate-600 sm:text-lg lg:mx-0"
            >
              A smart, centralized ecosystem connecting{' '}
              <span className="font-semibold text-slate-900">Students</span>,{' '}
              <span className="font-semibold text-slate-900">Coordinators</span>, and{' '}
              <span className="font-semibold text-slate-900">Industry Partners</span>{' '}
              for seamless placement, supervision, and evaluation.
            </motion.p>

            <motion.div 
              variants={itemVariants}
              className="mt-10 flex flex-col items-center gap-4 sm:flex-row lg:justify-start"
            >
              <a
                href="#get-started"
                onMouseEnter={() => setIsHovered(true)}
                onMouseLeave={() => setIsHovered(false)}
                className="group relative w-full sm:w-auto overflow-hidden rounded-lg bg-gradient-to-r from-primary-600 to-primary-700 px-8 py-4 text-sm font-semibold text-white shadow-lg transition-all duration-300 hover:shadow-xl hover:from-primary-700 hover:to-primary-800 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2"
              >
                <span className="relative z-10 flex items-center justify-center gap-2">
                  Get Started
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
                <div className="absolute inset-0 bg-gradient-to-r from-primary-500 to-primary-600 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              </a>

              <a
                href="#features"
                className="group w-full sm:w-auto rounded-lg border border-slate-200 bg-white px-8 py-4 text-sm font-semibold text-slate-700 shadow-soft transition-all duration-300 hover:border-primary-200 hover:bg-slate-50 hover:shadow-card-hover focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2"
              >
                <span className="flex items-center justify-center gap-2">
                  Explore Companies
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
              className="mt-12 flex flex-wrap items-center justify-center gap-6 border-t border-slate-100 pt-8 lg:justify-start"
            >
              {stats.map((stat, idx) => (
                <div key={idx} className="flex items-center gap-3">
                  <div>
                    <p className="text-2xl font-bold text-slate-900">{stat.value}</p>
                    <p className="text-sm text-slate-500">{stat.label}</p>
                  </div>
                  {idx < stats.length - 1 && (
                    <div className="hidden sm:block h-8 w-px bg-slate-200" />
                  )}
                </div>
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
                Trusted by <span className="font-semibold text-slate-700">15+ universities</span>
              </p>
            </motion.div>
          </div>

          {/* Right Side: Enhanced Visual Mockup */}
          <motion.div 
            variants={itemVariants}
            className="relative mt-8 w-full max-w-xl flex-1 lg:mt-0 lg:max-w-none"
          >
            <div className="relative rounded-2xl border border-slate-200 bg-slate-50 p-3 shadow-xl transition-all duration-300 hover:shadow-2xl">
              <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
                {/* Mockup Header with Dynamic Elements */}
                <div className="flex items-center justify-between border-b border-slate-100 bg-gradient-to-r from-slate-50 to-white px-4 py-3">
                  <div className="flex gap-1.5">
                    <div className="h-3 w-3 rounded-full bg-error-500 hover:bg-error-600 transition-colors cursor-pointer" />
                    <div className="h-3 w-3 rounded-full bg-warning-500 hover:bg-warning-600 transition-colors cursor-pointer" />
                    <div className="h-3 w-3 rounded-full bg-success-500 hover:bg-success-600 transition-colors cursor-pointer" />
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="h-6 w-6 rounded-full bg-primary-100 p-1">
                      <div className="h-full w-full rounded-full bg-primary-600" />
                    </div>
                    <div className="h-4 w-24 rounded bg-slate-200" />
                  </div>
                </div>

                {/* Enhanced Content Placeholder with Realistic UI Elements */}
                <div className="p-6">
                  <div className="space-y-4">
                    {/* Dashboard Header */}
                    <div className="flex items-center justify-between">
                      <div className="h-6 w-32 rounded bg-slate-100 animate-pulse" />
                      <div className="flex gap-2">
                        <div className="h-8 w-8 rounded bg-slate-50 border border-slate-200" />
                        <div className="h-8 w-8 rounded bg-slate-50 border border-slate-200" />
                      </div>
                    </div>

                    {/* Stats Grid */}
                    <div className="grid grid-cols-3 gap-3">
                      {[1, 2, 3].map((i) => (
                        <div
                          key={i}
                          className="h-20 rounded-lg border border-slate-100 bg-gradient-to-br from-slate-50 to-white p-2"
                        >
                          <div className="h-2 w-12 rounded bg-slate-200 mb-2" />
                          <div className="h-6 w-16 rounded bg-slate-100" />
                        </div>
                      ))}
                    </div>

                    {/* Activity Feed */}
                    <div className="rounded-lg border border-primary-100 bg-primary-50/30 p-4">
                      <div className="flex items-center gap-3">
                        <div className="h-8 w-8 rounded-full bg-primary-100 flex items-center justify-center">
                          <div className="h-2 w-2 rounded-full bg-primary-600" />
                        </div>
                        <div className="flex-1">
                          <div className="h-3 w-3/4 rounded bg-primary-100 mb-2" />
                          <div className="h-2 w-1/2 rounded bg-primary-50" />
                        </div>
                      </div>
                    </div>

                    {/* Recent Activity */}
                    <div className="space-y-2">
                      <div className="flex items-center gap-3">
                        <div className="h-6 w-6 rounded-full bg-success-100" />
                        <div className="flex-1">
                          <div className="h-2 w-full rounded bg-slate-100" />
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        <div className="h-6 w-6 rounded-full bg-warning-100" />
                        <div className="flex-1">
                          <div className="h-2 w-3/4 rounded bg-slate-100" />
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
                className="absolute -top-6 -right-6 rounded-xl bg-white p-3 shadow-modal border border-slate-100 hidden md:block"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-success-100 text-success-600">
                    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <div>
                    <p className="text-xs font-medium text-slate-500">Final Report</p>
                    <p className="text-sm font-bold text-slate-900">Verified & Stamped</p>
                  </div>
                </div>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, x: -20, y: 20 }}
                animate={{ opacity: 1, x: 0, y: 0 }}
                transition={{ delay: 0.7, duration: 0.5 }}
                className="absolute -bottom-6 -left-6 rounded-xl bg-white p-3 shadow-modal border border-slate-100 hidden md:block"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary-100 text-primary-600">
                    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                    </svg>
                  </div>
                  <div>
                    <p className="text-xs font-medium text-slate-500">Weekly Plan</p>
                    <p className="text-sm font-bold text-slate-900">Submitted & Approved</p>
                  </div>
                </div>
              </motion.div>
            </div>

            {/* Decorative Elements */}
            <div className="absolute -z-10 -top-10 -right-10 h-40 w-40 rounded-full bg-primary-100/20 blur-3xl" />
            <div className="absolute -z-10 -bottom-10 -left-10 h-40 w-40 rounded-full bg-primary-50/30 blur-3xl" />
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
              className="h-2 w-1 rounded-full bg-primary-500 mt-2"
            />
          </div>
        </div>
      </motion.div>
    </section>
  );
};

export default Hero;