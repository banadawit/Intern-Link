import crypto from 'crypto';

/**
 * Generate a random verification token
 * @returns {string} 64-character hex string
 */
export const generateVerificationToken = (): string => {
  return crypto.randomBytes(32).toString('hex');
};

/**
 * Get token expiry date (24 hours from now)
 * @returns {Date} Expiry date
 */
export const getVerificationTokenExpiry = (): Date => {
  const expiry = new Date();
  expiry.setHours(expiry.getHours() + 24);
  return expiry;
};

/**
 * Check if token is expired
 * @param {Date} expiryDate - Token expiry date
 * @returns {boolean} True if expired
 */
export const isTokenExpired = (expiryDate: Date): boolean => {
  return new Date() > expiryDate;
};

/**
 * Generate a random password reset token
 * @returns {string} 64-character hex string
 */
export const generateResetToken = (): string => {
  return crypto.randomBytes(32).toString('hex');
};

/**
 * Get reset token expiry date (1 hour from now)
 * @returns {Date} Expiry date
 */
export const getResetTokenExpiry = (): Date => {
  const expiry = new Date();
  expiry.setHours(expiry.getHours() + 1);
  return expiry;
};