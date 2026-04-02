'use client';

import React, { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { 
  GraduationCap, 
  ArrowRight, 
  ArrowLeft, 
  Upload, 
  CheckCircle2,
  Mail,
  Lock,
  UserCircle,
  AlertCircle,
  Eye,
  EyeOff,
  X,
  FileText,
  Loader2,
  Check,
  Building,
  Briefcase,
  School
} from 'lucide-react';
import { useAuth } from '@/lib/hooks/useAuth';

// Types
type Role = 'student' | 'coordinator' | 'supervisor' | null;

interface FormData {
  fullName: string;
  email: string;
  password: string;
  confirmPassword: string;
  // Role-specific fields
  universityName?: string;
  companyName?: string;
  department?: string;
  studentId?: string;
  position?: string;
  verificationFile?: File;
  verificationFilePreview?: string;
}

interface FormErrors {
  fullName?: string;
  email?: string;
  password?: string;
  confirmPassword?: string;
  universityName?: string;
  companyName?: string;
  department?: string;
  studentId?: string;
  position?: string;
  verificationFile?: string;
  general?: string;
}

const RegisterPage = () => {
  const router = useRouter();
  const { register, isLoading: authLoading } = useAuth();
  
  const [step, setStep] = useState(1);
  const [role, setRole] = useState<Role>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [agreedToTerms, setAgreedToTerms] = useState(false);
  
  const [formData, setFormData] = useState<FormData>({
    fullName: '',
    email: '',
    password: '',
    confirmPassword: '',
    universityName: '',
    companyName: '',
    department: '',
    studentId: '',
    position: '',
  });
  
  const [errors, setErrors] = useState<FormErrors>({});
  const [touched, setTouched] = useState<Record<string, boolean>>({});
  const [passwordStrength, setPasswordStrength] = useState({ score: 0, label: '', color: '' });

  // Password strength checker
  const checkPasswordStrength = useCallback((password: string) => {
    let score = 0;
    if (password.length >= 8) score++;
    if (password.match(/[A-Z]/)) score++;
    if (password.match(/[0-9]/)) score++;
    if (password.match(/[^A-Za-z0-9]/)) score++;
    
    const strengthMap = {
      0: { label: 'Very Weak', color: 'text-red-500' },
      1: { label: 'Weak', color: 'text-orange-500' },
      2: { label: 'Fair', color: 'text-yellow-500' },
      3: { label: 'Good', color: 'text-primary-500' },
      4: { label: 'Strong', color: 'text-emerald-500' },
    };
    
    return { score, ...strengthMap[score as keyof typeof strengthMap] };
  }, []);

  // Update password strength when password changes
  useEffect(() => {
    if (formData.password) {
      setPasswordStrength(checkPasswordStrength(formData.password));
    }
  }, [formData.password, checkPasswordStrength]);

  // Validation functions
  const validateFullName = (name: string) => {
    if (!name) return 'Full name is required';
    if (name.length < 3) return 'Name must be at least 3 characters';
    return '';
  };

  const validateEmail = (email: string) => {
    const emailRegex = /^[^\s@]+@([^\s@]+\.)+[^\s@]+$/;
    if (!email) return 'Email is required';
    if (!emailRegex.test(email)) return 'Please enter a valid email address';
    
    return '';
  };

  const validatePassword = (password: string) => {
    if (!password) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!password.match(/[A-Za-z]/)) return 'Password must contain at least one letter';
    if (!password.match(/[0-9]/)) return 'Password must contain at least one number';
    return '';
  };

  const validateConfirmPassword = (confirm: string) => {
    if (!confirm) return 'Please confirm your password';
    if (confirm !== formData.password) return 'Passwords do not match';
    return '';
  };

  const validateRoleSpecific = () => {
    if (role === 'coordinator') {
      if (!formData.universityName) return 'University name is required';
      if (!formData.position) return 'Position is required';
    }
    if (role === 'supervisor') {
      if (!formData.companyName) return 'Company name is required';
      if (!formData.position) return 'Position is required';
    }
    if (role === 'student') {
      if (!formData.universityName) return 'University name is required';
      if (!formData.department) return 'Department is required';
      if (!formData.studentId) return 'Student ID is required';
    }
    return '';
  };

  const validateVerificationFile = (file?: File) => {
    if (file && file.size > 5 * 1024 * 1024) {
      return 'File size must be less than 5MB';
    }
    
    if (file && !['application/pdf', 'image/jpeg', 'image/png'].includes(file.type)) {
      return 'Only PDF, JPG, or PNG files are allowed';
    }
    
    return '';
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    
    // Clear error for this field
    if (errors[name as keyof FormErrors]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const handleBlur = (field: string) => {
    setTouched(prev => ({ ...prev, [field]: true }));
    
    // Validate field
    let error = '';
    switch (field) {
      case 'fullName':
        error = validateFullName(formData.fullName);
        break;
      case 'email':
        error = validateEmail(formData.email);
        break;
      case 'password':
        error = validatePassword(formData.password);
        break;
      case 'confirmPassword':
        error = validateConfirmPassword(formData.confirmPassword);
        break;
    }
    
    if (error) {
      setErrors(prev => ({ ...prev, [field]: error }));
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setFormData(prev => ({ 
        ...prev, 
        verificationFile: file,
        verificationFilePreview: URL.createObjectURL(file)
      }));
      setErrors(prev => ({ ...prev, verificationFile: '' }));
    }
  };

  const removeFile = () => {
    setFormData(prev => ({ 
      ...prev, 
      verificationFile: undefined,
      verificationFilePreview: undefined
    }));
  };

  const validateStep1 = () => {
    return role !== null;
  };

  const validateStep2 = () => {
    const fullNameError = validateFullName(formData.fullName);
    const emailError = validateEmail(formData.email);
    const passwordError = validatePassword(formData.password);
    const confirmError = validateConfirmPassword(formData.confirmPassword);
    
    setErrors({
      fullName: fullNameError,
      email: emailError,
      password: passwordError,
      confirmPassword: confirmError,
    });
    
    return !fullNameError && !emailError && !passwordError && !confirmError;
  };

  const validateStep3 = () => {
    const roleError = validateRoleSpecific();
    const fileError = validateVerificationFile(formData.verificationFile);
    
    if (roleError) {
      setErrors(prev => ({ ...prev, general: roleError }));
      return false;
    }
    
    if (fileError) {
      setErrors(prev => ({ ...prev, verificationFile: fileError }));
      return false;
    }
    
    if (!agreedToTerms) {
      setErrors(prev => ({ ...prev, general: 'You must agree to the terms and conditions' }));
      return false;
    }
    
    return true;
  };

  const nextStep = () => {
    if (step === 1 && validateStep1()) {
      setStep(2);
    } else if (step === 2 && validateStep2()) {
      setStep(3);
    }
  };

  const prevStep = () => {
    setStep(step - 1);
  };

  const handleSubmit = async () => {
    if (!validateStep3()) return;
    
    setIsLoading(true);
    setErrors({});
    
    try {
      const registerData = {
        fullName: formData.fullName,
        email: formData.email,
        password: formData.password,
        role: role!,
        universityName: formData.universityName,
        ...(role === 'coordinator' && { position: formData.position }),
        ...(role === 'supervisor' && {
          companyName: formData.companyName,
          position: formData.position,
        }),
        ...(role === 'student' && {
          department: formData.department,
          studentId: formData.studentId,
        }),
        verificationDocument: formData.verificationFile,
      };
      
      await register(registerData);
      
      router.push(`/verify-email?email=${encodeURIComponent(formData.email)}`);
      
    } catch (error: unknown) {
      const err = error as { message?: string };
      setErrors({
        general: err?.message || 'Registration failed. Please try again.'
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Progress Header */}
      <div className="space-y-2">
        <div className="flex justify-between text-xs font-bold uppercase tracking-widest text-slate-400">
          <span>Step {step} of 3</span>
          <span>
            {step === 1 ? 'Role Selection' : step === 2 ? 'Account Details' : 'Verification'}
          </span>
        </div>
        <div className="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
          <div 
            className="h-full bg-gradient-to-r from-primary-500 to-primary-600 transition-all duration-500 ease-out rounded-full" 
            style={{ width: `${(step / 3) * 100}%` }}
          />
        </div>
      </div>

      {/* General Error Message */}
      {errors.general && (
        <div className="flex items-center gap-3 rounded-xl bg-red-50 p-4 text-red-700 border border-red-200 animate-slide-down">
          <AlertCircle className="h-5 w-5 flex-shrink-0" />
          <p className="text-sm font-medium">{errors.general}</p>
        </div>
      )}

      {/* STEP 1: ROLE SELECTION */}
      {step === 1 && (
        <div className="space-y-6 animate-slide-up">
          <div className="text-center lg:text-left">
            <h1 className="text-3xl font-bold text-slate-900">Choose your role</h1>
            <p className="mt-2 text-sm text-slate-500">
              Select how you will be using the InternLink platform
            </p>
          </div>

          <div className="grid gap-4">
            {[
              { 
                id: 'student' as const, 
                title: 'Student', 
                icon: GraduationCap, 
                desc: 'Apply for internships and track your progress',
                color: 'bg-emerald-50 text-emerald-600',
                bgHover: 'hover:border-emerald-200'
              },
              { 
                id: 'coordinator' as const, 
                title: 'University Coordinator', 
                icon: School, 
                desc: 'Manage student placements and university partnerships',
                color: 'bg-primary-50 text-primary-600',
                bgHover: 'hover:border-primary-200'
              },
              { 
                id: 'supervisor' as const, 
                title: 'Company Supervisor', 
                icon: Briefcase, 
                desc: 'Evaluate students and verify internship reports',
                color: 'bg-slate-100 text-slate-600',
                bgHover: 'hover:border-slate-300'
              },
            ].map((item) => (
              <button
                key={item.id}
                onClick={() => setRole(item.id)}
                className={`flex items-center gap-4 p-4 rounded-2xl border-2 transition-all text-left group ${
                  role === item.id 
                    ? 'border-primary-600 bg-primary-50/30 shadow-soft' 
                    : 'border-slate-100 bg-white hover:border-slate-200 hover:shadow-soft'
                }`}
              >
                <div className={`p-3 rounded-xl transition-all ${
                  role === item.id 
                    ? 'bg-primary-600 text-white shadow-lg shadow-primary-600/20' 
                    : 'bg-slate-100 text-slate-500 group-hover:bg-primary-50 group-hover:text-primary-600'
                }`}>
                  <item.icon className="h-6 w-6" />
                </div>
                <div className="flex-1">
                  <p className="font-bold text-slate-900">{item.title}</p>
                  <p className="text-xs text-slate-500">{item.desc}</p>
                </div>
                {role === item.id && (
                  <CheckCircle2 className="h-5 w-5 text-primary-600" />
                )}
              </button>
            ))}
          </div>

          <button
            disabled={!role}
            onClick={nextStep}
            className="w-full flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-4 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700 hover:shadow-xl disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Continue to Account Details 
            <ArrowRight className="h-4 w-4" />
          </button>
        </div>
      )}

      {/* STEP 2: BASIC ACCOUNT INFO */}
      {step === 2 && (
        <div className="space-y-6 animate-slide-up">
          <div className="text-center lg:text-left">
            <h1 className="text-3xl font-bold text-slate-900">Account Details</h1>
            <p className="mt-2 text-sm text-slate-500">
              Enter your official credentials
            </p>
          </div>

          <div className="space-y-4">
            {/* Full Name */}
            <div className="space-y-2">
              <label className="text-sm font-semibold text-slate-700">
                Full Name <span className="text-red-500">*</span>
              </label>
              <div className="relative group">
                <UserCircle className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-primary-500 transition-colors" />
                <input
                  type="text"
                  name="fullName"
                  value={formData.fullName}
                  onChange={handleInputChange}
                  onBlur={() => handleBlur('fullName')}
                  placeholder="John Doe"
                  className={`w-full pl-10 pr-4 py-3 rounded-xl border bg-white text-slate-900 placeholder:text-slate-400 transition-all
                    focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500
                    ${errors.fullName && touched.fullName 
                      ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20'
                      : 'border-slate-200 hover:border-slate-300'
                    }`}
                />
              </div>
              {errors.fullName && touched.fullName && (
                <p className="text-xs text-red-600 flex items-center gap-1 mt-1">
                  <AlertCircle className="h-3 w-3" />
                  {errors.fullName}
                </p>
              )}
            </div>

            {/* Email */}
            <div className="space-y-2">
              <label className="text-sm font-semibold text-slate-700">
                Email Address <span className="text-red-500">*</span>
              </label>
              <div className="relative group">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-primary-500 transition-colors" />
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleInputChange}
                  onBlur={() => handleBlur('email')}
                  placeholder={role === 'coordinator' ? 'name@university.edu.et' : 'name@email.com'}
                  className={`w-full pl-10 pr-4 py-3 rounded-xl border bg-white text-slate-900 placeholder:text-slate-400 transition-all
                    focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500
                    ${errors.email && touched.email 
                      ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20'
                      : 'border-slate-200 hover:border-slate-300'
                    }`}
                />
              </div>
              {errors.email && touched.email && (
                <p className="text-xs text-red-600 flex items-center gap-1 mt-1">
                  <AlertCircle className="h-3 w-3" />
                  {errors.email}
                </p>
              )}
            </div>

            {/* Password */}
            <div className="space-y-2">
              <label className="text-sm font-semibold text-slate-700">
                Password <span className="text-red-500">*</span>
              </label>
              <div className="relative group">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-primary-500 transition-colors" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  name="password"
                  value={formData.password}
                  onChange={handleInputChange}
                  onBlur={() => handleBlur('password')}
                  placeholder="••••••••"
                  className={`w-full pl-10 pr-12 py-3 rounded-xl border bg-white text-slate-900 placeholder:text-slate-400 transition-all
                    focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500
                    ${errors.password && touched.password 
                      ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20'
                      : 'border-slate-200 hover:border-slate-300'
                    }`}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                >
                  {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                </button>
              </div>
              
              {/* Password Strength Indicator */}
              {formData.password && (
                <div className="mt-2 space-y-1">
                  <div className="flex gap-1">
                    {[1, 2, 3, 4].map((level) => (
                      <div
                        key={level}
                        className={`h-1 flex-1 rounded-full transition-all ${
                          level <= passwordStrength.score
                            ? passwordStrength.score === 4
                              ? 'bg-emerald-500'
                              : passwordStrength.score === 3
                              ? 'bg-primary-500'
                              : passwordStrength.score === 2
                              ? 'bg-yellow-500'
                              : 'bg-orange-500'
                            : 'bg-slate-200'
                        }`}
                      />
                    ))}
                  </div>
                  <p className={`text-xs ${passwordStrength.color}`}>
                    {passwordStrength.label} password
                  </p>
                </div>
              )}
              
              {errors.password && touched.password && (
                <p className="text-xs text-red-600 flex items-center gap-1 mt-1">
                  <AlertCircle className="h-3 w-3" />
                  {errors.password}
                </p>
              )}
            </div>

            {/* Confirm Password */}
            <div className="space-y-2">
              <label className="text-sm font-semibold text-slate-700">
                Confirm Password <span className="text-red-500">*</span>
              </label>
              <div className="relative group">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-primary-500 transition-colors" />
                <input
                  type={showConfirmPassword ? 'text' : 'password'}
                  name="confirmPassword"
                  value={formData.confirmPassword}
                  onChange={handleInputChange}
                  onBlur={() => handleBlur('confirmPassword')}
                  placeholder="••••••••"
                  className={`w-full pl-10 pr-12 py-3 rounded-xl border bg-white text-slate-900 placeholder:text-slate-400 transition-all
                    focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500
                    ${errors.confirmPassword && touched.confirmPassword 
                      ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20'
                      : 'border-slate-200 hover:border-slate-300'
                    }`}
                />
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                >
                  {showConfirmPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                </button>
              </div>
              {errors.confirmPassword && touched.confirmPassword && (
                <p className="text-xs text-red-600 flex items-center gap-1 mt-1">
                  <AlertCircle className="h-3 w-3" />
                  {errors.confirmPassword}
                </p>
              )}
            </div>
          </div>

          <div className="flex gap-4">
            <button
              onClick={prevStep}
              className="flex-1 flex items-center justify-center gap-2 py-4 text-sm font-bold text-slate-500 hover:text-slate-700 transition-colors rounded-xl hover:bg-slate-50"
            >
              <ArrowLeft className="h-4 w-4" />
              Back
            </button>
            <button
              onClick={nextStep}
              className="flex-[2] flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-4 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700"
            >
              Next Step
              <ArrowRight className="h-4 w-4" />
            </button>
          </div>
        </div>
      )}

      {/* STEP 3: ROLE SPECIFIC + VERIFICATION */}
      {step === 3 && role && (
        <div className="space-y-6 animate-slide-up">
          <div className="text-center lg:text-left">
            <h1 className="text-3xl font-bold text-slate-900">
              {role === 'student' ? 'Student Information' : 
               role === 'coordinator' ? 'University Information' : 
               'Company Information'}
            </h1>
            <p className="mt-2 text-sm text-slate-500">
              {role === 'student' 
                ? 'Enter your academic details and upload student ID'
                : role === 'coordinator'
                ? 'Enter your university details and upload official verification letter'
                : 'Enter your company details and upload official verification document'}
            </p>
          </div>

          {/* Step 3 error display */}
          {errors.general && (
            <div className="flex items-center gap-3 rounded-xl bg-red-50 p-4 text-red-700 border border-red-200">
              <AlertCircle className="h-5 w-5 flex-shrink-0" />
              <p className="text-sm font-medium">{errors.general}</p>
            </div>
          )}

          {/* Role-Specific Fields */}
          <div className="space-y-4">
            {role === 'coordinator' && (
              <>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    University Name <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <Building className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
                    <input
                      type="text"
                      name="universityName"
                      value={formData.universityName}
                      onChange={handleInputChange}
                      placeholder="e.g., Haramaya University"
                      className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    Position/Title <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="position"
                    value={formData.position}
                    onChange={handleInputChange}
                    placeholder="e.g., Internship Coordinator"
                    className="w-full px-4 py-3 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                  />
                </div>
              </>
            )}

            {role === 'supervisor' && (
              <>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    Company Name <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <Briefcase className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
                    <input
                      type="text"
                      name="companyName"
                      value={formData.companyName}
                      onChange={handleInputChange}
                      placeholder="e.g., Ethio Telecom"
                      className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    Position <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="position"
                    value={formData.position}
                    onChange={handleInputChange}
                    placeholder="e.g., HR Manager"
                    className="w-full px-4 py-3 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                  />
                </div>
              </>
            )}

            {role === 'student' && (
              <>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    University Name <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <Building className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
                    <input
                      type="text"
                      name="universityName"
                      value={formData.universityName}
                      onChange={handleInputChange}
                      placeholder="e.g., Haramaya University"
                      className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    Department <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <GraduationCap className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
                    <input
                      type="text"
                      name="department"
                      value={formData.department}
                      onChange={handleInputChange}
                      placeholder="e.g., Software Engineering"
                      className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    Student ID <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="studentId"
                    value={formData.studentId}
                    onChange={handleInputChange}
                    placeholder="e.g., 2122/142"
                    className="w-full px-4 py-3 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                  />
                </div>
              </>
            )}
          </div>

          {/* File Upload */}
          <div className="space-y-2">
            <label className="text-sm font-semibold text-slate-700">
              {role === 'student' ? 'Student ID / Verification' : 
               role === 'coordinator' ? 'Official University Letter with Stamp' : 
               'Official Company Letter with Stamp'} <span className="text-red-500">*</span>
            </label>
            
            {!formData.verificationFile ? (
              <label className="border-2 border-dashed border-slate-200 rounded-2xl p-8 flex flex-col items-center justify-center bg-slate-50 hover:bg-slate-100 hover:border-primary-300 transition-all cursor-pointer group">
                <input
                  type="file"
                  accept=".pdf,.jpg,.jpeg,.png"
                  onChange={handleFileChange}
                  className="hidden"
                />
                <div className="h-14 w-14 rounded-full bg-white shadow-sm flex items-center justify-center text-slate-400 group-hover:text-primary-600 transition-colors mb-4">
                  <Upload className="h-7 w-7" />
                </div>
                <p className="text-sm font-bold text-slate-900">Click to upload or drag and drop</p>
                <p className="text-xs text-slate-500 mt-1">PDF, JPG or PNG (max. 5MB)</p>
                <p className="text-xs text-slate-400 mt-2">Official document with institutional stamp required</p>
              </label>
            ) : (
              <div className="border-2 border-primary-200 rounded-2xl p-4 bg-primary-50/30">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-primary-100 rounded-lg">
                      <FileText className="h-6 w-6 text-primary-600" />
                    </div>
                    <div>
                      <p className="text-sm font-medium text-slate-900">
                        {formData.verificationFile.name}
                      </p>
                      <p className="text-xs text-slate-500">
                        {(formData.verificationFile.size / 1024 / 1024).toFixed(2)} MB
                      </p>
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={removeFile}
                    className="p-1 hover:bg-slate-200 rounded-lg transition-colors"
                  >
                    <X className="h-5 w-5 text-slate-500" />
                  </button>
                </div>
                {formData.verificationFilePreview && formData.verificationFile.type.startsWith('image/') && (
                  <div className="mt-3">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img 
                      src={formData.verificationFilePreview} 
                      alt="Preview" 
                      className="max-h-32 rounded-lg object-cover"
                    />
                  </div>
                )}
              </div>
            )}
            
            {errors.verificationFile && (
              <p className="text-xs text-red-600 flex items-center gap-1 mt-1">
                <AlertCircle className="h-3 w-3" />
                {errors.verificationFile}
              </p>
            )}
          </div>

          {/* Terms and Conditions */}
          <div className="flex items-start gap-3 pt-2">
            <input
              type="checkbox"
              id="terms"
              checked={agreedToTerms}
              onChange={(e) => setAgreedToTerms(e.target.checked)}
              className="mt-0.5 h-4 w-4 rounded border-slate-300 text-primary-600 focus:ring-primary-500"
            />
            <label htmlFor="terms" className="text-sm text-slate-600">
              I agree to the{' '}
              <Link href="/terms" className="text-primary-600 hover:text-primary-700 font-medium">
                Terms of Service
              </Link>{' '}
              and{' '}
              <Link href="/privacy" className="text-primary-600 hover:text-primary-700 font-medium">
                Privacy Policy
              </Link>
            </label>
          </div>

          <div className="flex gap-4 pt-4">
            <button
              onClick={prevStep}
              className="flex-1 flex items-center justify-center gap-2 py-4 text-sm font-bold text-slate-500 hover:text-slate-700 transition-colors rounded-xl hover:bg-slate-50"
            >
              <ArrowLeft className="h-4 w-4" />
              Back
            </button>
            <button
              onClick={handleSubmit}
              disabled={isLoading || authLoading}
              className="flex-[2] flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-4 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700 disabled:opacity-70 disabled:cursor-not-allowed"
            >
              {isLoading || authLoading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Creating Account...
                </>
              ) : (
                <>
                  <Check className="h-4 w-4" />
                  Complete Registration
                </>
              )}
            </button>
          </div>
        </div>
      )}

      {/* Footer */}
      <p className="text-center text-sm text-slate-500 pt-4">
        Already have an account?{' '}
        <Link 
          href="/login" 
          className="font-bold text-primary-600 hover:text-primary-700 underline underline-offset-4 transition-colors"
        >
          Sign In
        </Link>
      </p>
    </div>
  );
};

export default RegisterPage;