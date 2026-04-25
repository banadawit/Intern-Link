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
  primary: { box: 'bg-teal-50', icon: 'text-teal-600' },
  success: { box: 'bg-green-50', icon: 'text-green-600' },
  warning: { box: 'bg-yellow-50', icon: 'text-yellow-600' },
  info: { box: 'bg-blue-50', icon: 'text-blue-600' },
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
    <section className="bg-gradient-to-b from-teal-50 to-white py-20 sm:py-24 lg:py-28">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-12">
          <span className="mb-4 inline-flex items-center rounded-full bg-teal-100 px-3 py-1 text-sm font-medium text-teal-700">
            Real-Time Impact
          </span>
          <h2 className="text-3xl font-bold text-slate-900 sm:text-4xl">
            Trusted by the Academic Community
          </h2>
          <p className="mt-4 text-lg text-slate-600">
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
                className="rounded-2xl border border-slate-200 bg-white p-6 text-center shadow-soft transition-all hover:shadow-card-hover"
              >
                <div className={`mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-xl ${styles.box}`}>
                  <Icon className={`h-6 w-6 ${styles.icon}`} />
                </div>
                <p className="mb-1 text-3xl font-bold text-slate-900">
                  <CountUp target={stat.target} suffix={stat.value.includes('+') ? '+' : ''} />
                </p>
                <p className="text-sm text-slate-500">{stat.name}</p>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
};

export default Stats;