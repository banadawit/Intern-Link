'use client';

import React, { useRef } from 'react';
import { motion, useInView } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { GraduationCap, Building2, UserCheck, Shield, FileText, TrendingUp, CheckCircle2, Users } from 'lucide-react';

const colorStyles = {
  primary: { badge: "bg-teal-50 text-teal-700 ring-teal-600/20", iconGlow: "bg-teal-100", check: "text-teal-500", action: "text-teal-700", statIconBox: "bg-teal-50", statIcon: "text-teal-600", hoverTint: "from-teal-50/80 via-transparent to-white", hoverRing: "group-hover:ring-teal-300/60", iconGradient: "from-teal-500 to-teal-700", borderTop: "from-teal-400 to-teal-600" },
  success: { badge: "bg-green-50 text-green-700 ring-green-600/20", iconGlow: "bg-green-100", check: "text-green-500", action: "text-green-700", statIconBox: "bg-green-50", statIcon: "text-green-600", hoverTint: "from-green-50/70 via-transparent to-white", hoverRing: "group-hover:ring-green-300/60", iconGradient: "from-green-500 to-green-700", borderTop: "from-green-400 to-green-600" },
  warning: { badge: "bg-yellow-50 text-yellow-700 ring-yellow-600/20", iconGlow: "bg-yellow-100", check: "text-yellow-500", action: "text-yellow-700", statIconBox: "bg-yellow-50", statIcon: "text-yellow-600", hoverTint: "from-yellow-50/75 via-transparent to-white", hoverRing: "group-hover:ring-yellow-300/60", iconGradient: "from-yellow-500 to-amber-600", borderTop: "from-yellow-400 to-amber-500" },
  info: { badge: "bg-blue-50 text-blue-700 ring-blue-600/20", iconGlow: "bg-blue-100", check: "text-blue-500", action: "text-blue-700", statIconBox: "bg-blue-50", statIcon: "text-blue-600", hoverTint: "from-blue-50/75 via-transparent to-white", hoverRing: "group-hover:ring-blue-300/60", iconGradient: "from-blue-500 to-blue-700", borderTop: "from-blue-400 to-blue-600" },
} as const;

const Features = () => {
  const t = useTranslations('Features');
  const headerRef = useRef(null);
  const isHeaderInView = useInView(headerRef, { once: true });

  const features = [
    { roleKey: 'students',     titleKey: 'studentsTitle',     descKey: 'studentsDesc',     benefitsKey: 'studentsBenefits',     icon: GraduationCap, color: 'primary'  as const },
    { roleKey: 'coordinators', titleKey: 'coordinatorsTitle', descKey: 'coordinatorsDesc', benefitsKey: 'coordinatorsBenefits', icon: Building2,     color: 'success'  as const },
    { roleKey: 'supervisors',  titleKey: 'supervisorsTitle',  descKey: 'supervisorsDesc',  benefitsKey: 'supervisorsBenefits',  icon: UserCheck,     color: 'warning'  as const },
    { roleKey: 'admin',        titleKey: 'adminTitle',        descKey: 'adminDesc',        benefitsKey: 'adminBenefits',        icon: Shield,        color: 'info'     as const },
  ];

  const stats = [
    { icon: Users,         value: '15+',    labelKey: 'universities', color: 'primary'  as const },
    { icon: Building2,     value: '50+',    labelKey: 'companies',    color: 'success'  as const },
    { icon: GraduationCap, value: '2,000+', labelKey: 'students',     color: 'warning'  as const },
    { icon: FileText,      value: '98%',    labelKey: 'satisfaction', color: 'info'     as const },
  ];

  return (
    <section id="features" className="relative overflow-hidden bg-gradient-to-b from-slate-50 to-white py-20 sm:py-24 lg:py-28 dark:from-slate-900 dark:to-slate-950">
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-primary-100/30 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-success-100/20 rounded-full blur-3xl" />
      </div>

      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <motion.div
          ref={headerRef}
          initial={{ opacity: 0, y: 20 }}
          animate={isHeaderInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5 }}
          className="mx-auto mb-12 max-w-3xl text-center sm:mb-16"
        >
          <div className="inline-flex items-center rounded-full bg-primary-50 px-4 py-1.5 text-sm font-medium text-primary-700 ring-1 ring-inset ring-primary-600/20 mb-6">
            <TrendingUp className="w-4 h-4 mr-2" />
            {t('badge')}
          </div>
          <h2 className="text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl lg:text-5xl dark:text-slate-100">
            {t('title')}
            <span className="bg-gradient-to-r from-primary-600 to-primary-800 bg-clip-text text-transparent"> {t('titleHighlight')}</span>
          </h2>
          <p className="mt-6 text-lg leading-relaxed text-slate-600 dark:text-slate-300">{t('subtitle')}</p>
        </motion.div>

        {/* Stats Bar */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={isHeaderInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="mb-20"
        >
          <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft sm:p-6 dark:border-slate-700 dark:bg-slate-900">
            <div className="grid grid-cols-2 gap-4 sm:gap-6 md:grid-cols-4">
              {stats.map((stat, idx) => {
                const Icon = stat.icon;
                const s = colorStyles[stat.color];
                return (
                  <div key={idx} className="text-center">
                    <div className={`mb-3 inline-flex h-12 w-12 items-center justify-center rounded-xl ${s.statIconBox}`}>
                      <Icon className={`h-6 w-6 ${s.statIcon}`} />
                    </div>
                    <p className="text-2xl font-bold text-slate-900 dark:text-slate-100">{stat.value}</p>
                    <p className="text-sm text-slate-500 dark:text-slate-400">{t(`stats.${stat.labelKey}`)}</p>
                  </div>
                );
              })}
            </div>
          </div>
        </motion.div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 gap-6 sm:gap-8 md:grid-cols-2 lg:grid-cols-4">
          {features.map((feature, index) => {
            const Icon = feature.icon;
            const s = colorStyles[feature.color];
            const benefits = t.raw(`roles.${feature.benefitsKey}`) as string[];
            return (
              <motion.div
                key={feature.roleKey}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                whileHover={{ y: -10, scale: 1.01 }}
                className={`group relative overflow-hidden rounded-2xl bg-white shadow-card ring-1 ring-slate-200 transition-all duration-300 hover:shadow-card-hover dark:bg-slate-900 dark:ring-slate-700 ${s.hoverRing}`}
              >
                <div className={`absolute inset-x-0 top-0 h-1 bg-gradient-to-r ${s.borderTop}`} />
                <div className="p-8">
                  <div className="relative mb-6">
                    <div className={`absolute inset-0 rounded-xl blur-lg opacity-50 ${s.iconGlow}`} />
                    <div className={`relative w-14 h-14 rounded-xl bg-gradient-to-br ${s.iconGradient} flex items-center justify-center shadow-lg transform transition-transform duration-300 group-hover:scale-110 group-hover:rotate-3`}>
                      <Icon className="w-7 h-7 text-white" />
                    </div>
                  </div>
                  <div className="mb-4">
                    <span className={`inline-flex items-center rounded-full px-3 py-1 text-xs font-medium ring-1 ring-inset ${s.badge}`}>
                      {t(`roles.${feature.roleKey}`)}
                    </span>
                  </div>
                  <h3 className="text-xl font-bold text-slate-900 mb-3 dark:text-slate-100">
                    {t(`roles.${feature.titleKey}`)}
                  </h3>
                  <p className="text-slate-600 text-sm leading-relaxed mb-6 dark:text-slate-300">
                    {t(`roles.${feature.descKey}`)}
                  </p>
                  <div className="space-y-2">
                    {Array.isArray(benefits) && benefits.map((benefit: string, idx: number) => (
                      <div key={idx} className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-300">
                        <CheckCircle2 className={`h-4 w-4 flex-shrink-0 ${s.check}`} />
                        <span>{benefit}</span>
                      </div>
                    ))}
                  </div>
                  <div className="mt-6 pt-4 border-t border-slate-100 dark:border-slate-800">
                    <button className={`inline-flex items-center gap-1 text-sm font-semibold transition-all group-hover:gap-2 ${s.action}`}>
                      {t('learnMore')}
                      <svg className="w-4 h-4 transition-transform group-hover:translate-x-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                      </svg>
                    </button>
                  </div>
                </div>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
};

export default Features;
