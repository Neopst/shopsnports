"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.calculateCommission = calculateCommission;
exports.calculatePayoutBreakdown = calculatePayoutBreakdown;
/**
 * Calculate commission for a payout based on commission settings
 *
 * @param db Firestore instance
 * @param grossAmount Gross amount before commission
 * @param recipientType Type of recipient (affiliate, shipper, vendor)
 * @param recipientId Optional specific entity ID for custom rates
 * @returns Commission calculation result
 */
async function calculateCommission(db, grossAmount, recipientType, recipientId) {
    try {
        // Try to get entity-specific commission setting first
        let applicableSetting = null;
        if (recipientId) {
            const entitySpecificSnapshot = await db
                .collection('commission_settings')
                .where('entity_type', '==', recipientType)
                .where('entity_id', '==', recipientId)
                .where('is_active', '==', true)
                .limit(1)
                .get();
            if (!entitySpecificSnapshot.empty) {
                applicableSetting = entitySpecificSnapshot.docs[0].data();
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
                applicableSetting = defaultSnapshot.docs[0].data();
            }
        }
        // If still no setting, use default rates
        if (!applicableSetting) {
            const defaultRates = {
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
            const defaultRates = {
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
            const defaultRates = {
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
        let commissionAmount;
        let platformFee;
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
                }
                else {
                    // Outside tier, use default
                    const defaultRates = {
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
                const defaultRates = {
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
    }
    catch (error) {
        console.error('Error calculating commission:', error);
        // Return default commission on error to prevent blocking payouts
        const defaultRates = {
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
async function calculatePayoutBreakdown(db, grossAmount, recipientType, recipientId, country) {
    // Calculate commission
    const commissionResult = await calculateCommission(db, grossAmount, recipientType, recipientId);
    // Calculate tax on commission amount (not gross amount)
    const { calculateTax } = await Promise.resolve().then(() => __importStar(require('./taxCalculation')));
    const taxResult = await calculateTax(db, commissionResult.commissionAmount, recipientType, country);
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
