import * as admin from 'firebase-admin';

/**
 * Commission Calculation Helper
 *
 * Calculates commission based on commission settings from Firestore
 */

interface CommissionCalculationResult {
  commissionAmount: number;
  commissionRate: number;
  commissionType: string;
  platformFee: number;
}

interface CommissionSetting {
  entity_type: string;
  entity_id?: string;
  commission_type: string;
  commission_value: number;
  min_amount?: number;
  max_amount?: number;
  effective_from?: admin.firestore.Timestamp;
  effective_to?: admin.firestore.Timestamp;
  is_active: boolean;
}

/**
 * Calculate commission for a payout based on commission settings
 *
 * @param db Firestore instance
 * @param grossAmount Gross amount before commission
 * @param recipientType Type of recipient (affiliate, shipper, vendor)
 * @param recipientId Optional specific entity ID for custom rates
 * @returns Commission calculation result
 */
export async function calculateCommission(
  db: admin.firestore.Firestore,
  grossAmount: number,
  recipientType: string,
  recipientId?: string
): Promise<CommissionCalculationResult> {
  try {
    // Try to get entity-specific commission setting first
    let applicableSetting: CommissionSetting | null = null;

    if (recipientId) {
      const entitySpecificSnapshot = await db
        .collection('commission_settings')
        .where('entity_type', '==', recipientType)
        .where('entity_id', '==', recipientId)
        .where('is_active', '==', true)
        .limit(1)
        .get();

      if (!entitySpecificSnapshot.empty) {
        applicableSetting = entitySpecificSnapshot.docs[0].data() as CommissionSetting;
      }
    }

    // If no entity-specific setting, get default/global setting for this type
    if (!applicableSetting) {
      const defaultSnapshot = await db
        .collection('commission_settings')
        .where('entity_type', '==', recipientType)
        .where('is_active', '==', true)
        .where('entity_id', '==', null)
        .limit(1)
        .get();

      if (!defaultSnapshot.empty) {
        applicableSetting = defaultSnapshot.docs[0].data() as CommissionSetting;
      }
    }

    // If still no setting, use default rates
    if (!applicableSetting) {
      const defaultRates: { [key: string]: number } = {
        affiliate: 15.0,
        shipper: 10.0,
        vendor: 5.0,
      };

      const defaultRate = defaultRates[recipientType] || 10.0;
      const commissionAmount = (grossAmount * defaultRate) / 100;

      return {
        commissionAmount: Math.round(commissionAmount * 100) / 100,
        commissionRate: defaultRate,
        commissionType: 'percentage',
        platformFee: Math.round((grossAmount - commissionAmount) * 100) / 100,
      };
    }

    // Check effective date range
    const now = new Date();
    const effectiveFrom = applicableSetting.effective_from?.toDate();
    const effectiveTo = applicableSetting.effective_to?.toDate();

    if (effectiveFrom && effectiveFrom > now) {
      // Setting not yet effective, use default
      const defaultRates: { [key: string]: number } = {
        affiliate: 15.0,
        shipper: 10.0,
        vendor: 5.0,
      };

      const defaultRate = defaultRates[recipientType] || 10.0;
      const commissionAmount = (grossAmount * defaultRate) / 100;

      return {
        commissionAmount: Math.round(commissionAmount * 100) / 100,
        commissionRate: defaultRate,
        commissionType: 'percentage',
        platformFee: Math.round((grossAmount - commissionAmount) * 100) / 100,
      };
    }

    if (effectiveTo && effectiveTo < now) {
      // Setting expired, use default
      const defaultRates: { [key: string]: number } = {
        affiliate: 15.0,
        shipper: 10.0,
        vendor: 5.0,
      };

      const defaultRate = defaultRates[recipientType] || 10.0;
      const commissionAmount = (grossAmount * defaultRate) / 100;

      return {
        commissionAmount: Math.round(commissionAmount * 100) / 100,
        commissionRate: defaultRate,
        commissionType: 'percentage',
        platformFee: Math.round((grossAmount - commissionAmount) * 100) / 100,
      };
    }

    // Calculate commission based on type
    const commissionType = applicableSetting.commission_type;
    const commissionValue = applicableSetting.commission_value;
    let commissionAmount: number;
    let platformFee: number;

    switch (commissionType) {
      case 'percentage':
        commissionAmount = (grossAmount * commissionValue) / 100;
        platformFee = grossAmount - commissionAmount;
        break;

      case 'fixed':
        commissionAmount = commissionValue;
        platformFee = grossAmount - commissionAmount;
        break;

      case 'tiered':
        // For tiered, check if amount falls within range
        const minAmount = applicableSetting.min_amount ?? 0;
        const maxAmount = applicableSetting.max_amount ?? Infinity;

        if (grossAmount >= minAmount && grossAmount <= maxAmount) {
          commissionAmount = (grossAmount * commissionValue) / 100;
        } else {
          // Outside tier, use default
          const defaultRates: { [key: string]: number } = {
            affiliate: 15.0,
            shipper: 10.0,
            vendor: 5.0,
          };

          const defaultRate = defaultRates[recipientType] || 10.0;
          commissionAmount = (grossAmount * defaultRate) / 100;
        }
        platformFee = grossAmount - commissionAmount;
        break;

      default:
        // Unknown type, use default
        const defaultRates: { [key: string]: number } = {
          affiliate: 15.0,
          shipper: 10.0,
          vendor: 5.0,
        };

        const defaultRate = defaultRates[recipientType] || 10.0;
        commissionAmount = (grossAmount * defaultRate) / 100;
        platformFee = grossAmount - commissionAmount;
    }

    return {
      commissionAmount: Math.round(commissionAmount * 100) / 100,
      commissionRate: commissionType === 'fixed' ? 0 : commissionValue,
      commissionType,
      platformFee: Math.round(platformFee * 100) / 100,
    };
  } catch (error) {
    console.error('Error calculating commission:', error);
    // Return default commission on error to prevent blocking payouts
    const defaultRates: { [key: string]: number } = {
      affiliate: 15.0,
      shipper: 10.0,
      vendor: 5.0,
    };

    const defaultRate = defaultRates[recipientType] || 10.0;
    const commissionAmount = (grossAmount * defaultRate) / 100;

    return {
      commissionAmount: Math.round(commissionAmount * 100) / 100,
      commissionRate: defaultRate,
      commissionType: 'percentage',
      platformFee: Math.round((grossAmount - commissionAmount) * 100) / 100,
    };
  }
}

/**
 * Calculate complete payout breakdown including commission and tax
 *
 * @param db Firestore instance
 * @param grossAmount Gross amount
 * @param recipientType Type of recipient
 * @param recipientId Optional specific entity ID
 * @param country Optional country code for tax
 * @returns Complete payout breakdown
 */
export async function calculatePayoutBreakdown(
  db: admin.firestore.Firestore,
  grossAmount: number,
  recipientType: string,
  recipientId?: string,
  country?: string
): Promise<{
  grossAmount: number;
  commissionAmount: number;
  commissionRate: number;
  commissionType: string;
  platformFee: number;
  taxAmount: number;
  taxRate: number;
  taxName: string;
  taxType: string;
  netAmount: number;
}> {
  // Calculate commission
  const commissionResult = await calculateCommission(
    db,
    grossAmount,
    recipientType,
    recipientId
  );

  // Calculate tax on commission amount (not gross amount)
  const { calculateTax } = await import('./taxCalculation');
  const taxResult = await calculateTax(
    db,
    commissionResult.commissionAmount,
    recipientType,
    country
  );

  // Calculate net amount
  const netAmount = commissionResult.commissionAmount - taxResult.taxAmount;

  return {
    grossAmount,
    commissionAmount: commissionResult.commissionAmount,
    commissionRate: commissionResult.commissionRate,
    commissionType: commissionResult.commissionType,
    platformFee: commissionResult.platformFee,
    taxAmount: taxResult.taxAmount,
    taxRate: taxResult.taxRate,
    taxName: taxResult.taxName,
    taxType: taxResult.taxType,
    netAmount: Math.round(netAmount * 100) / 100,
  };
}