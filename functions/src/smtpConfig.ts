import * as functions from 'firebase-functions';

/**
 * SMTP Configuration Service
 *
 * Uses Firebase Functions config for secure SMTP credentials
 * instead of hardcoded environment variables
 *
 * Setup:
 * firebase functions:config:set smtp.host="smtp.example.com" smtp.port="587" smtp.user="noreply@example.com" smtp.pass="password" smtp.secure="false"
 */

export interface SmtpConfig {
  host: string;
  port: number;
  user: string;
  pass: string;
  secure: boolean;
}

/**
 * Get SMTP configuration from Firebase Functions config
 * Falls back to environment variables for development
 */
export function getSmtpConfig(): SmtpConfig {
  const functionsConfig = functions.config();

  // Try Firebase Functions config first (production)
  if (functionsConfig.smtp) {
    return {
      host: functionsConfig.smtp.host || 'smtp.gmail.com',
      port: parseInt(functionsConfig.smtp.port || '587', 10),
      user: functionsConfig.smtp.user || 'noreply@shopsnports.com',
      pass: functionsConfig.smtp.pass || '',
      secure: (functionsConfig.smtp.secure || 'false') === 'true',
    };
  }

  // Fallback to environment variables (development only)
  return {
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    user: process.env.SMTP_USER || 'noreply@shopsnports.com',
    pass: process.env.SMTP_PASS || '',
    secure: (process.env.SMTP_SECURE || 'false') === 'true',
  };
}

/**
 * Validate SMTP configuration
 */
export function validateSmtpConfig(config: SmtpConfig): { valid: boolean; error?: string } {
  if (!config.host) {
    return { valid: false, error: 'SMTP host is required' };
  }

  if (!config.port || config.port < 1 || config.port > 65535) {
    return { valid: false, error: 'SMTP port must be between 1 and 65535' };
  }

  if (!config.user) {
    return { valid: false, error: 'SMTP user is required' };
  }

  if (!config.pass) {
    return { valid: false, error: 'SMTP password is required' };
  }

  return { valid: true };
}

/**
 * Create nodemailer transporter from SMTP config
 */
export function createSmtpTransporter(nodemailer: any) {
  const config = getSmtpConfig();
  const validation = validateSmtpConfig(config);

  if (!validation.valid) {
    console.error('❌ Invalid SMTP configuration:', validation.error);
    throw new Error(validation.error);
  }

  return nodemailer.createTransport({
    host: config.host,
    port: config.port,
    secure: config.secure,
    auth: {
      user: config.user,
      pass: config.pass,
    },
  });
}