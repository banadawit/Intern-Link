'use client';

import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { type Locale, DEFAULT_LOCALE, getStoredLocale, setStoredLocale } from '@/lib/i18n';

type Messages = Record<string, Record<string, unknown>>;

interface I18nContextValue {
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: (namespace: string, key: string) => string;
  raw: (namespace: string, key: string) => unknown;
}

const I18nContext = createContext<I18nContextValue>({
  locale: DEFAULT_LOCALE,
  setLocale: () => {},
  t: (_ns, key) => key,
  raw: (_ns, key) => key,
});

export function useI18n() {
  return useContext(I18nContext);
}

/** Minimal hook that mimics next-intl's useTranslations(namespace) */
export function useTranslations(namespace: string) {
  const { t, raw } = useI18n();

  const fn = (key: string, params?: Record<string, string | number>) => {
    const str = t(namespace, key);
    if (!params) return str;

    // Handle ICU plural: {count, plural, one {# item} other {# items}}
    const resolved = str.replace(
      /\{(\w+),\s*plural,\s*((?:(?:zero|one|two|few|many|other|=\d+)\s*\{[^}]*\}\s*)+)\}/g,
      (_match, paramName, cases) => {
        const count = Number(params[paramName] ?? 0);
        // Parse cases into a map
        const caseMap: Record<string, string> = {};
        const caseRegex = /(zero|one|two|few|many|other|=\d+)\s*\{([^}]*)\}/g;
        let m: RegExpExecArray | null;
        while ((m = caseRegex.exec(cases)) !== null) {
          caseMap[m[1]] = m[2];
        }
        // Pick the right case
        const exactKey = `=${count}`;
        let chosen = caseMap[exactKey];
        if (!chosen) {
          if (count === 0 && caseMap['zero']) chosen = caseMap['zero'];
          else if (count === 1 && caseMap['one']) chosen = caseMap['one'];
          else if (count === 2 && caseMap['two']) chosen = caseMap['two'];
          else chosen = caseMap['other'] ?? String(count);
        }
        // Replace # with the count
        return chosen.replace(/#/g, String(count));
      }
    );

    // Replace remaining {param} placeholders
    return resolved.replace(/\{(\w+)\}/g, (_, k) => String(params[k] ?? `{${k}}`));
  };

  fn.raw = (key: string) => raw(namespace, key);
  return fn;
}

async function loadMessages(locale: Locale): Promise<Messages> {
  try {
    switch (locale) {
      case 'am': return (await import('../../../messages/am.json')).default as unknown as Messages;
      case 'om': return (await import('../../../messages/om.json')).default as unknown as Messages;
      default:   return (await import('../../../messages/en.json')).default as unknown as Messages;
    }
  } catch {
    return {};
  }
}

export default function I18nProvider({ children }: { children: React.ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>(DEFAULT_LOCALE);
  const [messages, setMessages] = useState<Messages>({});
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const stored = getStoredLocale();
    setLocaleState(stored);
    loadMessages(stored).then((m) => { setMessages(m); setReady(true); });
  }, []);

  const setLocale = useCallback((newLocale: Locale) => {
    setStoredLocale(newLocale);
    setLocaleState(newLocale);
    loadMessages(newLocale).then(setMessages);
  }, []);

  const t = useCallback((namespace: string, key: string): string => {
    // Support dotted namespaces: 'Auth.register' → messages.Auth.register
    const ns = namespace.split('.').reduce<unknown>((obj, k) => {
      if (obj && typeof obj === 'object') return (obj as Record<string, unknown>)[k];
      return undefined;
    }, messages);
    if (!ns || typeof ns !== 'object') return key;
    // Support dotted keys: 'roles.student' → ns.roles.student
    const val = key.split('.').reduce<unknown>((obj, k) => {
      if (obj && typeof obj === 'object') return (obj as Record<string, unknown>)[k];
      return undefined;
    }, ns);
    return typeof val === 'string' ? val : key;
  }, [messages]);

  const raw = useCallback((namespace: string, key: string): unknown => {
    const ns = namespace.split('.').reduce<unknown>((obj, k) => {
      if (obj && typeof obj === 'object') return (obj as Record<string, unknown>)[k];
      return undefined;
    }, messages);
    if (!ns || typeof ns !== 'object') return key;
    const val = key.split('.').reduce<unknown>((obj, k) => {
      if (obj && typeof obj === 'object') return (obj as Record<string, unknown>)[k];
      return undefined;
    }, ns);
    return val ?? key;
  }, [messages]);

  if (!ready) return null;

  return (
    <I18nContext.Provider value={{ locale, setLocale, t, raw }}>
      {children}
    </I18nContext.Provider>
  );
}
