'use client';

import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { NextIntlClientProvider, type AbstractIntlMessages } from 'next-intl';
import { type Locale, DEFAULT_LOCALE, getStoredLocale, setStoredLocale } from '@/lib/i18n';

interface I18nContextValue {
  locale: Locale;
  setLocale: (locale: Locale) => void;
}

const I18nContext = createContext<I18nContextValue>({
  locale: DEFAULT_LOCALE,
  setLocale: () => {},
});

export function useI18n() {
  return useContext(I18nContext);
}

async function loadMessages(locale: Locale): Promise<AbstractIntlMessages> {
  switch (locale) {
    case 'am': return (await import('../../../messages/am.json')).default as unknown as AbstractIntlMessages;
    case 'om': return (await import('../../../messages/om.json')).default as unknown as AbstractIntlMessages;
    default:   return (await import('../../../messages/en.json')).default as unknown as AbstractIntlMessages;
  }
}

export default function I18nProvider({ children }: { children: React.ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>(DEFAULT_LOCALE);
  const [messages, setMessages] = useState<AbstractIntlMessages | null>(null);

  useEffect(() => {
    const stored = getStoredLocale();
    setLocaleState(stored);
    loadMessages(stored).then(setMessages);
  }, []);

  const setLocale = useCallback((newLocale: Locale) => {
    setStoredLocale(newLocale);
    setLocaleState(newLocale);
    loadMessages(newLocale).then(setMessages);
  }, []);

  if (!messages) return null;

  return (
    <I18nContext.Provider value={{ locale, setLocale }}>
      <NextIntlClientProvider locale={locale} messages={messages}>
        {children}
      </NextIntlClientProvider>
    </I18nContext.Provider>
  );
}
