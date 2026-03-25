'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Building2, Users, FileCheck, Trophy, ArrowRight } from 'lucide-react';

const steps = [
  {
    id: '01',
    name: 'Institutional Onboarding',
    description: 'Universities and Companies register by uploading stamped verification proposals to ensure a secure network.',
    icon: Building2,
    color: 'primary',
  },
  {
    id: '02',
    name: 'Smart Placement',
    description: 'Coordinators match students to verified companies based on department and available internship slots.',
    icon: Users,
    color: 'success',
  },
  {
    id: '03',
    name: 'Continuous Evaluation',
    description: 'Students submit weekly plans while supervisors provide real-time feedback and attendance tracking.',
    icon: FileCheck,
    color: 'warning',
  },
  {
    id: '04',
    name: 'Certified Completion',
    description: 'Final performance reports are automatically generated with official digital stamps for academic records.',
    icon: Trophy,
    color: 'info',
  },
];

const HowItWorks = () => {
  return (
    <section id="how-it-works" className="bg-white py-24 sm:py-32">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="text-center max-w-2xl mx-auto mb-16">
          <span className="inline-flex items-center rounded-full bg-primary-50 px-3 py-1 text-sm font-medium text-primary-700 ring-1 ring-inset ring-primary-600/20 mb-4">
            The Process
          </span>
          <h2 className="text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl">
            From Registration to{' '}
            <span className="text-primary-600">Graduation</span>
          </h2>
          <p className="mt-4 text-lg text-slate-600">
            We&apos;ve simplified the internship lifecycle into four clear phases, ensuring transparency 
            for students and efficiency for coordinators.
          </p>
        </div>

        {/* Steps */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {steps.map((step, index) => {
            const Icon = step.icon;
            return (
              <motion.div
                key={step.id}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                className="relative group"
              >
                <div className="flex flex-col">
                  {/* Step Number with Icon */}
                  <div className="relative mb-6">
                    <div className={`w-16 h-16 rounded-2xl bg-${step.color}-50 flex items-center justify-center border-2 border-${step.color}-200 group-hover:scale-110 transition-transform duration-300`}>
                      <Icon className={`w-8 h-8 text-${step.color}-600`} />
                    </div>
                    <div className="absolute -top-2 -right-2 w-8 h-8 rounded-full bg-white border-2 border-primary-200 flex items-center justify-center text-sm font-bold text-primary-600">
                      {index + 1}
                    </div>
                  </div>
                  
                  {/* Content */}
                  <span className={`inline-flex items-center rounded-full bg-${step.color}-50 px-2.5 py-0.5 text-xs font-medium text-${step.color}-700 mb-3 w-fit`}>
                    Step {index + 1}
                  </span>
                  <h3 className="text-xl font-bold text-slate-900 mb-2">
                    {step.name}
                  </h3>
                  <p className="text-slate-600 text-sm leading-relaxed">
                    {step.description}
                  </p>
                </div>

                {/* Connector */}
                {index < steps.length - 1 && (
                  <div className="hidden lg:block absolute top-1/2 left-full w-full h-0.5 bg-gradient-to-r from-slate-200 to-transparent -translate-y-1/2" />
                )}
              </motion.div>
            );
          })}
        </div>

        {/* CTA */}
        <div className="mt-16 text-center">
          <button className="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-6 py-3 text-sm font-semibold text-white hover:bg-primary-700 transition-all">
            Get Started
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </section>
  );
};

export default HowItWorks;