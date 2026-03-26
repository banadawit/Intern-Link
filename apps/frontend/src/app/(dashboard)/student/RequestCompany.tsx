'use client';

import React, { useState } from 'react';
import { 
  Building, 
  Mail, 
  Send, 
  CheckCircle2, 
  Clock, 
  AlertCircle,
  Info,
  ArrowRight
} from 'lucide-react';
import { MOCK_COMPANY_REQUESTS } from '@/lib/superadmin/mockData';
import { CompanyRequest } from '@/lib/superadmin/types';
import { cn } from '@/lib/utils';

const RequestCompany = () => {
  const [requests, setRequests] = useState<CompanyRequest[]>(MOCK_COMPANY_REQUESTS);
  const [formData, setFormData] = useState({
    companyName: '',
    contactEmail: '',
    description: '',
  });
  const [isSubmitted, setIsSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const newRequest: CompanyRequest = {
      id: `cr${Date.now()}`,
      companyName: formData.companyName,
      contactEmail: formData.contactEmail,
      status: 'Pending',
      requestedAt: new Date().toISOString(),
    };
    setRequests([newRequest, ...requests]);
    setIsSubmitted(true);
    setFormData({ companyName: '', contactEmail: '', description: '' });
    setTimeout(() => setIsSubmitted(false), 5000);
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <header>
        <h1 className="text-3xl font-bold mb-2 text-slate-900">Request Company Registration</h1>
        <p className="text-slate-600">Initiate onboarding for companies not yet on the platform.</p>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Request Form */}
        <div className="card p-8 bg-white border border-slate-200">
          <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
            <Building className="w-5 h-5 text-teal-600" />
            Company Details
          </h3>
          
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-2">
              <label className="text-sm font-bold text-slate-500">Company Name</label>
              <div className="relative">
                <Building className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500" />
                <input 
                  type="text" 
                  className="w-full pl-10 px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-600 focus:border-transparent transition-all bg-white text-slate-900"
                  placeholder="Enter company name..."
                  value={formData.companyName}
                  onChange={(e) => setFormData({ ...formData, companyName: e.target.value })}
                  required
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-bold text-slate-500">Contact Email</label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500" />
                <input 
                  type="email" 
                  className="w-full pl-10 px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-600 focus:border-transparent transition-all bg-white text-slate-900"
                  placeholder="Enter HR or supervisor email..."
                  value={formData.contactEmail}
                  onChange={(e) => setFormData({ ...formData, contactEmail: e.target.value })}
                  required
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-bold text-slate-500">Additional Information (Optional)</label>
              <textarea 
                className="w-full min-h-[100px] px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-600 focus:border-transparent transition-all bg-white text-slate-900 text-sm"
                placeholder="Provide any additional context for the coordinator..."
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              />
            </div>

            <div className="p-4 bg-blue-50 border border-blue-200 rounded-xl flex items-start gap-3">
              <Info className="w-5 h-5 text-blue-600 mt-0.5" />
              <p className="text-xs text-blue-700 leading-relaxed">
                Once submitted, the Internship Coordinator will be notified to invite the company. You will be assigned once the company registers and passes verification.
              </p>
            </div>

            <button type="submit" className="w-full bg-teal-600 hover:bg-teal-700 text-white font-medium py-2 px-4 rounded-lg transition-all flex items-center justify-center gap-2">
              <Send className="w-4 h-4" />
              Submit Request
            </button>

            {isSubmitted && (
              <div className="p-4 bg-green-50 border border-green-200 rounded-xl flex items-center gap-3 animate-in fade-in slide-in-from-top-2">
                <CheckCircle2 className="w-5 h-5 text-green-600" />
                <p className="text-sm font-medium text-green-700">Request submitted successfully!</p>
              </div>
            )}
          </form>
        </div>

        {/* Request History */}
        <div className="space-y-6">
          <h3 className="text-lg font-bold">Request History</h3>
          <div className="space-y-4">
            {requests.map((request) => (
              <div key={request.id} className="card p-6 flex items-center justify-between hover:border-teal-600/30 transition-all bg-white border border-slate-200">
                <div className="flex items-center gap-4">
                  <div className={cn(
                    "p-3 rounded-xl",
                    request.status === 'Onboarded' ? "bg-green-50 text-green-600" : 
                    request.status === 'Invited' ? "bg-blue-50 text-blue-600" : "bg-yellow-50 text-yellow-500"
                  )}>
                    {request.status === 'Onboarded' ? <CheckCircle2 className="w-5 h-5" /> : 
                     request.status === 'Invited' ? <Send className="w-5 h-5" /> : <Clock className="w-5 h-5" />}
                  </div>
                  <div>
                    <h4 className="font-bold text-slate-900">{request.companyName}</h4>
                    <p className="text-xs text-slate-500">Requested on {new Date(request.requestedAt).toLocaleDateString()}</p>
                  </div>
                </div>
                <div className="text-right">
                  <span className={cn(
                    "px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider",
                    request.status === 'Onboarded' ? "bg-green-50 text-green-600" : 
                    request.status === 'Invited' ? "bg-blue-50 text-blue-600" : "bg-yellow-50 text-yellow-500"
                  )}>
                    {request.status}
                  </span>
                </div>
              </div>
            ))}
            {requests.length === 0 && (
              <div className="card p-12 text-center text-slate-500 bg-white border border-slate-200">
                <Building className="w-12 h-12 mx-auto mb-4 opacity-20" />
                <p className="text-sm font-medium">No company requests found.</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default RequestCompany;
