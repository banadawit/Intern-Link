import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Privacy Policy — InternLink",
  description: "Learn how InternLink collects, uses, and protects your personal information.",
};

const LAST_UPDATED = "May 15, 2026";

export default function PrivacyPolicyPage() {
  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-800 dark:text-slate-200">
      {/* Header */}
      <header className="border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900">
        <div className="mx-auto max-w-4xl px-6 py-5 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2 text-teal-600 dark:text-teal-400 font-bold text-xl tracking-tight">
            InternLink
          </Link>
          <nav className="flex items-center gap-6 text-sm text-slate-500 dark:text-slate-400">
            <Link href="/terms" className="hover:text-teal-600 dark:hover:text-teal-400 transition-colors">Terms of Service</Link>
            <Link href="/" className="hover:text-teal-600 dark:hover:text-teal-400 transition-colors">Back to Home</Link>
          </nav>
        </div>
      </header>

      {/* Hero */}
      <div className="bg-gradient-to-br from-slate-700 to-slate-900 dark:from-slate-800 dark:to-slate-950 text-white">
        <div className="mx-auto max-w-4xl px-6 py-16">
          <p className="text-slate-300 text-sm font-semibold uppercase tracking-widest mb-3">Legal</p>
          <h1 className="text-4xl font-bold mb-4">Privacy Policy</h1>
          <p className="text-slate-300 text-lg max-w-2xl">
            Your privacy matters to us. This policy explains what information we collect, how we use it, and the choices you have.
          </p>
          <p className="mt-6 text-slate-400 text-sm">Last updated: {LAST_UPDATED}</p>
        </div>
      </div>

      {/* Content */}
      <main className="mx-auto max-w-4xl px-6 py-14 space-y-12">

        <Section title="1. Introduction">
          <p>
            InternLink ("we," "our," or "us") is committed to protecting your personal information. This Privacy Policy describes how we collect, use, disclose, and safeguard your information when you use the InternLink platform ("Service"). Please read this policy carefully. If you disagree with its terms, please discontinue use of the Service.
          </p>
        </Section>

        <Section title="2. Information We Collect">
          <p>We collect information in the following ways:</p>

          <h3>Information You Provide Directly</h3>
          <ul>
            <li><strong>Account information:</strong> Full name, email address, role (student, supervisor, coordinator, etc.), and password.</li>
            <li><strong>Profile information:</strong> University or company affiliation, department, and contact details.</li>
            <li><strong>Verification documents:</strong> Identity or credential documents submitted during registration for supervisors and coordinators.</li>
            <li><strong>Internship content:</strong> Weekly plans, progress reports, evaluations, and feedback submitted through the platform.</li>
            <li><strong>Communications:</strong> Messages sent through the platform's chat or announcement features.</li>
          </ul>

          <h3>Information Collected Automatically</h3>
          <ul>
            <li><strong>Usage data:</strong> Pages visited, features used, actions taken, and timestamps.</li>
            <li><strong>Device information:</strong> Browser type, operating system, and IP address.</li>
            <li><strong>Log data:</strong> Server logs including access times and error reports.</li>
          </ul>
        </Section>

        <Section title="3. How We Use Your Information">
          <p>We use the information we collect to:</p>
          <ul>
            <li>Create and manage your account and verify your identity.</li>
            <li>Facilitate internship placements, supervision, and coordination.</li>
            <li>Enable communication between students, supervisors, coordinators, and administrators.</li>
            <li>Process and display weekly plans, reports, and evaluations.</li>
            <li>Send notifications about platform activity, approvals, and updates.</li>
            <li>Improve the Service through analytics and usage insights.</li>
            <li>Comply with legal obligations and enforce our Terms of Service.</li>
            <li>Detect and prevent fraudulent or unauthorized activity.</li>
          </ul>
        </Section>

        <Section title="4. How We Share Your Information">
          <p>We do not sell your personal information. We may share your information in the following circumstances:</p>
          <ul>
            <li><strong>Within the platform:</strong> Your name, role, and institutional affiliation are visible to other users as necessary for the internship workflow (e.g., a supervisor can see their assigned student's reports).</li>
            <li><strong>With your institution:</strong> Coordinators and administrators at your university or company may access your internship-related data as part of their oversight responsibilities.</li>
            <li><strong>Service providers:</strong> We may share data with trusted third-party providers (such as cloud storage and email services) who assist in operating the platform, subject to confidentiality agreements.</li>
            <li><strong>Legal requirements:</strong> We may disclose information if required by law, court order, or governmental authority.</li>
            <li><strong>Business transfers:</strong> In the event of a merger, acquisition, or sale of assets, your information may be transferred as part of that transaction.</li>
          </ul>
        </Section>

        <Section title="5. Data Retention">
          <p>
            We retain your personal information for as long as your account is active or as needed to provide the Service. Internship records, evaluations, and reports may be retained for a longer period to satisfy academic and institutional record-keeping requirements.
          </p>
          <p className="mt-3">
            When your account is deleted, we will remove or anonymize your personal information, except where retention is required by law or legitimate institutional need.
          </p>
        </Section>

        <Section title="6. Data Security">
          <p>
            We implement industry-standard technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. These measures include:
          </p>
          <ul>
            <li>Encrypted data transmission using HTTPS/TLS.</li>
            <li>Hashed and salted password storage.</li>
            <li>Role-based access controls limiting data access to authorized users.</li>
            <li>Regular security reviews and monitoring.</li>
          </ul>
          <p className="mt-3">
            No method of transmission over the internet or electronic storage is 100% secure. While we strive to protect your information, we cannot guarantee absolute security.
          </p>
        </Section>

        <Section title="7. Cookies and Tracking">
          <p>
            InternLink uses cookies and similar tracking technologies to maintain your session, remember your preferences, and analyze platform usage. You can control cookie settings through your browser, though disabling certain cookies may affect the functionality of the Service.
          </p>
          <p className="mt-3">
            We use session cookies (which expire when you close your browser) and persistent cookies (which remain until deleted or expired) for authentication and user experience purposes.
          </p>
        </Section>

        <Section title="8. Your Rights and Choices">
          <p>Depending on your location, you may have the following rights regarding your personal information:</p>
          <ul>
            <li><strong>Access:</strong> Request a copy of the personal information we hold about you.</li>
            <li><strong>Correction:</strong> Request correction of inaccurate or incomplete information.</li>
            <li><strong>Deletion:</strong> Request deletion of your personal information, subject to legal and institutional retention requirements.</li>
            <li><strong>Portability:</strong> Request a machine-readable copy of your data.</li>
            <li><strong>Objection:</strong> Object to certain processing of your personal information.</li>
          </ul>
          <p className="mt-3">
            To exercise any of these rights, please contact your institution's coordinator or reach out to us directly at the contact information below.
          </p>
        </Section>

        <Section title="9. Children's Privacy">
          <p>
            InternLink is not intended for use by individuals under the age of 16. We do not knowingly collect personal information from children under 16. If we become aware that we have collected such information, we will take steps to delete it promptly.
          </p>
        </Section>

        <Section title="10. Third-Party Links">
          <p>
            The Service may contain links to third-party websites or services. We are not responsible for the privacy practices of those third parties and encourage you to review their privacy policies before providing any personal information.
          </p>
        </Section>

        <Section title="11. Changes to This Policy">
          <p>
            We may update this Privacy Policy from time to time. We will notify you of significant changes by updating the "Last updated" date at the top of this page. Your continued use of the Service after any changes constitutes your acceptance of the updated policy.
          </p>
        </Section>

        <Section title="12. Contact Us">
          <p>
            If you have questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us:
          </p>
          <div className="mt-4 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-5 text-sm space-y-1">
            <p className="font-semibold text-slate-900 dark:text-slate-100">InternLink Privacy Team</p>
            <p>Email: <a href="mailto:privacy@internlink.app" className="text-teal-600 dark:text-teal-400 hover:underline">privacy@internlink.app</a></p>
          </div>
        </Section>

      </main>

      {/* Footer */}
      <footer className="border-t border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900">
        <div className="mx-auto max-w-4xl px-6 py-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-sm text-slate-500 dark:text-slate-400">
          <p>© {new Date().getFullYear()} InternLink. All rights reserved.</p>
          <div className="flex items-center gap-6">
            <Link href="/terms" className="hover:text-teal-600 dark:hover:text-teal-400 transition-colors">Terms of Service</Link>
            <Link href="/privacy" className="text-teal-600 dark:text-teal-400 font-medium">Privacy Policy</Link>
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
      <div className="text-slate-600 dark:text-slate-400 leading-relaxed space-y-3 [&_h3]:text-base [&_h3]:font-semibold [&_h3]:text-slate-800 [&_h3]:dark:text-slate-200 [&_h3]:mt-5 [&_h3]:mb-2 [&_ul]:mt-3 [&_ul]:space-y-2 [&_ul]:list-disc [&_ul]:pl-6 [&_strong]:text-slate-800 [&_strong]:dark:text-slate-200">
        {children}
      </div>
    </section>
  );
}
