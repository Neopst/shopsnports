import * as admin from 'firebase-admin';

/**
 * Payment Service for Payout Processing
 *
 * Supports multiple payment providers:
 * - Stripe (for card/bank transfers)
 * - PayPal (for PayPal payouts)
 * - Manual (for bank transfers/checks)
 */

export interface PaymentProvider {
  name: string;
  processPayout(payoutData: PayoutData): Promise<PaymentResult>;
}

export interface PayoutData {
  payoutId: string;
  payoutNumber: string;
  amount: number;
  currency: string;
  recipientName: string;
  recipientEmail: string;
  recipientType: 'affiliate' | 'shipper' | 'vendor';
  recipientId: string;
  bankAccountDetails?: BankAccountDetails;
  paymentMethod: string;
  notes?: string;
}

export interface BankAccountDetails {
  accountNumber?: string;
  routingNumber?: string;
  bankName?: string;
  accountType?: 'checking' | 'savings';
  country?: string;
}

export interface PaymentResult {
  success: boolean;
  transactionId?: string;
  transactionReference?: string;
  status: 'pending' | 'completed' | 'failed' | 'cancelled';
  errorMessage?: string;
  metadata?: Record<string, any>;
}

/**
 * Manual Payment Provider
 * Used for bank transfers, checks, or other manual payment methods
 */
class ManualPaymentProvider implements PaymentProvider {
  name = 'manual';

  async processPayout(payoutData: PayoutData): Promise<PaymentResult> {
    // Manual payments don't require API calls
    // They just generate a reference number for tracking
    const transactionReference = `MANUAL-${Date.now()}-${payoutData.payoutNumber}`;

    return {
      success: true,
      transactionReference,
      status: 'completed',
      metadata: {
        processedAt: new Date().toISOString(),
        paymentMethod: 'manual',
      },
    };
  }
}

/**
 * Stripe Payment Provider
 * For automated bank transfers and card payouts
 */
class StripePaymentProvider implements PaymentProvider {
  name = 'stripe';
  private apiKey: string;

  constructor(apiKey?: string) {
    this.apiKey = apiKey || process.env.STRIPE_SECRET_KEY || '';
  }

  async processPayout(payoutData: PayoutData): Promise<PaymentResult> {
    if (!this.apiKey) {
      return {
        success: false,
        status: 'failed',
        errorMessage: 'Stripe API key not configured',
      };
    }

    try {
      // Note: This is a placeholder for Stripe API integration
      // In production, you would use the Stripe SDK:
      // const stripe = require('stripe')(this.apiKey);
      // const payout = await stripe.payouts.create({...});

      // For now, simulate a successful payout
      const transactionId = `pi_${Date.now()}_${Math.random().toString(36).substring(7)}`;

      return {
        success: true,
        transactionId,
        transactionReference: transactionId,
        status: 'completed',
        metadata: {
          provider: 'stripe',
          processedAt: new Date().toISOString(),
        },
      };
    } catch (error: any) {
      return {
        success: false,
        status: 'failed',
        errorMessage: error.message || 'Stripe payout failed',
      };
    }
  }
}

/**
 * PayPal Payment Provider
 * For PayPal payouts
 */
class PayPalPaymentProvider implements PaymentProvider {
  name = 'paypal';
  private clientId: string;
  private clientSecret: string;

  constructor(clientId?: string, clientSecret?: string) {
    this.clientId = clientId || process.env.PAYPAL_CLIENT_ID || '';
    this.clientSecret = clientSecret || process.env.PAYPAL_CLIENT_SECRET || '';
  }

  async processPayout(payoutData: PayoutData): Promise<PaymentResult> {
    if (!this.clientId || !this.clientSecret) {
      return {
        success: false,
        status: 'failed',
        errorMessage: 'PayPal credentials not configured',
      };
    }

    try {
      // Note: This is a placeholder for PayPal API integration
      // In production, you would use the PayPal SDK:
      // const payout = await paypal.payouts.create({...});

      // For now, simulate a successful payout
      const transactionId = `PAYPAL-${Date.now()}-${Math.random().toString(36).substring(7)}`;

      return {
        success: true,
        transactionId,
        transactionReference: transactionId,
        status: 'completed',
        metadata: {
          provider: 'paypal',
          processedAt: new Date().toISOString(),
        },
      };
    } catch (error: any) {
      return {
        success: false,
        status: 'failed',
        errorMessage: error.message || 'PayPal payout failed',
      };
    }
  }
}

/**
 * Payment Service Factory
 * Creates payment provider instances based on configuration
 */
export class PaymentService {
  private providers: Map<string, PaymentProvider> = new Map();
  private db: admin.firestore.Firestore;

  constructor(db: admin.firestore.Firestore) {
    this.db = db;

    // Register default providers
    this.registerProvider(new ManualPaymentProvider());
    this.registerProvider(new StripePaymentProvider());
    this.registerProvider(new PayPalPaymentProvider());
  }

  registerProvider(provider: PaymentProvider): void {
    this.providers.set(provider.name, provider);
  }

  getProvider(name: string): PaymentProvider | undefined {
    return this.providers.get(name);
  }

  /**
   * Process a payout using the specified payment provider
   */
  async processPayout(
    payoutData: PayoutData,
    providerName: string = 'manual'
  ): Promise<PaymentResult> {
    const provider = this.getProvider(providerName);

    if (!provider) {
      return {
        success: false,
        status: 'failed',
        errorMessage: `Payment provider '${providerName}' not found`,
      };
    }

    return await provider.processPayout(payoutData);
  }

  /**
   * Get available payment providers
   */
  getAvailableProviders(): string[] {
    return Array.from(this.providers.keys());
  }

  /**
   * Validate bank account details
   */
  validateBankAccountDetails(details: BankAccountDetails): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (!details.accountNumber || details.accountNumber.length < 4) {
      errors.push('Account number is required');
    }

    if (!details.routingNumber || details.routingNumber.length !== 9) {
      errors.push('Routing number must be 9 digits');
    }

    if (!details.bankName) {
      errors.push('Bank name is required');
    }

    if (!details.accountType || !['checking', 'savings'].includes(details.accountType)) {
      errors.push('Account type must be checking or savings');
    }

    return {
      valid: errors.length === 0,
      errors,
    };
  }

  /**
   * Get payment provider settings from Firestore
   */
  async getPaymentSettings(): Promise<Record<string, any>> {
    const doc = await this.db.collection('settings').doc('payment').get();

    if (!doc.exists) {
      return {
        defaultProvider: 'manual',
        providers: {
          manual: { enabled: true },
          stripe: { enabled: false },
          paypal: { enabled: false },
        },
      };
    }

    return doc.data() as Record<string, any>;
  }

  /**
   * Update payment provider settings
   */
  async updatePaymentSettings(settings: Record<string, any>): Promise<void> {
    await this.db.collection('settings').doc('payment').set(settings, { merge: true });
  }
}

/**
 * Create payment service instance
 */
export function createPaymentService(db: admin.firestore.Firestore): PaymentService {
  return new PaymentService(db);
}