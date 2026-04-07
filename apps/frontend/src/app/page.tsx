'use client';

import { useEffect } from 'react';
import Navbar from '../components/shared/Navbar';
import Hero from '../components/landing/Hero';
import Features from '../components/landing/Features';
import HowItWorks from '../components/landing/HowItWorks';
import Stats from '../components/landing/Stats';
import CTASection from '../components/landing/CTASection';
import Testimonials from '../components/landing/Testimonials';
import Footer from '../components/shared/Footer';
import AiChatFloating from '../components/ai/AiChatFloating';

export default function Home() {
  // Smooth scroll handling for anchor links
  useEffect(() => {
    const handleAnchorClick = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      const anchor = target.closest('a');
      
      if (anchor?.hash && anchor.hash.startsWith('#') && anchor.pathname === window.location.pathname) {
        e.preventDefault();
        const element = document.querySelector(anchor.hash);
        if (element) {
          const offset = 80; // Navbar height
          const elementPosition = element.getBoundingClientRect().top;
          const offsetPosition = elementPosition + window.pageYOffset - offset;
          
          window.scrollTo({
            top: offsetPosition,
            behavior: 'smooth'
          });
          
          // Update URL without jumping
          window.history.pushState(null, '', anchor.hash);
        }
      }
    };

    document.addEventListener('click', handleAnchorClick);
    return () => document.removeEventListener('click', handleAnchorClick);
  }, []);

  return (
    <div className="min-h-screen bg-white">
      <Navbar />
      
      {/* Main Content */}
      <main>
        {/* Hero Section - Full height on desktop */}
        <section id="home" className="relative">
          <Hero />
        </section>

        {/* Features Section */}
        <section id="features" className="scroll-mt-20">
          <Features />
        </section>

        {/* How It Works Section */}
        <section id="how-it-works" className="scroll-mt-20 bg-slate-50">
          <HowItWorks />
        </section>

        {/* Stats Section */}
        <section id="stats" className="scroll-mt-20">
          <Stats />
        </section>

        {/* Testimonials Section */}
        <section id="testimonials" className="scroll-mt-20 bg-slate-50">
          <Testimonials />
        </section>

        {/* CTA Section */}
        <section id="get-started" className="scroll-mt-20">
          <CTASection />
        </section>
      </main>

      {/* Footer */}
      <Footer />

      {/* Floating AI Chatbot */}
      <AiChatFloating role="visitor" />
    </div>
  );
}