'use client';

import React, { useState, useRef, useEffect } from 'react';
import { motion, useInView, AnimatePresence } from 'framer-motion';
import { 
  Star, 
  Quote, 
  ChevronLeft, 
  ChevronRight,
  Award,
  CheckCircle2,
  TrendingUp,
  Users,
  Calendar,
  MessageSquare
} from 'lucide-react';

const testimonials = [
  {
    id: 1,
    content: "InternLink transformed how we manage 500+ students. The digital verification of company proposals saved us weeks of manual paperwork. The automated reporting system has been a game-changer for our department.",
    author: "Dr. Abadanaf G.",
    role: "University Coordinator",
    university: "Haramaya University",
    avatar: "AG",
    rating: 5,
    date: "March 2024",
    category: "coordinator",
    metric: "500+ Students Managed",
    metricIcon: Users
  },
  {
    id: 2,
    content: "The weekly plan submission is so smooth. I love that I can see my evaluation status in real-time without having to call my supervisor. It's made my internship experience so much more organized and stress-free.",
    author: "Ayana F.",
    role: "Software Engineering Student",
    university: "HU - 5th Year",
    avatar: "AF",
    rating: 5,
    date: "February 2024",
    category: "student",
    metric: "Real-time Updates",
    metricIcon: MessageSquare
  },
  {
    id: 3,
    content: "Reviewing intern performance is now a 1-click process. Generating the final stamped report used to be a headache; now it's automatic. This platform has revolutionized our internship program.",
    author: "Amanuel T.",
    role: "Senior Developer / Supervisor",
    university: "Pixel Addis Solutions",
    avatar: "AT",
    rating: 5,
    date: "January 2024",
    category: "supervisor",
    metric: "100% Digital Workflow",
    metricIcon: CheckCircle2
  },
  {
    id: 4,
    content: "The analytics dashboard gives me real-time insights into student performance. I can track progress across multiple departments and identify areas for improvement instantly.",
    author: "Bana D.",
    role: "Internship Coordinator",
    university: "Addis Ababa University",
    avatar: "BD",
    rating: 5,
    date: "March 2024",
    category: "coordinator",
    metric: "Real-time Analytics",
    metricIcon: TrendingUp
  },
  {
    id: 5,
    content: "My students adapted to the platform within days. The interface is intuitive and the feedback system is excellent. Highly recommended for any university.",
    author: "Amanuel A.",
    role: "Department Head",
    university: "Bahir Dar University",
    avatar: "AA",
    rating: 5,
    date: "February 2024",
    category: "coordinator",
    metric: "Easy Adoption",
    metricIcon: Award
  }
];

const StarRating = ({ rating }: { rating: number }) => {
  return (
    <div className="flex gap-0.5">
      {[...Array(5)].map((_, i) => (
        <Star
          key={i}
          className={`w-4 h-4 ${
            i < rating ? 'text-warning-500 fill-warning-500' : 'text-slate-200'
          }`}
        />
      ))}
    </div>
  );
};

const TestimonialCard = ({ testimonial, index }: { testimonial: typeof testimonials[0], index: number }) => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, amount: 0.3 });
  const MetricIcon = testimonial.metricIcon;

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 30 }}
      animate={isInView ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.5, delay: index * 0.1 }}
      whileHover={{ y: -8 }}
      className="group relative"
    >
      <div className="relative h-full bg-white rounded-2xl shadow-card hover:shadow-card-hover transition-all duration-300 overflow-hidden border border-slate-100">
        {/* Gradient Border Effect */}
        <div className="absolute inset-0 bg-gradient-to-r from-primary-500/0 via-primary-500/5 to-primary-500/0 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
        
        {/* Quote Icon */}
        <div className="absolute top-6 right-6 opacity-10 group-hover:opacity-20 transition-opacity">
          <Quote className="w-12 h-12 text-slate-400" />
        </div>
        
        <div className="p-6 md:p-8">
          {/* Rating and Date */}
          <div className="flex items-center justify-between mb-4">
            <StarRating rating={testimonial.rating} />
            <span className="text-xs text-slate-400">{testimonial.date}</span>
          </div>
          
          {/* Content */}
          <blockquote className="text-slate-600 text-base leading-relaxed mb-6 relative z-10 line-clamp-4">
            “{testimonial.content}”
          </blockquote>
          
          {/* Metric Badge */}
          <div className="inline-flex items-center gap-1.5 rounded-full bg-primary-50 px-2.5 py-1 mb-4">
            <MetricIcon className="w-3.5 h-3.5 text-primary-600" />
            <span className="text-xs font-medium text-primary-700">
              {testimonial.metric}
            </span>
          </div>
          
          {/* Author Info */}
          <div className="flex items-center gap-4 mt-4 pt-4 border-t border-slate-100">
            <div className="relative">
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-primary-500 to-primary-700 flex items-center justify-center text-white font-bold shadow-md">
                {testimonial.avatar}
              </div>
              <div className="absolute -bottom-1 -right-1 w-4 h-4 rounded-full bg-success-500 border-2 border-white" />
            </div>
            <div className="flex-1">
              <div className="text-sm font-bold text-slate-900">{testimonial.author}</div>
              <div className="text-xs text-primary-600 font-medium">{testimonial.role}</div>
              <div className="text-xs text-slate-400">{testimonial.university}</div>
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  );
};

const Testimonials = () => {
  const headerRef = useRef(null);
  const isHeaderInView = useInView(headerRef, { once: true });
  const [activeCategory, setActiveCategory] = useState('all');
  const [currentPage, setCurrentPage] = useState(0);
  const itemsPerPage = 3;
  
  const categories = [
    { id: 'all', label: 'All Reviews', icon: Star },
    { id: 'coordinator', label: 'Coordinators', icon: Users },
    { id: 'student', label: 'Students', icon: MessageSquare },
    { id: 'supervisor', label: 'Supervisors', icon: CheckCircle2 }
  ];

  const filteredTestimonials = activeCategory === 'all' 
    ? testimonials 
    : testimonials.filter(t => t.category === activeCategory);
  
  const totalPages = Math.ceil(filteredTestimonials.length / itemsPerPage);
  const currentTestimonials = filteredTestimonials.slice(
    currentPage * itemsPerPage,
    (currentPage + 1) * itemsPerPage
  );

  // Reset page when category changes
  useEffect(() => {
    setCurrentPage(0);
  }, [activeCategory]);

  const overallRating = (testimonials.reduce((acc, t) => acc + t.rating, 0) / testimonials.length).toFixed(1);

  return (
    <section id="testimonials" className="relative bg-gradient-to-b from-white to-slate-50 py-24 sm:py-32 overflow-hidden">
      {/* Background Decoration */}
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-0 right-0 w-96 h-96 bg-primary-100/20 rounded-full blur-3xl" />
        <div className="absolute bottom-0 left-0 w-96 h-96 bg-success-100/20 rounded-full blur-3xl" />
        <div className="absolute inset-0 bg-[radial-gradient(#e2e8f0_1px,transparent_1px)] bg-[size:20px_20px] [mask-image:radial-gradient(ellipse_80%_50%_at_50%_50%,#000_60%,transparent_100%)]" />
      </div>

      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <motion.div
          ref={headerRef}
          initial={{ opacity: 0, y: 20 }}
          animate={isHeaderInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5 }}
          className="text-center max-w-3xl mx-auto mb-12"
        >
          {/* Badge */}
          <div className="inline-flex items-center rounded-full bg-primary-50 px-4 py-1.5 text-sm font-medium text-primary-700 ring-1 ring-inset ring-primary-600/20 mb-6">
            <Star className="w-4 h-4 mr-2 fill-primary-600 text-primary-600" />
            {overallRating} / 5.0 Rating
          </div>
          
          <h2 className="text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl lg:text-5xl">
            Trusted by{' '}
            <span className="bg-gradient-to-r from-primary-600 to-primary-800 bg-clip-text text-transparent">
              Students & Professionals
            </span>
          </h2>
          
          <p className="mt-4 text-lg leading-relaxed text-slate-600">
            Join hundreds of satisfied users who have transformed their internship management experience
          </p>
        </motion.div>

        {/* Rating Summary */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={isHeaderInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="mb-12 flex flex-col items-center justify-center gap-4 sm:flex-row sm:gap-8"
        >
          <div className="flex items-center gap-3">
            <div className="text-4xl font-bold text-slate-900">{overallRating}</div>
            <div>
              <StarRating rating={5} />
              <p className="text-xs text-slate-500">Based on {testimonials.length} reviews</p>
            </div>
          </div>
          <div className="hidden sm:block h-8 w-px bg-slate-200" />
          <div className="flex items-center gap-2">
            <div className="flex -space-x-2">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="w-8 h-8 rounded-full bg-gradient-to-br from-slate-300 to-slate-400 ring-2 ring-white" />
              ))}
            </div>
            <span className="text-sm text-slate-600">
              <span className="font-semibold text-primary-600">500+</span> active users
            </span>
          </div>
        </motion.div>

        {/* Category Filter */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={isHeaderInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="flex flex-wrap items-center justify-center gap-2 mb-12"
        >
          {categories.map((category) => {
            const Icon = category.icon;
            const isActive = activeCategory === category.id;
            return (
              <button
                key={category.id}
                onClick={() => setActiveCategory(category.id)}
                className={`inline-flex items-center gap-2 rounded-full px-4 py-2 text-sm font-medium transition-all duration-200 ${
                  isActive
                    ? 'bg-primary-600 text-white shadow-md'
                    : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
                }`}
              >
                <Icon className="w-4 h-4" />
                {category.label}
              </button>
            );
          })}
        </motion.div>

        {/* Testimonials Grid */}
        <AnimatePresence mode="wait">
          <motion.div
            key={activeCategory}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.3 }}
            className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 lg:gap-8"
          >
            {currentTestimonials.map((testimonial, index) => (
              <TestimonialCard key={testimonial.id} testimonial={testimonial} index={index} />
            ))}
          </motion.div>
        </AnimatePresence>

        {/* Pagination Controls */}
        {totalPages > 1 && (
          <div className="flex justify-center items-center gap-2 mt-12">
            <button
              onClick={() => setCurrentPage(prev => Math.max(0, prev - 1))}
              disabled={currentPage === 0}
              className="p-2 rounded-lg border border-slate-200 bg-white text-slate-600 hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>
            <div className="flex gap-2">
              {[...Array(totalPages)].map((_, idx) => (
                <button
                  key={idx}
                  onClick={() => setCurrentPage(idx)}
                  className={`transition-all ${
                    currentPage === idx
                      ? 'w-6 h-2 bg-primary-600 rounded-full'
                      : 'w-2 h-2 bg-slate-300 rounded-full hover:bg-slate-400'
                  }`}
                />
              ))}
            </div>
            <button
              onClick={() => setCurrentPage(prev => Math.min(totalPages - 1, prev + 1))}
              disabled={currentPage === totalPages - 1}
              className="p-2 rounded-lg border border-slate-200 bg-white text-slate-600 hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronRight className="w-5 h-5" />
            </button>
          </div>
        )}

        {/* CTA to Leave Review */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={isHeaderInView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.5, delay: 0.6 }}
          className="mt-12 text-center"
        >
          <div className="inline-flex items-center gap-2 bg-white rounded-full px-4 py-2 shadow-soft border border-slate-100">
            <MessageSquare className="w-4 h-4 text-primary-600" />
            <span className="text-sm text-slate-600">Share your experience</span>
            <button className="text-sm font-medium text-primary-600 hover:text-primary-700 transition-colors">
              Write a review
            </button>
          </div>
        </motion.div>
      </div>
    </section>
  );
};

export default Testimonials;