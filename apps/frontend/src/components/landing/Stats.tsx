'use client';

import React, { useRef, useState, useEffect } from 'react';
import { motion, useInView } from 'framer-motion';
import { Users, Building2, GraduationCap, FileText } from 'lucide-react';

const stats = [
  { id: 1, name: 'Active Students', value: '2,500+', target: 2500, icon: Users, color: 'primary' },
  { id: 2, name: 'Industry Partners', value: '85+', target: 85, icon: Building2, color: 'success' },
  { id: 3, name: 'University Departments', value: '12+', target: 12, icon: GraduationCap, color: 'warning' },
  { id: 4, name: 'Reports Generated', value: '10k+', target: 10000, icon: FileText, color: 'info' },
];

const statColorStyles = {
  primary: { box: 'bg-primary-500/10', icon: 'text-primary-400' },
  success: { box: 'bg-success-500/10', icon: 'text-success-400' },
  warning: { box: 'bg-warning-500/10', icon: 'text-warning-400' },
  info: { box: 'bg-info-500/10', icon: 'text-info-400' },
} as const;

const CountUp = ({ target, suffix }: { target: number; suffix: string }) => {
  const [count, setCount] = useState(0);
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });

  useEffect(() => {
    if (isInView) {
      let start = 0;
      const duration = 2000;
      const step = target / (duration / 16);
      
      const timer = setInterval(() => {
        start += step;
        if (start >= target) {
          setCount(target);
          clearInterval(timer);
        } else {
          setCount(Math.floor(start));
        }
      }, 16);
      
      return () => clearInterval(timer);
    }
  }, [isInView, target]);

  return <span ref={ref}>{count}{suffix}</span>;
};

const Stats = () => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });

  return (
    <section className="bg-gradient-to-b from-slate-900 to-slate-800 py-20 sm:py-24 lg:py-28">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-12">
          <span className="inline-flex items-center rounded-full bg-primary-500/10 px-3 py-1 text-sm font-medium text-primary-400 mb-4">
            Real-Time Impact
          </span>
          <h2 className="text-3xl font-bold text-white sm:text-4xl">
            Trusted by the Academic Community
          </h2>
          <p className="mt-4 text-lg text-slate-300">
            InternLink is rapidly becoming the standard for internship management
          </p>
        </div>

        <div ref={ref} className="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-6 lg:grid-cols-4">
          {stats.map((stat, index) => {
            const Icon = stat.icon;
            const styles = statColorStyles[stat.color as keyof typeof statColorStyles] || statColorStyles.primary;
            return (
              <motion.div
                key={stat.id}
                initial={{ opacity: 0, y: 20 }}
                animate={isInView ? { opacity: 1, y: 0 } : {}}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                className="rounded-2xl border border-white/10 bg-white/5 p-6 text-center transition-all hover:bg-white/10"
              >
                <div className={`mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-xl ${styles.box}`}>
                  <Icon className={`h-6 w-6 ${styles.icon}`} />
                </div>
                <p className="text-3xl font-bold text-white mb-1">
                  <CountUp target={stat.target} suffix={stat.value.includes('+') ? '+' : ''} />
                </p>
                <p className="text-sm text-slate-400">{stat.name}</p>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
};

export default Stats;