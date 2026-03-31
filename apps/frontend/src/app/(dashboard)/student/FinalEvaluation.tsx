"use client";

import React, { useEffect, useState } from 'react';
import { Download, Award, MessageSquare, TrendingUp, ShieldCheck, ExternalLink, Clock } from 'lucide-react';
import StudentPageHero from './StudentPageHero';
import { cn } from '@/lib/utils';
import { RadialBarChart, RadialBar, ResponsiveContainer, PolarAngleAxis } from 'recharts';
import api from '@/lib/api/client';
import { mapEvaluationApi, type EvaluationWithMeta } from '@/lib/api/mappers';
import { format } from 'date-fns';

const ScoreCard = ({
  label,
  score,
  color,
  icon: Icon,
}: {
  label: string;
  score: number;
  color: string;
  icon: React.ComponentType<{ className?: string }>;
}) => {
  const data = [{ name: label, value: score, fill: color }];

  return (
    <div className="card p-8 flex flex-col items-center justify-center text-center space-y-6 relative overflow-hidden">
      <div className="absolute top-0 right-0 p-4 opacity-10">
        <Icon className="w-24 h-24" />
      </div>
      <div className="w-40 h-40 relative">
        <ResponsiveContainer width="100%" height="100%">
          <RadialBarChart innerRadius="80%" outerRadius="100%" barSize={10} data={data} startAngle={90} endAngle={450}>
            <PolarAngleAxis type="number" domain={[0, 100]} angleAxisId={0} tick={false} />
            <RadialBar background dataKey="value" cornerRadius={10} angleAxisId={0} />
          </RadialBarChart>
        </ResponsiveContainer>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="text-4xl font-black text-text-heading">{score}</span>
          <span className="text-xs text-text-muted font-bold uppercase tracking-widest">/ 100</span>
        </div>
      </div>
      <div>
        <h4 className="text-lg font-bold text-text-heading">{label}</h4>
        <p className="text-sm text-text-muted">Performance evaluation score</p>
      </div>
    </div>
  );
};

const FinalEvaluation = () => {
  const [evaluation, setEvaluation] = useState<EvaluationWithMeta | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const { data } = await api.get<{ evaluation: Parameters<typeof mapEvaluationApi>[0] | null }>(
          '/reports/my-evaluation'
        );
        if (cancelled) return;
        if (data.evaluation) setEvaluation(mapEvaluationApi(data.evaluation));
        else setEvaluation(null);
      } catch {
        if (!cancelled) setEvaluation(null);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  if (loading) {
    return (
      <p className="text-sm text-text-muted py-8" role="status">
        Loading evaluation…
      </p>
    );
  }

  if (!evaluation) {
    return (
      <div className="card p-12 text-center flex flex-col items-center justify-center space-y-6 animate-in fade-in duration-500">
        <div className="p-6 bg-yellow-50 rounded-full text-status-warning">
          <Clock className="w-12 h-12" />
        </div>
        <div className="max-w-md">
          <h2 className="text-2xl font-bold mb-2">Evaluation Pending</h2>
          <p className="text-text-muted">
            Your final evaluation will appear here after your supervisor submits it in the system.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <StudentPageHero
        badge="Final evaluation"
        title="Final Evaluation"
        description="Review your performance scores and download your final internship report."
        action={
          <button type="button" className="btn-primary flex w-full items-center justify-center gap-2 sm:w-auto">
            <Download className="h-5 w-5" />
            Download Final Report
          </button>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <ScoreCard label="Technical Skills" score={evaluation.technicalScore} color="#0D9488" icon={TrendingUp} />
        <ScoreCard label="Soft Skills" score={evaluation.softSkillScore} color="#3B82F6" icon={Award} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="card p-8 lg:col-span-2">
          <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
            <MessageSquare className="w-5 h-5 text-primary-base" />
            Supervisor Comments
          </h3>
          <div className="p-6 bg-bg-secondary rounded-2xl border border-border-default italic text-text-body leading-relaxed">
            &ldquo;{evaluation.comments}&rdquo;
          </div>
          <div className="mt-8 flex items-center gap-4 p-4 rounded-xl bg-primary-light/30 border border-primary-light">
            <div className="w-12 h-12 rounded-full bg-primary-base flex items-center justify-center text-white font-bold">
              {evaluation.supervisorName
                .split(/\s+/)
                .map((n) => n[0])
                .join('')
                .slice(0, 2)
                .toUpperCase()}
            </div>
            <div>
              <p className="font-bold text-text-heading">{evaluation.supervisorName}</p>
              <p className="text-xs text-text-muted">Supervisor at {evaluation.companyName}</p>
            </div>
          </div>
        </div>

        <div className="card p-8 flex flex-col justify-between">
          <div>
            <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-primary-base" />
              Certificate Info
            </h3>
            <div className="space-y-4">
              <div className="flex justify-between text-sm">
                <span className="text-text-muted">Evaluated</span>
                <span className="font-bold">{format(new Date(evaluation.evaluatedAt), 'MMM d, yyyy')}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-text-muted">Organization</span>
                <span className="font-bold truncate max-w-[140px]">{evaluation.companyName}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-text-muted">Status</span>
                <span className={cn('font-bold text-status-success')}>Recorded</span>
              </div>
            </div>
          </div>
          <button
            type="button"
            className="w-full mt-8 py-3 rounded-xl border border-border-default hover:bg-bg-tertiary transition-all flex items-center justify-center gap-2 text-sm font-bold"
          >
            <ExternalLink className="w-4 h-4" />
            Verify on Blockchain
          </button>
        </div>
      </div>
    </div>
  );
};

export default FinalEvaluation;
