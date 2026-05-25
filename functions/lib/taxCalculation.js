"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.calculateTax = calculateTax;
exports.calculateTaxBreakdown = calculateTaxBreakdown;
/**
 * Calculate tax for a payout based on tax settings
 *
 * @param db Firestore instance
 * @param amount Gross amount before tax
 * @param recipientType Type of recipient (affiliate, shipper, vendor)
 * @param country Optional country code for location-based tax
 * @returns Tax calculation result
 */
async function calculateTax(db, amount, recipientType, country) {
    try {
        // Get active tax settings that apply to this recipient type
        const taxSettingsSnapshot = await db
            .collection('tax_settings')
            .where('is_active', '==', true)
            .where('applies_to', 'in', ['all', recipientType])
            .get();
        if (taxSettingsSnapshot.empty) {
            // No tax settings found, return zero tax
            return {
                taxAmount: 0,
                taxRate: 0,
                taxName: 'No Tax',
                taxType: 'none',
            };
        }
        // Find applicable tax setting
        let applicableTax = null;
        const now = new Date();
        for (const doc of taxSettingsSnapshot.docs) {
            const taxSetting = doc.data();
            // Check effective date range
            const effectiveFrom = taxSetting.effective_from?.toDate();
            const effectiveTo = taxSetting.effective_to?.toDate();
            if (effectiveFrom && effectiveFrom > now) {
                continue; // Not yet effective
            }
            if (effectiveTo && effectiveTo < now) {
                continue; // Expired
            }
            // Check country/region match if specified
            if (country && taxSetting.country) {
                if (taxSetting.country !== country) {
                    continue; // Country doesn't match
                }
            }
            // Use this tax setting (first match wins)
            applicableTax = taxSetting;
            break;
        }
        if (!applicableTax) {
            return {
                taxAmount: 0,
                taxRate: 0,
                taxName: 'No Tax',
                taxType: 'none',
            };
        }
        // Calculate tax amount
        const taxRate = applicableTax.tax_rate || 0;
        const taxAmount = (amount * taxRate) / 100;
        return {
            taxAmount: Math.round(taxAmount * 100) / 100, // Round to 2 decimal places
            taxRate,
            taxName: applicableTax.tax_name || 'Tax',
            taxType: applicableTax.tax_type || 'unknown',
        };
    }
    catch (error) {
        console.error('Error calculating tax:', error);
        // Return zero tax on error to prevent blocking payouts
        return {
            taxAmount: 0,
            taxRate: 0,
            taxName: 'No Tax',
            taxType: 'none',
        };
    }
}
/**
 * Calculate tax breakdown for multiple tax types
 * (e.g., VAT + withholding tax)
 *
 * @param db Firestore instance
 * @param amount Gross amount before tax
 * @param recipientType Type of recipient
 * @param country Optional country code
 * @returns Array of tax calculations
 */
async function calculateTaxBreakdown(db, amount, recipientType, country) {
    try {
        const taxSettingsSnapshot = await db
            .collection('tax_settings')
            .where('is_active', '==', true)
            .where('applies_to', 'in', ['all', recipientType])
            .get();
        if (taxSettingsSnapshot.empty) {
            return [];
        }
        const results = [];
        const now = new Date();
        for (const doc of taxSettingsSnapshot.docs) {
            const taxSetting = doc.data();
            // Check effective date range
            const effectiveFrom = taxSetting.effective_from?.toDate();
            const effectiveTo = taxSetting.effective_to?.toDate();
            if (effectiveFrom && effectiveFrom > now) {
                continue;
            }
            if (effectiveTo && effectiveTo < now) {
                continue;
            }
            // Check country/region match if specified
            if (country && taxSetting.country) {
                if (taxSetting.country !== country) {
                    continue;
                }
            }
            // Calculate tax for this setting
            const taxRate = taxSetting.tax_rate || 0;
            const taxAmount = (amount * taxRate) / 100;
            results.push({
                taxAmount: Math.round(taxAmount * 100) / 100,
                taxRate,
                taxName: taxSetting.tax_name || 'Tax',
                taxType: taxSetting.tax_type || 'unknown',
            });
        }
        return results;
    }
    catch (error) {
        console.error('Error calculating tax breakdown:', error);
        return [];
    }
}
