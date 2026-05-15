import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Terms of Service — InternLink",
  description: "Read the InternLink Terms of Service governing your use of the platform.",
};

const LAST_UPDATED = "May 15, 2026";

export default function TermsOfServicePage() {
  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-800 dark:text-slate-200">
      {/* Header */}
      <header className="border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900">
        <div className="mx-auto max-w-4xl px-6 py-5 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2 text-teal-600 dark:text-teal-400 font-bold text-xl tracking-tight">
            InternLink
          </Link>
          <nav className="flex items-center gap-6 text-sm text-slate-500 dark:text-slate-400">
            <Link href="/privacy" className="hover:text-teal-600 dark:hover:text-teal-400 transition-colors">Privacy Policy</Link>
            <Link href="/" className="hover:text-teal-600 dark:hover:text-teal-400 transition-colors">Back to Home</Link>
          </nav>
        </div>
      </header>

      {/* Hero */}
      <div className="bg-gradient-to-br from-teal-600 to-teal-800 dark:from-teal-800 dark:to-teal-950 text-white">
        <div className="mx-auto max-w-4xl px-6 py-16">
          <p className="text-teal-200 text-sm font-semibold uppercase tracking-widest mb-3">Legal</p>
          <h1 className="text-4xl font-bold mb-4">Terms of Service</h1>
          <p className="text-teal-100 text-lg max-w-2xl">
            Please read these terms carefully before using InternLink. By accessing or using our platform, you agree to be bound by these terms.
          </p>
          <p className="mt-6 text-teal-200 text-sm">Last updated: {LAST_UPDATED}</p>
        </div>
      </div>

      {/* Content */}
      <main className="mx-auto max-w-4xl px-6 py-14 space-y-12">

        <Section title="1. Acceptance of Terms">
          <p>
            By registering for, accessing, or using the InternLink platform ("Service"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, you may not access or use the Service. These Terms apply to all users, including students, supervisors, coordinators, heads of department, and administrators.
          </p>
        </Section>

        <Section title="2. Description of Service">
          <p>
            InternLink is an internship management platform designed to facilitate the coordination, supervision, and tracking of student internship programs between universities and companies. The Service provides tools for internship placement, weekly reporting, evaluations, document management, and communication between all stakeholders.
          </p>
        </Section>

        <Section title="3. User Accounts and Registration">
          <p>To use InternLink, you must create an account. You agree to:</p>
          <ul>
            <li>Provide accurate, current, and complete information during registration.</li>
            <li>Maintain and promptly update your account information.</li>
            <li>Keep your password confidential and not share it with any third party.</li>
            <li>Notify us immediately of any unauthorized use of your account.</li>
            <li>Accept responsibility for all activities that occur under your account.</li>
          </ul>
          <p className="mt-4">
            Accounts are subject to approval by platform administrators. InternLink reserves the right to suspend or terminate accounts that violate these Terms or are found to contain false information.
          </p>
        </Section>

        <Section title="4. User Roles and Responsibilities">
          <p>InternLink serves multiple user roles, each with specific responsibilities:</p>
          <ul>
            <li><strong>Students</strong> must submit accurate weekly plans, reports, and evaluations in a timely manner.</li>
            <li><strong>Supervisors</strong> are responsible for overseeing student interns, providing feedback, and submitting evaluations honestly.</li>
            <li><strong>Coordinators</strong> are responsible for managing internship placements and ensuring compliance with university requirements.</li>
            <li><strong>Heads of Department (HOD)</strong> oversee the academic integrity of the internship program within their department.</li>
            <li><strong>Administrators</strong> manage platform access, approve institutions, and maintain system integrity.</li>
          </ul>
        </Section>

        <Section title="5. Acceptable Use">
          <p>You agree not to use the Service to:</p>
          <ul>
            <li>Upload, post, or transmit any content that is unlawful, harmful, defamatory, or fraudulent.</li>
            <li>Impersonate any person or entity or misrepresent your affiliation with any person or entity.</li>
            <li>Interfere with or disrupt the integrity or performance of the Service.</li>
            <li>Attempt to gain unauthorized access to any part of the Service or its related systems.</li>
            <li>Use the Service for any commercial purpose not expressly permitted by InternLink.</li>
            <li>Harvest or collect personal information about other users without their consent.</li>
          </ul>
        </Section>

        <Section title="6. Intellectual Property">
          <p>
            The Service and its original content, features, and functionality are and will remain the exclusive property of InternLink and its licensors. Our trademarks and trade dress may not be used in connection with any product or service without the prior written consent of InternLink.
          </p>
          <p className="mt-4">
            Content submitted by users (such as reports, evaluations, and documents) remains the intellectual property of the respective user or their institution. By submitting content, you grant InternLink a non-exclusive, royalty-free license to use, store, and display that content solely for the purpose of operating the Service.
          </p>
        </Section>

        <Section title="7. Privacy">
          <p>
            Your use of the Service is also governed by our <Link href="/privacy" className="text-teal-600 dark:text-teal-400 underline underline-offset-2 hover:text-teal-700">Privacy Policy</Link>, which is incorporated into these Terms by reference. Please review our Privacy Policy to understand our practices regarding the collection and use of your personal information.
          </p>
        </Section>

        <Section title="8. Document Verification">
          <p>
            Users who register as supervisors or coordinators are required to submit verification documents. By submitting these documents, you confirm that they are authentic and accurate. Submission of fraudulent documents will result in immediate account termination and may be reported to relevant authorities.
          </p>
        </Section>

        <Section title="9. Termination">
          <p>
            InternLink reserves the right to suspend or terminate your access to the Service at any time, with or without cause, and with or without notice, including for violation of these Terms. Upon termination, your right to use the Service will immediately cease.
          </p>
          <p className="mt-4">
            You may terminate your account at any time by contacting your institution's coordinator or platform administrator.
          </p>
        </Section>

        <Section title="10. Disclaimers">
          <p>
            The Service is provided on an "as is" and "as available" basis without warranties of any kind, either express or implied. InternLink does not warrant that the Service will be uninterrupted, error-free, or free of viruses or other harmful components.
          </p>
        </Section>

        <Section title="11. Limitation of Liability">
          <p>
            To the fullest extent permitted by applicable law, InternLink shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, or goodwill, arising out of or in connection with your use of the Service.
          </p>
        </Section>

        <Section title="12. Changes to Terms">
          <p>
            InternLink reserves the right to modify these Terms at any time. We will notify users of material changes by updating the "Last updated" date at the top of this page. Your continued use of the Service after any changes constitutes your acceptance of the new Terms.
          </p>
        </Section>

        <Section title="13. Governing Law">
          <p>
            These Terms shall be governed by and construed in accordance with applicable laws. Any disputes arising under these Terms shall be subject to the exclusive jurisdiction of the competent courts.
          </p>
        </Section>

        <Section title="14. Contact Us">
          <p>
            If you have any questions about these Terms, please contact us at:
          </p>
          <div className="mt-4 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-5 text-sm space-y-1">
            <p className="font-semibold text-slate-900 dark:text-slate-100">InternLink Support</p>
            <p>Email: <a href="mailto:support@internlink.app" className="text-teal-600 dark:text-teal-400 hover:underline">support@internlink.app</a></p>
          </div>
        </Section>

      </main>

      {/* Footer */}
      <footer className="border-t border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900">
        <div className="mx-auto max-w-4xl px-6 py-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-sm text-slate-500 dark:text-slate-400">
          <p>© {new Date().getFullYear()} InternLink. All rights reserved.</p>
          <div className="flex items-center gap-6">
            <Link href="/terms" className="text-teal-600 dark:text-teal-400 font-medium">Terms of Service</Link>
            <Link href="/privacy" className="hover:text-teal-600 dark:hover:text-teal-400 transition-colors">Privacy Policy</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section>
      <h2 className="text-xl font-bold text-slate-900 dark:text-slate-100 mb-4 pb-2 border-b border-slate-200 dark:border-slate-700">
        {title}
      </h2>
      <div className="text-slate-600 dark:text-slate-400 leading-relaxed space-y-3 [&_ul]:mt-3 [&_ul]:space-y-2 [&_ul]:list-disc [&_ul]:pl-6 [&_strong]:text-slate-800 [&_strong]:dark:text-slate-200">
        {children}
      </div>
    </section>
  );
}
