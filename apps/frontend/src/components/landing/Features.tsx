'use client';

import React, { useRef } from 'react';
import { motion, useInView } from 'framer-motion';
import { 
  GraduationCap, 
  Building2, 
  UserCheck, 
  Shield,
  Calendar,
  FileText,
  Trophy,
  TrendingUp,
  CheckCircle2,
  Clock,
  Users,
  BookOpen
} from 'lucide-react';

const features = [
  {
    role: "Students",
    title: "Track Your Journey",
    description: "Submit weekly plans, upload presentations, and track your internship progress through a personalized dashboard with real-time feedback.",
    icon: GraduationCap,
    benefits: [
      "Weekly plan submissions",
      "Presentation uploads",
      "Real-time feedback",
      "Progress tracking"
    ],
    color: "primary",
    gradient: "from-primary-500 to-primary-700"
  },
  {
    role: "Coordinators",
    title: "Seamless Placement",
    description: "Easily match students with verified companies and manage thousands of placements with comprehensive institutional oversight and analytics.",
    icon: Building2,
    benefits: [
      "Student registration",
      "Company matching",
      "Placement tracking",
      "Analytics dashboard"
    ],
    color: "success",
    gradient: "from-success-500 to-success-700"
  },
  {
    role: "Supervisors",
    title: "Digital Evaluation",
    description: "Review weekly tasks, mark attendance, and generate officially stamped final performance reports with just a few clicks.",
    icon: UserCheck,
    benefits: [
      "Weekly plan review",
      "Attendance tracking",
      "Performance evaluation",
      "Stamped reports"
    ],
    color: "warning",
    gradient: "from-warning-500 to-warning-700"
  },
  {
    role: "Admin",
    title: "System Control",
    description: "Manage university settings, onboard new companies, verify institutions, and ensure data integrity across the entire ecosystem.",
    icon: Shield,
    benefits: [
      "Institution verification",
      "User management",
      "System monitoring",
      "Data security"
    ],
    color: "info",
    gradient: "from-info-500 to-info-700"
  }
];

const stats = [
  { icon: Users, value: "15+", label: "Universities", color: "primary" },
  { icon: Building2, value: "50+", label: "Companies", color: "success" },
  { icon: GraduationCap, value: "2,000+", label: "Students", color: "warning" },
  { icon: FileText, value: "98%", label: "Satisfaction", color: "info" }
];

const FeatureCard = ({ feature, index }: { feature: typeof features[0], index: number }) => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, amount: 0.3 });
  
  const Icon = feature.icon;
  
  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 30 }}
      animate={isInView ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.5, delay: index * 0.1 }}
      whileHover={{ y: -8 }}
      className="group relative bg-white rounded-2xl shadow-card hover:shadow-card-hover transition-all duration-300"
    >
      {/* Decorative gradient border */}
      <div className={`absolute inset-0 rounded-2xl bg-gradient-to-r ${feature.gradient} opacity-0 group-hover:opacity-100 transition-opacity duration-300 blur-xl -z-10`} />
      
      <div className="p-8">
        {/* Icon with animated background */}
        <div className={`relative mb-6`}>
          <div className={`absolute inset-0 bg-${feature.color}-100 rounded-xl blur-lg opacity-50 group-hover:opacity-75 transition-opacity`} />
          <div className={`relative w-14 h-14 rounded-xl bg-gradient-to-br ${feature.gradient} flex items-center justify-center shadow-lg transform group-hover:scale-110 transition-transform duration-300`}>
            <Icon className="w-7 h-7 text-white" />
          </div>
        </div>
        
        {/* Role Badge */}
        <div className="mb-4">
          <span className={`inline-flex items-center rounded-full bg-${feature.color}-50 px-3 py-1 text-xs font-medium text-${feature.color}-700 ring-1 ring-inset ring-${feature.color}-600/20`}>
            {feature.role}
          </span>
        </div>
        
        {/* Title */}
        <h3 className="text-xl font-bold text-slate-900 mb-3">
          {feature.title}
        </h3>
        
        {/* Description */}
        <p className="text-slate-600 text-sm leading-relaxed mb-6">
          {feature.description}
        </p>
        
        {/* Benefits List */}
        <div className="space-y-2">
          {feature.benefits.map((benefit, idx) => (
            <div key={idx} className="flex items-center gap-2 text-sm text-slate-600">
              <CheckCircle2 className={`w-4 h-4 text-${feature.color}-500 flex-shrink-0`} />
              <span>{benefit}</span>
            </div>
          ))}
        </div>
        
        {/* Hover Action */}
        <div className="mt-6 pt-4 border-t border-slate-100">
          <button className={`text-${feature.color}-600 text-sm font-semibold inline-flex items-center gap-1 group-hover:gap-2 transition-all`}>
            Learn more
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>
      </div>
    </motion.div>
  );
};

const Features = () => {
  const headerRef = useRef(null);
  const isHeaderInView = useInView(headerRef, { once: true });

  return (
    <section id="features" className="relative bg-gradient-to-b from-slate-50 to-white py-24 sm:py-32 overflow-hidden">
      {/* Background decoration */}
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-primary-100/30 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-success-100/20 rounded-full blur-3xl" />
      </div>
      
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <motion.div
          ref={headerRef}
          initial={{ opacity: 0, y: 20 }}
          animate={isHeaderInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5 }}
          className="text-center max-w-3xl mx-auto mb-16"
        >
          {/* Eyebrow */}
          <div className="inline-flex items-center rounded-full bg-primary-50 px-4 py-1.5 text-sm font-medium text-primary-700 ring-1 ring-inset ring-primary-600/20 mb-6">
            <TrendingUp className="w-4 h-4 mr-2" />
            The Complete Workflow
          </div>
          
          {/* Title */}
          <h2 className="text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl lg:text-5xl">
            One Platform,
            <span className="bg-gradient-to-r from-primary-600 to-primary-800 bg-clip-text text-transparent"> Four Unified Roles</span>
          </h2>
          
          {/* Description */}
          <p className="mt-6 text-lg leading-relaxed text-slate-600">
            InternLink connects every stakeholder in the internship lifecycle, replacing manual paperwork 
            with a secure, automated digital workflow that saves time and ensures accuracy.
          </p>
        </motion.div>

        {/* Stats Bar */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={isHeaderInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="mb-20"
        >
          <div className="bg-white rounded-2xl border border-slate-200 shadow-soft p-6">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
              {stats.map((stat, idx) => {
                const Icon = stat.icon;
                return (
                  <div key={idx} className="text-center">
                    <div className={`inline-flex items-center justify-center w-12 h-12 rounded-xl bg-${stat.color}-50 mb-3`}>
                      <Icon className={`w-6 h-6 text-${stat.color}-600`} />
                    </div>
                    <p className="text-2xl font-bold text-slate-900">{stat.value}</p>
                    <p className="text-sm text-slate-500">{stat.label}</p>
                  </div>
                );
              })}
            </div>
          </div>
        </motion.div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {features.map((feature, index) => (
            <FeatureCard key={feature.role} feature={feature} index={index} />
          ))}
        </div>

       
      </div>
    </section>
  );
};

export default Features;