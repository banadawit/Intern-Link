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
  School,
  ChevronDown,
  Search
} from 'lucide-react';
import { useAuth } from '@/lib/hooks/useAuth';
import { cloudinaryService } from '@/lib/services/cloudinary.service';
import ContactSupportModal from '@/components/shared/ContactSupportModal';

// Types
type Role = 'student' | 'coordinator' | 'hod' | 'supervisor' | null;

interface FormData {
  fullName: string;
  email: string;
  password: string;
  confirmPassword: string;
  // Role-specific fields
  universityId?: number;       // Coordinator, HoD & Student: selected approved university
  universitySearch?: string;   // search input text
  hodId?: number;              // Student: selected HoD/department
  companyName?: string;
  department?: string;
  studentId?: string;
  employeeId?: string;
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
  universityId?: string;
  hodId?: string;
  companyName?: string;
  department?: string;
  studentId?: string;
  employeeId?: string;
  position?: string;
  verificationFile?: string;
  general?: string;
}

const RegisterPage = () => {
  const router = useRouter();
  const { register, isLoading: authLoading } = useAuth();
  
  const [step, setStep] = useState(1);
  const [showSupport, setShowSupport] = useState(false);
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
    universityId: undefined,
    universitySearch: '',
    companyName: '',
    department: '',
    studentId: '',
    employeeId: '',
    position: '',
  });
  
  const [errors, setErrors] = useState<FormErrors>({});
  const [touched, setTouched] = useState<Record<string, boolean>>({});
  const [passwordStrength, setPasswordStrength] = useState({ score: 0, label: '', color: '' });

  // Approved universities for HoD & Student dropdown
  const [approvedUniversities, setApprovedUniversities] = useState<{ id: number; name: string; hasCoordinator: boolean }[]>([]);
  const [uniDropdownOpen, setUniDropdownOpen] = useState(false);
  // Departments (HoD profiles) for the selected university
  const [departments, setDepartments] = useState<{ id: number; department: string }[]>([]);
  const [deptLoading, setDeptLoading] = useState(false);

  // Registration open/closed status per role
  const [regStatus, setRegStatus] = useState<Record<string, boolean>>({
    student: true, coordinator: true, hod: true, supervisor: true,
  });

  useEffect(() => {
    const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';
    fetch(`${API}/registration-status`)
      .then((r) => r.json())
      .then((data: { student: boolean; coordinator: boolean; hod: boolean; supervisor: boolean }) => {
        setRegStatus({
          student: data.student !== false,
          coordinator: data.coordinator !== false,
          hod: data.hod !== false,
          supervisor: data.supervisor !== false,
        });
      })
      .catch(() => {});
  }, []);

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

  // Fetch approved universities when HoD or Student role is selected and we reach step 3
  useEffect(() => {
    if ((role === 'hod' || role === 'student') && step === 3 && approvedUniversities.length === 0) {
      fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api'}/universities/approved`)
        .then((r) => r.json())
        .then((data) => {
          // Backend wraps response as { success, data: [...] }
          const list = Array.isArray(data) ? data : Array.isArray(data?.data) ? data.data : [];
          setApprovedUniversities(list);
        })
        .catch(() => setApprovedUniversities([]));
    }
  }, [role, step, approvedUniversities.length]);

  // Fetch departments when a university is selected for student role
  useEffect(() => {
    if (role === 'student' && formData.universityId) {
      setDeptLoading(true);
      setDepartments([]);
      setFormData(prev => ({ ...prev, hodId: undefined }));
      fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api'}/universities/${formData.universityId}/departments`)
        .then((r) => r.json())
        .then((data) => {
          const list = Array.isArray(data) ? data : Array.isArray(data?.data) ? data.data : [];
          setDepartments(list);
        })
        .catch(() => setDepartments([]))
        .finally(() => setDeptLoading(false));
    }
  }, [role, formData.universityId]);

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
      if (!formData.universityId) return 'University selection is required. Please select an existing institution from the dropdown list. You cannot proceed with a manually typed organization name.';
      // Verify the selected ID actually exists in approved universities
      const selectedUni = approvedUniversities.find(u => u.id === formData.universityId);
      if (!selectedUni) return 'Selected university is not valid or no longer approved. Please select from the list again.';
    }
    if (role === 'hod') {
      if (!formData.universityId) return 'Please select a university';
      if (!approvedUniversities.find((u) => u.id === formData.universityId)?.hasCoordinator) {
        return 'This university does not have a coordinator yet. Please make sure your coordinator registers and gets approved first.';
      }
      if (!formData.department) return 'Department is required';
    }
    if (role === 'supervisor') {
      if (!formData.companyName) return 'Company name is required';
      if (!formData.position) return 'Position is required';
    }
    if (role === 'student') {
      if (!formData.universityId) return 'Please select a university';
      if (!formData.hodId) return 'Please select a department';
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
    
    if (roleError) {
      setErrors(prev => ({ ...prev, general: roleError }));
      return false;
    }
    
    // File upload is optional for coordinators and supervisors
    const fileError = (role === 'coordinator' || role === 'supervisor') ? '' : validateVerificationFile(formData.verificationFile);
    
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
      // 1. Upload verification file to Cloudinary first if it exists
      let verificationDocumentUrl = '';
      if (formData.verificationFile) {
        // Use a generic folder for registration verification docs
        const folder = `internlink/registration-verifications`;
        const uploadResult = await cloudinaryService.uploadDocument(formData.verificationFile, folder);
        
        if (uploadResult.success && uploadResult.url) {
          verificationDocumentUrl = uploadResult.url;
        } else {
          const errorMsg = uploadResult.error || 'Failed to upload verification document';
          console.error('Upload failed:', errorMsg);
          throw new Error(`Document upload failed: ${errorMsg}. Please check your Cloudinary configuration.`);
        }
      }

      const registerData = {
        fullName: formData.fullName,
        email: formData.email,
        password: formData.password,
        role: role!,
        ...(role === 'coordinator' && {
          universityId: formData.universityId,
        }),
        ...(role === 'hod' && {
          universityId: formData.universityId,
          department: formData.department,
          employeeId: formData.employeeId,
        }),
        ...(role === 'supervisor' && {
          companyName: formData.companyName,
          position: formData.position,
        }),
        ...(role === 'student' && {
          universityId: formData.universityId,
          hodId: formData.hodId,
          studentId: formData.studentId,
        }),
        verificationDocument: verificationDocumentUrl || undefined,
      };
      
      const result = await register(registerData);
      
      // Redirect to verify-email page (no token in URL — token is only in the email link)
      const roleParam = role === 'coordinator' ? '&role=coordinator' : role === 'hod' ? '&role=hod' : role === 'student' ? '&role=student' : role === 'supervisor' ? '&role=supervisor' : '';
      router.push(`/verify-email?email=${encodeURIComponent(formData.email)}${roleParam}`);
      
    } catch (error: unknown) {
      const err = error as { message?: string };
      setErrors({
        general: err?.message || 'Registration failed. Please try again.'
      });
    } finally {
      setIsLoading(false);
    }
  };

  const coordinatorUploadLocked = role === 'coordinator' && !formData.universityId;

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Progress Header */}
      <div className="space-y-2">
        <div className="flex justify-between text-xs font-bold uppercase tracking-widest text-slate-400 dark:text-slate-500">
          <span>Step {step} of 3</span>
          <span>
            {step === 1 ? 'Role Selection' : step === 2 ? 'Account Details' : 'Verification'}
          </span>
        </div>
        <div className="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden dark:bg-slate-800">
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
            <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">Choose your role</h1>
            <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
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
              },
              { 
                id: 'coordinator' as const, 
                title: 'University Coordinator', 
                icon: School, 
                desc: 'Manage student placements and university partnerships',
                color: 'bg-primary-50 text-primary-600',
              },
              {
                id: 'hod' as const,
                title: 'Head of Department',
                icon: Building,
                desc: 'Oversee departmental internship activities and approvals',
                color: 'bg-violet-50 text-violet-600',
              },
              { 
                id: 'supervisor' as const, 
                title: 'Company Supervisor', 
                icon: Briefcase, 
                desc: 'Evaluate students and verify internship reports',
                color: 'bg-slate-100 text-slate-600',
              },
            ].map((item) => {
              const isClosed = !regStatus[item.id];
              return (
                <button
                  key={item.id}
                  onClick={() => !isClosed && setRole(item.id)}
                  disabled={isClosed}
                  className={`flex items-center gap-4 p-4 rounded-2xl border-2 transition-all text-left group ${
                    isClosed
                      ? 'border-slate-100 bg-slate-50 opacity-60 cursor-not-allowed dark:border-slate-800 dark:bg-slate-900'
                      : role === item.id 
                        ? 'border-primary-600 bg-primary-50/30 shadow-soft dark:bg-primary-900/20' 
                        : 'border-slate-100 bg-white hover:border-slate-200 hover:shadow-soft dark:border-slate-800 dark:bg-slate-950 dark:hover:border-slate-700'
                  }`}
                >
                  <div className={`p-3 rounded-xl transition-all ${
                    isClosed
                      ? 'bg-slate-200 text-slate-400 dark:bg-slate-800 dark:text-slate-500'
                      : role === item.id 
                        ? 'bg-primary-600 text-white shadow-lg shadow-primary-600/20' 
                        : 'bg-slate-100 text-slate-500 group-hover:bg-primary-50 group-hover:text-primary-600 dark:bg-slate-900 dark:text-slate-400 dark:group-hover:bg-primary-900/30'
                  }`}>
                    <item.icon className="h-6 w-6" />
                  </div>
                  <div className="flex-1">
                    <p className={`font-bold ${isClosed ? 'text-slate-400 dark:text-slate-500' : 'text-slate-900 dark:text-slate-100'}`}>{item.title}</p>
                    <p className="text-xs text-slate-500 dark:text-slate-400">
                      {isClosed ? 'Registration is currently closed for this role.' : item.desc}
                    </p>
                  </div>
                  {isClosed ? (
                    <span className="shrink-0 rounded-full bg-slate-200 px-2 py-0.5 text-[10px] font-bold text-slate-500 dark:bg-slate-800 dark:text-slate-400">
                      Closed
                    </span>
                  ) : role === item.id ? (
                    <CheckCircle2 className="h-5 w-5 text-primary-600" />
                  ) : null}
                </button>
              );
            })}
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
            <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">Account Details</h1>
            <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
              Enter your official credentials
            </p>
          </div>

          <div className="space-y-4">
            {/* Full Name */}
            <div className="space-y-2">
              <label className="text-sm font-semibold text-slate-700 dark:text-slate-200">
                Full Name <span className="text-red-500">*</span>
              </label>
              <div className="relative group">
                <UserCircle className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-primary-500 transition-colors dark:text-slate-500" />
                <input
                  type="text"
                  name="fullName"
                  value={formData.fullName}
                  onChange={handleInputChange}
                  onBlur={() => handleBlur('fullName')}
                  placeholder="Enter your full name"
                  className={`w-full pl-10 pr-4 py-3 rounded-xl border bg-white text-slate-900 placeholder:text-slate-400 transition-all dark:bg-slate-900 dark:text-slate-100 dark:placeholder:text-slate-500
                    focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500
                    ${errors.fullName && touched.fullName 
                      ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20'
                      : 'border-slate-200 hover:border-slate-300 dark:border-slate-700 dark:hover:border-slate-600'
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
              <label className="text-sm font-semibold text-slate-700 dark:text-slate-200">
                Email Address <span className="text-red-500">*</span>
              </label>
              <div className="relative group">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-primary-500 transition-colors dark:text-slate-500" />
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleInputChange}
                  onBlur={() => handleBlur('email')}
                  placeholder={role === 'coordinator' ? 'Enter your university email' : 'Enter your email address'}
                  className={`w-full pl-10 pr-4 py-3 rounded-xl border bg-white text-slate-900 placeholder:text-slate-400 transition-all dark:bg-slate-900 dark:text-slate-100 dark:placeholder:text-slate-500
                    focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500
                    ${errors.email && touched.email 
                      ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20'
                      : 'border-slate-200 hover:border-slate-300 dark:border-slate-700 dark:hover:border-slate-600'
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
              <label className="text-sm font-semibold text-slate-700 dark:text-slate-200">
                Password <span className="text-red-500">*</span>
              </label>
              <div className="relative group">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-primary-500 transition-colors dark:text-slate-500" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  name="password"
                  value={formData.password}
                  onChange={handleInputChange}
                  onBlur={() => handleBlur('password')}
                  placeholder="••••••••"
                  className={`w-full pl-10 pr-12 py-3 rounded-xl border bg-white text-slate-900 placeholder:text-slate-400 transition-all dark:bg-slate-900 dark:text-slate-100 dark:placeholder:text-slate-500
                    focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500
                    ${errors.password && touched.password 
                      ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20'
                      : 'border-slate-200 hover:border-slate-300 dark:border-slate-700 dark:hover:border-slate-600'
                    }`}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:text-slate-500 dark:hover:text-slate-300"
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
                            : 'bg-slate-200 dark:bg-slate-700'
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
              <label className="text-sm font-semibold text-slate-700 dark:text-slate-200">
                Confirm Password <span className="text-red-500">*</span>
              </label>
              <div className="relative group">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 group-focus-within:text-primary-500 transition-colors dark:text-slate-500" />
                <input
                  type={showConfirmPassword ? 'text' : 'password'}
                  name="confirmPassword"
                  value={formData.confirmPassword}
                  onChange={handleInputChange}
                  onBlur={() => handleBlur('confirmPassword')}
                  placeholder="••••••••"
                  className={`w-full pl-10 pr-12 py-3 rounded-xl border bg-white text-slate-900 placeholder:text-slate-400 transition-all dark:bg-slate-900 dark:text-slate-100 dark:placeholder:text-slate-500
                    focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500
                    ${errors.confirmPassword && touched.confirmPassword 
                      ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20'
                      : 'border-slate-200 hover:border-slate-300 dark:border-slate-700 dark:hover:border-slate-600'
                    }`}
                />
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:text-slate-500 dark:hover:text-slate-300"
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
              className="flex-1 flex items-center justify-center gap-2 py-4 text-sm font-bold text-slate-500 hover:text-slate-700 transition-colors rounded-xl hover:bg-slate-50 dark:text-slate-400 dark:hover:text-slate-200 dark:hover:bg-slate-900"
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
            <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">
              {role === 'student' ? 'Student Information' : 
               role === 'coordinator' ? 'University Information' :
               role === 'hod' ? 'Department Information' :
               'Company Information'}
            </h1>
            <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
              {role === 'student' 
                ? 'Enter your academic details and upload student ID'
                : role === 'coordinator'
                ? 'Select your institution from the approved universities'
                : role === 'hod'
                ? 'Select your university, enter your department, and upload your staff ID'
                : 'Enter your company details'}
            </p>
          </div>



          {/* Role-Specific Fields */}
          <div className="space-y-4">
            {role === 'coordinator' && (
              <>
                {/* Searchable University Dropdown - REQUIRED FROM DATABASE ONLY */}
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700 dark:text-slate-200">
                    University <span className="text-red-500">* (select from list only)</span>
                  </label>
                  <div className="relative">
                    <button
                      type="button"
                      onClick={() => setUniDropdownOpen((o) => !o)}
                      className={`w-full flex items-center justify-between pl-10 pr-4 py-3 rounded-xl border bg-white text-left transition-all focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 dark:bg-slate-900 dark:text-slate-100 ${
                        errors.universityId 
                          ? 'border-red-300' 
                          : formData.universityId 
                          ? 'border-emerald-300 dark:border-emerald-700' 
                          : 'border-slate-200 hover:border-slate-300 dark:border-slate-700 dark:hover:border-slate-600'
                      }`}
                    >
                      <Building className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400 dark:text-slate-500" />
                      <span className={formData.universityId ? 'text-slate-900 dark:text-slate-100' : 'text-slate-400 dark:text-slate-500'}>
                        {formData.universityId
                          ? approvedUniversities.find((u) => u.id === formData.universityId)?.name
                          : 'Select your university'}
                      </span>
                      <ChevronDown className={`h-4 w-4 text-slate-400 dark:text-slate-500 transition-transform ${uniDropdownOpen ? 'rotate-180' : ''}`} />
                    </button>

                    {uniDropdownOpen && (
                      <div className="absolute z-20 mt-1 w-full bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl shadow-lg overflow-hidden">
                        <div className="p-2 border-b border-slate-100 dark:border-slate-700">
                          <div className="relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 dark:text-slate-500" />
                            <input
                              type="text"
                              name="universitySearch"
                              value={formData.universitySearch}
                              onChange={handleInputChange}
                              placeholder="Search universities..."
                              className="w-full pl-9 pr-4 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 dark:bg-slate-950 dark:text-slate-100"
                              autoFocus
                            />
                          </div>
                        </div>
                        <ul className="max-h-48 overflow-y-auto">
                          {approvedUniversities
                            .filter((u) =>
                              u.name.toLowerCase().includes((formData.universitySearch || '').toLowerCase())
                            )
                            .map((u) => (
                              <li key={u.id}>
                                <button
                                  type="button"
                                  onClick={() => {
                                    setFormData((prev) => ({ ...prev, universityId: u.id, universitySearch: '' }));
                                    setUniDropdownOpen(false);
                                    setErrors((prev) => ({ ...prev, universityId: '' }));
                                  }}
                                  className={`w-full text-left px-4 py-2.5 text-sm hover:bg-primary-50 dark:hover:bg-primary-900/30 hover:text-primary-700 dark:hover:text-primary-400 transition-colors ${formData.universityId === u.id ? 'bg-primary-50 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400 font-medium' : 'text-slate-700 dark:text-slate-300'}`}
                                >
                                  {u.name}
                                </button>
                              </li>
                            ))}
                          {approvedUniversities.filter((u) =>
                            u.name.toLowerCase().includes((formData.universitySearch || '').toLowerCase())
                          ).length === 0 && (
                            <li className="px-4 py-3 text-sm text-slate-400 text-center">No universities found</li>
                          )}
                        </ul>
                      </div>
                    )}
                  </div>
                  {errors.universityId && (
                    <p className="text-xs text-red-600 dark:text-red-400 flex items-center gap-1 mt-1">
                      <AlertCircle className="h-3 w-3" />
                      {errors.universityId}
                    </p>
                  )}
                </div>

                {/* Selection Required Warning */}
                {!formData.universityId && (
                  <div className="rounded-xl border border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-900/20 p-4">
                    <div className="flex items-start gap-3">
                      <AlertCircle className="h-5 w-5 text-red-600 dark:text-red-400 shrink-0 mt-0.5" />
                      <div className="flex-1">
                        <p className="text-sm font-semibold text-red-800 dark:text-red-300">University selection required</p>
                        <p className="text-xs text-red-700 dark:text-red-400 mt-1">
                          You must select an existing university from the dropdown. You cannot proceed without selecting a valid institution. Typing text alone is not a valid selection.
                        </p>
                      </div>
                    </div>
                  </div>
                )}

                {/* Can't find your institution? */}
                {formData.universitySearch && approvedUniversities.filter((u) =>
                  u.name.toLowerCase().includes((formData.universitySearch || '').toLowerCase())
                ).length === 0 && (
                  <div className="rounded-xl border border-amber-200 bg-amber-50 dark:border-amber-800 dark:bg-amber-900/20 p-4">
                    <div className="flex items-start gap-3">
                      <AlertCircle className="h-4 w-4 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
                      <div className="flex-1">
                        <p className="text-sm font-medium text-amber-800 dark:text-amber-300">Can't find your institution?</p>
                        <p className="text-xs text-amber-700 dark:text-amber-400 mt-1">
                          If your university is not listed, you can request to have it added to the system.
                        </p>
                        <button
                          type="button"
                          onClick={() => {
                            // This would navigate to an institution request form
                            // For now, we'll keep it simple and just alert
                            alert('Institution request feature coming soon. Please contact support.');
                          }}
                          className="mt-2 text-xs font-semibold text-amber-700 dark:text-amber-300 hover:text-amber-900 dark:hover:text-amber-200 underline underline-offset-2"
                        >
                          Request New Institution
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </>
            )}

            {role === 'hod' && (
              <>
                {/* Searchable University Dropdown */}
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    University <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <button
                      type="button"
                      onClick={() => setUniDropdownOpen((o) => !o)}
                      className={`w-full flex items-center justify-between pl-10 pr-4 py-3 rounded-xl border bg-white text-left transition-all focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 ${errors.universityId ? 'border-red-300' : 'border-slate-200 hover:border-slate-300'}`}
                    >
                      <Building className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
                      <span className={formData.universityId ? 'text-slate-900' : 'text-slate-400'}>
                        {formData.universityId
                          ? approvedUniversities.find((u) => u.id === formData.universityId)?.name
                          : 'Select your university'}
                      </span>
                      <ChevronDown className={`h-4 w-4 text-slate-400 transition-transform ${uniDropdownOpen ? 'rotate-180' : ''}`} />
                    </button>

                    {uniDropdownOpen && (
                      <div className="absolute z-20 mt-1 w-full bg-white border border-slate-200 rounded-xl shadow-lg overflow-hidden">
                        <div className="p-2 border-b border-slate-100">
                          <div className="relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
                            <input
                              type="text"
                              name="universitySearch"
                              value={formData.universitySearch}
                              onChange={handleInputChange}
                              placeholder="Search universities..."
                              className="w-full pl-9 pr-4 py-2 text-sm rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                              autoFocus
                            />
                          </div>
                        </div>
                        <ul className="max-h-48 overflow-y-auto">
                          {approvedUniversities
                            .filter((u) =>
                              u.name.toLowerCase().includes((formData.universitySearch || '').toLowerCase())
                            )
                            .map((u) => (
                              <li key={u.id}>
                                <button
                                  type="button"
                                  onClick={() => {
                                    setFormData((prev) => ({ ...prev, universityId: u.id, universitySearch: '' }));
                                    setUniDropdownOpen(false);
                                    setErrors((prev) => ({ ...prev, universityId: '' }));
                                  }}
                                  className={`w-full text-left px-4 py-2.5 text-sm hover:bg-primary-50 hover:text-primary-700 transition-colors ${formData.universityId === u.id ? 'bg-primary-50 text-primary-700 font-medium' : 'text-slate-700'}`}
                                >
                                  {u.name}
                                </button>
                              </li>
                            ))}
                          {approvedUniversities.filter((u) =>
                            u.name.toLowerCase().includes((formData.universitySearch || '').toLowerCase())
                          ).length === 0 && (
                            <li className="px-4 py-3 text-sm text-slate-400 text-center">No universities found</li>
                          )}
                        </ul>
                      </div>
                    )}
                  </div>
                  {errors.universityId && (
                    <p className="text-xs text-red-600 flex items-center gap-1 mt-1">
                      <AlertCircle className="h-3 w-3" />
                      {errors.universityId}
                    </p>
                  )}
                  {role === 'hod' && formData.universityId && !approvedUniversities.find((u) => u.id === formData.universityId)?.hasCoordinator && (
                    <div className="mt-2 flex items-start gap-2 rounded-xl border border-amber-200 bg-amber-50 px-3 py-2.5 text-xs text-amber-800">
                      <AlertCircle className="h-3.5 w-3.5 shrink-0 mt-0.5" />
                      <span>This university does not have a coordinator yet. Please make sure your coordinator registers and gets approved first before you register as Head of Department.</span>
                    </div>
                  )}
                </div>

                {/* Department */}
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
                      placeholder="Enter your department name"
                      className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                    />
                  </div>
                </div>

                {/* Employee ID (optional) */}
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    Employee ID <span className="text-slate-400 font-normal">(optional)</span>
                  </label>
                  <input
                    type="text"
                    name="employeeId"
                    value={formData.employeeId}
                    onChange={handleInputChange}
                    placeholder="Enter your employee ID (optional)"
                    className="w-full px-4 py-3 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                  />
                </div>
              </>
            )}

            {role === 'supervisor' && (
              <>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    Company/Organization Name <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <Briefcase className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
                    <input
                      type="text"
                      name="companyName"
                      value={formData.companyName}
                      onChange={handleInputChange}
                      placeholder="e.g., Tech Solutions Inc."
                      className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    Role/Position <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="position"
                    value={formData.position}
                    onChange={handleInputChange}
                    placeholder="e.g., Senior Engineer"
                    className="w-full px-4 py-3 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                  />
                </div>
              </>
            )}

            {role === 'student' && (
              <>
                {/* University Searchable Dropdown */}
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    University <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <button
                      type="button"
                      onClick={() => setUniDropdownOpen((o) => !o)}
                      className={`w-full flex items-center justify-between pl-10 pr-4 py-3 rounded-xl border bg-white text-left transition-all focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 ${errors.universityId ? 'border-red-300' : 'border-slate-200 hover:border-slate-300'}`}
                    >
                      <Building className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
                      <span className={formData.universityId ? 'text-slate-900' : 'text-slate-400'}>
                        {formData.universityId
                          ? approvedUniversities.find((u) => u.id === formData.universityId)?.name
                          : 'Select your university'}
                      </span>
                      <ChevronDown className={`h-4 w-4 text-slate-400 transition-transform ${uniDropdownOpen ? 'rotate-180' : ''}`} />
                    </button>
                    {uniDropdownOpen && (
                      <div className="absolute z-20 mt-1 w-full bg-white border border-slate-200 rounded-xl shadow-lg overflow-hidden">
                        <div className="p-2 border-b border-slate-100">
                          <div className="relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
                            <input
                              type="text"
                              name="universitySearch"
                              value={formData.universitySearch}
                              onChange={handleInputChange}
                              placeholder="Search universities..."
                              className="w-full pl-9 pr-4 py-2 text-sm rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                              autoFocus
                            />
                          </div>
                        </div>
                        <ul className="max-h-48 overflow-y-auto">
                          {approvedUniversities
                            .filter((u) => u.name.toLowerCase().includes((formData.universitySearch || '').toLowerCase()))
                            .map((u) => (
                              <li key={u.id}>
                                <button
                                  type="button"
                                  onClick={() => {
                                    setFormData((prev) => ({ ...prev, universityId: u.id, universitySearch: '', hodId: undefined }));
                                    setUniDropdownOpen(false);
                                    setErrors((prev) => ({ ...prev, universityId: '' }));
                                  }}
                                  className={`w-full text-left px-4 py-2.5 text-sm hover:bg-primary-50 hover:text-primary-700 transition-colors ${formData.universityId === u.id ? 'bg-primary-50 text-primary-700 font-medium' : 'text-slate-700'}`}
                                >
                                  {u.name}
                                </button>
                              </li>
                            ))}
                          {approvedUniversities.filter((u) => u.name.toLowerCase().includes((formData.universitySearch || '').toLowerCase())).length === 0 && (
                            <li className="px-4 py-3 text-sm text-slate-400 text-center">No universities found</li>
                          )}
                        </ul>
                      </div>
                    )}
                  </div>
                  {errors.universityId && (
                    <p className="text-xs text-red-600 flex items-center gap-1 mt-1">
                      <AlertCircle className="h-3 w-3" />{errors.universityId}
                    </p>
                  )}
                </div>

                {/* Department Dropdown — populated after university selected */}
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    Department <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <GraduationCap className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
                    <select
                      value={formData.hodId ?? ''}
                      onChange={(e) => {
                        const val = e.target.value ? parseInt(e.target.value, 10) : undefined;
                        setFormData((prev) => ({ ...prev, hodId: val }));
                        setErrors((prev) => ({ ...prev, hodId: '' }));
                      }}
                      disabled={!formData.universityId || deptLoading}
                      className={`w-full pl-10 pr-4 py-3 rounded-xl border bg-white text-slate-900 appearance-none transition-all focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 disabled:opacity-50 disabled:cursor-not-allowed ${errors.hodId ? 'border-red-300' : 'border-slate-200 hover:border-slate-300'}`}
                    >
                      <option value="">
                        {!formData.universityId
                          ? 'Select a university first'
                          : deptLoading
                          ? 'Loading departments...'
                          : departments.length === 0
                          ? 'No departments available'
                          : 'Select your department'}
                      </option>
                      {departments.map((d) => (
                        <option key={d.id} value={d.id}>{d.department}</option>
                      ))}
                    </select>
                    <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 pointer-events-none" />
                  </div>
                  {errors.hodId && (
                    <p className="text-xs text-red-600 flex items-center gap-1 mt-1">
                      <AlertCircle className="h-3 w-3" />{errors.hodId}
                    </p>
                  )}
                </div>

                {/* Student ID */}
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-700">
                    Student ID <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="studentId"
                    value={formData.studentId}
                    onChange={handleInputChange}
                    placeholder="Enter your student ID"
                    className="w-full px-4 py-3 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                  />
                </div>
              </>
            )}
          </div>

          {/* File Upload - Optional for coordinators, hidden for supervisors, required for others */}
          {role !== 'supervisor' && (
            <div className="space-y-2">
              <label className={`text-sm font-semibold ${
                role === 'coordinator' && !formData.universityId 
                  ? 'text-slate-400 dark:text-slate-500' 
                  : 'text-slate-700 dark:text-slate-200'
              }`}>
                {role === 'student' ? 'Student ID / Verification' : 
                 role === 'coordinator' ? 'Official University Letter with Stamp (Optional)' :
                 'Staff ID / Verification Document'} {role !== 'coordinator' && <span className="text-red-500">*</span>}
              </label>
              
              {/* Disabled state message for coordinators without selection */}
              {role === 'coordinator' && !formData.universityId && (
                <div className="rounded-xl border border-slate-300 dark:border-slate-600 bg-slate-100 dark:bg-slate-800/50 p-4 text-center">
                  <p className="text-sm text-slate-600 dark:text-slate-400 font-medium">
                    ℹ️ File upload is disabled until you select a valid university
                  </p>
                </div>
              )}
              
              {!formData.verificationFile ? (
                <label
                  className={`border-2 border-dashed rounded-2xl p-8 flex flex-col items-center justify-center transition-all ${
                    coordinatorUploadLocked
                      ? 'border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-900/30 cursor-not-allowed opacity-50 pointer-events-none'
                      : 'border-slate-200 dark:border-slate-700 bg-slate-50 hover:bg-slate-100 dark:bg-slate-900/50 dark:hover:bg-slate-800/50 hover:border-primary-300 dark:hover:border-primary-700 cursor-pointer group'
                  }`}
                  aria-disabled={coordinatorUploadLocked}
                >
                  <input
                    type="file"
                    accept=".pdf,.jpg,.jpeg,.png"
                    onChange={handleFileChange}
                    disabled={coordinatorUploadLocked}
                    className="hidden"
                  />
                  <div className={`h-14 w-14 rounded-full shadow-sm flex items-center justify-center transition-colors mb-4 ${
                    coordinatorUploadLocked
                      ? 'bg-slate-200 dark:bg-slate-700 text-slate-400 dark:text-slate-500'
                      : 'bg-white dark:bg-slate-900 text-slate-400 dark:text-slate-500 group-hover:text-primary-600 dark:group-hover:text-primary-400'
                  }`}>
                    <Upload className="h-7 w-7" />
                  </div>
                  <p className={`text-sm font-bold ${
                    coordinatorUploadLocked
                      ? 'text-slate-600 dark:text-slate-400'
                      : 'text-slate-900 dark:text-slate-100'
                  }`}>Click to upload or drag and drop</p>
                  <p className={`text-xs mt-1 ${
                    coordinatorUploadLocked
                      ? 'text-slate-500 dark:text-slate-500'
                      : 'text-slate-500 dark:text-slate-400'
                  }`}>PDF, JPG or PNG (max. 5MB)</p>
                  {role !== 'coordinator' && (
                    <p className="text-xs text-slate-400 dark:text-slate-500 mt-2">Official document with institutional stamp required</p>
                  )}
                </label>
              ) : (
                <div className="border-2 border-primary-200 dark:border-primary-800 rounded-2xl p-4 bg-primary-50/30 dark:bg-primary-900/20">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-primary-100 dark:bg-primary-900/50 rounded-lg">
                        <FileText className="h-6 w-6 text-primary-600 dark:text-primary-400" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-slate-900 dark:text-slate-100">
                          {formData.verificationFile.name}
                        </p>
                        <p className="text-xs text-slate-500 dark:text-slate-400">
                          {(formData.verificationFile.size / 1024 / 1024).toFixed(2)} MB
                        </p>
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={removeFile}
                      className="p-1 hover:bg-slate-200 dark:hover:bg-slate-700 rounded-lg transition-colors"
                    >
                      <X className="h-5 w-5 text-slate-500 dark:text-slate-400" />
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
                <p className="text-xs text-red-600 dark:text-red-400 flex items-center gap-1 mt-1">
                  <AlertCircle className="h-3 w-3" />
                  {errors.verificationFile}
                </p>
              )}
            </div>
          )}

          {/* Terms and Conditions */}
          <div className="flex items-start gap-3 pt-2">
            <input
              type="checkbox"
              id="terms"
              checked={agreedToTerms}
              onChange={(e) => setAgreedToTerms(e.target.checked)}
              className="mt-0.5 h-4 w-4 rounded border-slate-300 text-primary-600 focus:ring-primary-500"
            />
            <label htmlFor="terms" className="text-sm text-slate-600 dark:text-slate-400">
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
              className="flex-1 flex items-center justify-center gap-2 py-4 text-sm font-bold text-slate-500 hover:text-slate-700 transition-colors rounded-xl hover:bg-slate-50 dark:text-slate-400 dark:hover:text-slate-200 dark:hover:bg-slate-900"
            >
              <ArrowLeft className="h-4 w-4" />
              Back
            </button>
            <button
              onClick={handleSubmit}
              disabled={isLoading || authLoading || (role === 'coordinator' && !formData.universityId)}
              className="flex-[2] flex items-center justify-center gap-2 rounded-xl bg-primary-600 py-4 text-sm font-bold text-white shadow-lg shadow-primary-600/20 transition-all hover:bg-primary-700 disabled:opacity-70 disabled:cursor-not-allowed"
              title={role === 'coordinator' && !formData.universityId ? 'Please select a valid university from the dropdown first' : ''}
            >
              {isLoading || authLoading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Creating Account...
                </>
              ) : role === 'coordinator' && !formData.universityId ? (
                <>
                  <AlertCircle className="h-4 w-4" />
                  Select University to Continue
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
      <p className="text-center text-sm text-slate-500 pt-4 dark:text-slate-400">
        Already have an account?{' '}
        <Link 
          href="/login" 
          className="font-bold text-primary-600 hover:text-primary-700 underline underline-offset-4 transition-colors"
        >
          Sign In
        </Link>
      </p>
      <p className="text-center pt-1">
        <button
          type="button"
          onClick={() => setShowSupport(true)}
          className="text-xs text-slate-400 hover:text-primary-600 transition-colors dark:text-slate-500 dark:hover:text-primary-400"
        >
          Having trouble? Contact support
        </button>
      </p>
      <ContactSupportModal open={showSupport} onClose={() => setShowSupport(false)} />
    </div>
  );
};

export default RegisterPage;