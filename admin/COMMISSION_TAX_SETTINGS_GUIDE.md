# Commission & Tax Settings Guide

## Overview
This guide explains how to configure commission rates and tax settings that the backend uses to automatically calculate payouts.

## Where to Configure Settings

### Access Point
1. Navigate to **Payouts** in the sidebar menu
2. Click the **Settings** icon (⚙️) in the top-right of the Payouts Dashboard
3. This opens the **Payout Settings** screen with two tabs:
   - **Commission Rates**
   - **Tax Settings**

## Commission Rates Configuration

### What Are Commission Rates?
Commission rates determine how much of each transaction goes to vendors, affiliates, and shippers. The backend uses these rates to automatically calculate net payouts.

### How to Add a Commission Rate
1. Go to the **Commission Rates** tab
2. Click the **"+ Add Rate"** floating button (bottom-right)
3. Fill in the form:
   - **Entity Type**: Choose who this applies to (Vendor, Affiliate, Shipper, or Global Default)
   - **Commission Type**: 
     - **Percentage**: Take X% of each transaction
     - **Fixed**: Take a fixed amount per transaction
     - **Tiered**: Variable rates based on amount ranges
   - **Commission Value**: The percentage or amount
   - **Min/Max Amount** (Optional): Only apply this rate within a certain range
   - **Active**: Toggle to enable/disable this rate

### Examples
- **Vendor Commission**: 85% (vendor gets 85%, platform keeps 15%)
- **Affiliate Commission**: 10% (affiliate gets 10% referral fee)
- **Shipper Commission**: ₦500 fixed per delivery

### How to Edit a Commission Rate
1. Find the commission rate in the list
2. Click the **Edit** icon (pencil)
3. Modify the fields
4. Click **Save**

## Tax Settings Configuration

### What Are Tax Settings?
Tax settings define which taxes are automatically deducted from payouts. Common examples include VAT, withholding tax, and sales tax.

### How to Add a Tax Setting
1. Go to the **Tax Settings** tab
2. Click the **"+ Add Tax"** floating button (bottom-right)
3. Fill in the form:
   - **Tax Name**: Descriptive name (e.g., "VAT", "Withholding Tax")
   - **Tax Type**: Choose the type of tax
     - **VAT**: Value Added Tax
     - **Withholding Tax**: Tax withheld at source
     - **Sales Tax**: Tax on sales
     - **Income Tax**: Tax on income
   - **Tax Rate**: The percentage to deduct (e.g., 7.5 for 7.5%)
   - **Applies To**: 
     - **All Entities**: Deduct from everyone
     - **Vendors Only**
     - **Affiliates Only**
     - **Shippers Only**
   - **Country/Region**: Where this tax applies
   - **Active**: Toggle to enable/disable this tax

### Examples
- **Nigerian VAT**: 7.5% applied to all entities
- **Withholding Tax**: 5% applied to vendors only
- **State Sales Tax**: 2% applied in specific region

### How to Edit a Tax Setting
1. Find the tax setting in the list
2. Click the **Edit** icon (pencil)
3. Modify the fields
4. Click **Save**

## How Backend Uses These Settings

### Automatic Payout Creation
When an order is completed, the backend automatically:

1. **Identifies the entity** (vendor, affiliate, or shipper)
2. **Fetches the applicable commission rate** from the database
3. **Fetches the applicable tax rates** from the database
4. **Calculates the payout**:
   ```
   Gross Amount = Order Total
   Platform Fee = Gross Amount × Commission Rate
   Tax Deductions = Gross Amount × (Sum of Applicable Tax Rates)
   Net Payout = Gross Amount - Platform Fee - Tax Deductions
   ```
5. **Creates a payout record** with status "pending"
6. **Admin reviews and approves** in the Payouts Dashboard

### Example Calculation
```
Order Total: ₦100,000
Vendor Commission Rate: 85% (vendor gets 85%)
Platform Fee: ₦15,000 (15%)
VAT (7.5%): ₦7,500
Withholding Tax (5%): ₦5,000
Net Payout to Vendor: ₦72,500
```

Breakdown shown in Payouts Dashboard:
- **Gross**: ₦100,000
- **Platform Fee**: -₦15,000
- **Tax**: -₦12,500
- **Net**: ₦72,500

## Backend Integration Requirements

### Database Tables
Your backend should have these tables:
- `commission_settings` - Stores commission rates
- `tax_settings` - Stores tax configurations

### API Endpoints Needed
The frontend expects these endpoints (already defined in PayoutsApiClient):

#### Commission Settings
- `GET /api/v1/commission-settings` - List all commission rates
- `POST /api/v1/commission-settings` - Create new commission rate
- `PUT /api/v1/commission-settings/:id` - Update commission rate
- `DELETE /api/v1/commission-settings/:id` - Delete commission rate

#### Tax Settings
- `GET /api/v1/tax-settings` - List all tax settings
- `POST /api/v1/tax-settings` - Create new tax setting
- `PUT /api/v1/tax-settings/:id` - Update tax setting
- `DELETE /api/v1/tax-settings/:id` - Delete tax setting

### Order Completion Webhook
In your backend, when an order status changes to "completed":

```javascript
// Pseudo-code example
async function handleOrderCompletion(order) {
  // 1. Get commission rate for entity
  const commissionRate = await getCommissionRate(order.entity_type);
  
  // 2. Get applicable taxes
  const taxes = await getApplicableTaxes(order.entity_type, order.country);
  
  // 3. Calculate payout
  const grossAmount = order.total;
  const platformFee = grossAmount * (commissionRate.value / 100);
  const totalTax = taxes.reduce((sum, tax) => sum + (grossAmount * tax.rate / 100), 0);
  const netAmount = grossAmount - platformFee - totalTax;
  
  // 4. Create payout
  await createPayout({
    entity_id: order.vendor_id,
    entity_type: 'vendor',
    gross_amount: grossAmount,
    platform_fee: platformFee,
    tax_deductions: totalTax,
    net_amount: netAmount,
    status: 'pending',
    order_id: order.id
  });
}
```

## Admin Workflow

1. **Configure Settings** (One-time setup)
   - Set commission rates for vendors, affiliates, shippers
   - Configure applicable tax rates
   - Activate/deactivate as needed

2. **Orders Complete** (Automatic)
   - Backend creates payouts automatically
   - Calculations use configured rates
   - Payouts appear with status "pending"

3. **Review & Approve** (Admin action)
   - Admin reviews pending payouts in dashboard
   - Sees transparent breakdown (gross, fees, taxes, net)
   - Bulk approves or approves individually

4. **Process Payment** (Admin action)
   - Admin processes approved payouts
   - Status changes to "completed"
   - Funds transferred to entity bank accounts

## Important Notes

- ✅ **Settings are stored in the database** - Not hardcoded
- ✅ **Changes take effect immediately** - New orders use new rates
- ✅ **Multiple rates supported** - Different rates for different entity types
- ✅ **Transparent calculations** - All breakdown shown in dashboard
- ✅ **Audit trail** - All payouts logged with calculation details

## Next Steps

1. **Implement backend endpoints** for commission/tax settings CRUD
2. **Add payout creation logic** to order completion flow
3. **Test the workflow** with sample orders
4. **Deploy and monitor** payout processing

---

**Location in Code:**
- Settings Screen: `lib/features/payouts/presentation/screens/payouts_settings_screen.dart`
- Dashboard with Settings Button: `lib/features/payouts/presentation/screens/enhanced_payouts_dashboard.dart`
- Models: `lib/features/payouts/data/models/payout_models.dart`
- API Client: `lib/features/payouts/data/api/payouts_api_client.dart`
