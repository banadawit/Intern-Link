/**
 * next-intl shim — re-exports our local useTranslations so all files that
 * import from 'next-intl' can be redirected here via tsconfig path alias.
 */
export { useTranslations } from '@/components/i18n/I18nProvider';
