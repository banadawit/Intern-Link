'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { Building2, Users, FileCheck, Trophy, ArrowRight } from 'lucide-react';

const stepColors = {
  primary: { iconWrap: "bg-primary-50 border-primary-200", icon: "text-primary-600", badge: "bg-primary-50 text-primary-700" },
  success: { iconWrap: "bg-success-50 border-success-200", icon: "text-success-600", badge: "bg-success-50 text-success-700" },
  warning: { iconWrap: "bg-warning-50 border-warning-200", icon: "text-warning-600", badge: "bg-warning-50 text-warning-700" },
  info:    { iconWrap: "bg-info-50 border-info-200",       icon: "text-info-600",    badge: "bg-info-50 text-info-700"       },
} as const;

const HowItWorks = () => {
  const t = useTranslations('HowItWorks');

  const steps = [
    { id: '01', nameKey: 'step1', descKey: 'step1Desc', icon: Building2, color: 'primary'  as const },
    { id: '02', nameKey: 'step2', descKey: 'step2Desc', icon: Users,     color: 'success'  as const },
    { id: '03', nameKey: 'step3', descKey: 'step3Desc', icon: FileCheck, color: 'warning'  as const },
    { id: '04', nameKey: 'step4', descKey: 'step4Desc', icon: Trophy,    color: 'info'     as const },
  ];

  return (
    <section id="how-it-works" className="bg-white py-20 sm:py-24 lg:py-28 dark:bg-slate-950">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mx-auto mb-12 max-w-2xl text-center sm:mb-16">
          <span className="inline-flex items-center rounded-full bg-primary-50 px-3 py-1 text-sm font-medium text-primary-700 ring-1 ring-inset ring-primary-600/20 mb-4">
            {t('badge')}
          </span>
          <h2 className="text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl dark:text-slate-100">
            {t('title')}{' '}
            <span className="text-primary-600">{t('titleHighlight')}</span>
          </h2>
          <p className="mt-4 text-lg text-slate-600 dark:text-slate-300">{t('subtitle')}</p>
        </div>

        <div className="grid grid-cols-1 gap-6 sm:gap-8 md:grid-cols-2 lg:grid-cols-4">
          {steps.map((step, index) => {
            const Icon = step.icon;
            const styles = stepColors[step.color];
            return (
              <motion.div
                key={step.id}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                className="group relative rounded-2xl border border-slate-200 bg-slate-50/50 p-5 sm:p-6 dark:border-slate-700 dark:bg-slate-900/60"
              >
                <div className="flex flex-col">
                  <div className="relative mb-6">
                    <div className={`flex h-16 w-16 items-center justify-center rounded-2xl border-2 transition-transform duration-300 group-hover:scale-110 ${styles.iconWrap}`}>
                      <Icon className={`h-8 w-8 ${styles.icon}`} />
                    </div>
                    <div className="absolute -top-2 -right-2 w-8 h-8 rounded-full bg-white border-2 border-primary-200 flex items-center justify-center text-sm font-bold text-primary-600 dark:bg-slate-900 dark:border-primary-700">
                      {index + 1}
                    </div>
                  </div>
                  <span className={`mb-3 inline-flex w-fit items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${styles.badge}`}>
                    Step {index + 1}
                  </span>
                  <h3 className="text-xl font-bold text-slate-900 mb-2 dark:text-slate-100">
                    {t(`steps.${step.nameKey}`)}
                  </h3>
                  <p className="text-slate-600 text-sm leading-relaxed dark:text-slate-300">
                    {t(`steps.${step.descKey}`)}
                  </p>
                </div>
                {index < steps.length - 1 && (
                  <div className="hidden lg:block absolute top-1/2 left-full w-full h-0.5 bg-gradient-to-r from-slate-200 to-transparent -translate-y-1/2 dark:from-slate-700" />
                )}
              </motion.div>
            );
          })}
        </div>

        <div className="mt-16 text-center">
          <a
            href="/register"
            className="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-6 py-3 text-sm font-semibold text-white hover:bg-primary-700 transition-all"
          >
            {t('badge')}
            <ArrowRight className="w-4 h-4" />
          </a>
        </div>
      </div>
    </section>
  );
};

export default HowItWorks;
