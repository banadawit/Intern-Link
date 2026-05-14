'use client';

import { useState, useRef, useEffect, useCallback } from 'react';
import { createPortal } from 'react-dom';
import { Globe } from 'lucide-react';
import { useI18n, useTranslations } from '@/components/i18n/I18nProvider';
import { LOCALES, type Locale } from '@/lib/i18n';

export default function LanguageSwitcher() {
  const t = useTranslations('Language');
  const { locale, setLocale } = useI18n();
  const [open, setOpen] = useState(false);
  const [pos, setPos] = useState<{ top: number; right: number }>({ top: 0, right: 0 });
  const buttonRef = useRef<HTMLButtonElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const [mounted, setMounted] = useState(false);

  useEffect(() => { setMounted(true); }, []);

  const calcPos = useCallback(() => {
    if (!buttonRef.current) return;
    const r = buttonRef.current.getBoundingClientRect();
    setPos({ top: r.bottom + 6, right: window.innerWidth - r.right });
  }, []);

  const toggle = () => {
    if (!open) calcPos();
    setOpen((v) => !v);
  };

  useEffect(() => {
    if (!open) return;
    const handler = (e: MouseEvent) => {
      const target = e.target as Node;
      if (buttonRef.current?.contains(target) || dropdownRef.current?.contains(target)) return;
      setOpen(false);
    };
    document.addEventListener('click', handler, true);
    return () => document.removeEventListener('click', handler, true);
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const update = () => calcPos();
    window.addEventListener('scroll', update, true);
    window.addEventListener('resize', update);
    return () => {
      window.removeEventListener('scroll', update, true);
      window.removeEventListener('resize', update);
    };
  }, [open, calcPos]);

  const current = LOCALES.find((l) => l.code === locale) ?? LOCALES[0];

  return (
    <>
      <button
        ref={buttonRef}
        type="button"
        onClick={toggle}
        className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200 dark:hover:bg-slate-800"
        aria-label={t('select')}
        aria-expanded={open}
        aria-haspopup="listbox"
      >
        <Globe className="h-4 w-4 text-slate-500 dark:text-slate-400" />
        <span>{current.flag} {current.label}</span>
      </button>

      {open && mounted && createPortal(
        <div
          ref={dropdownRef}
          role="listbox"
          style={{ position: 'fixed', top: pos.top, right: pos.right, zIndex: 2147483647 }}
          className="w-44 rounded-xl border border-slate-200 bg-white py-1 shadow-lg dark:border-slate-700 dark:bg-slate-900"
        >
          {LOCALES.map((loc) => (
            <button
              key={loc.code}
              type="button"
              role="option"
              aria-selected={locale === loc.code}
              onClick={() => {
                setLocale(loc.code as Locale);
                setOpen(false);
              }}
              className={`flex w-full items-center gap-2 px-3 py-2 text-sm transition-colors hover:bg-slate-50 dark:hover:bg-slate-800 ${
                locale === loc.code
                  ? 'font-semibold text-primary-600 dark:text-teal-400'
                  : 'text-slate-700 dark:text-slate-300'
              }`}
            >
              <span>{loc.flag}</span>
              <span>{loc.label}</span>
              {locale === loc.code && (
                <span className="ml-auto h-1.5 w-1.5 rounded-full bg-primary-600 dark:bg-teal-400" />
              )}
            </button>
          ))}
        </div>,
        document.body
      )}
    </>
  );
}
