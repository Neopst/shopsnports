-- Migration: Create payouts and financial tables
-- Description: Payout management, commission, and tax configuration

-- Payout transactions table
CREATE TABLE IF NOT EXISTS payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payout_number VARCHAR(50) UNIQUE NOT NULL,
  
  -- Recipient info
  recipient_type VARCHAR(20) NOT NULL CHECK (recipient_type IN ('vendor', 'affiliate', 'shipper')),
  recipient_id UUID NOT NULL,
  recipient_name VARCHAR(255) NOT NULL,
  
  -- Amount details
  gross_amount DECIMAL(12, 2) NOT NULL,
  commission_amount DECIMAL(12, 2) DEFAULT 0,
  tax_amount DECIMAL(12, 2) DEFAULT 0,
  net_amount DECIMAL(12, 2) NOT NULL,
  currency VARCHAR(10) DEFAULT 'USD',
  
  -- Payment details
  payment_method VARCHAR(50),
  payment_reference VARCHAR(255),
  bank_account_number VARCHAR(100),
  bank_name VARCHAR(255),
  
  -- Period covered
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'approved', 'processing', 'completed', 'failed', 'cancelled'
  )),
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  approved_by UUID,
  approved_at TIMESTAMP,
  processed_by UUID,
  processed_at TIMESTAMP,
  
  -- Notes
  notes TEXT,
  rejection_reason TEXT
);

-- Commission settings table
CREATE TABLE IF NOT EXISTS commission_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Applicable to
  entity_type VARCHAR(20) NOT NULL CHECK (entity_type IN ('vendor', 'affiliate', 'shipper', 'platform')),
  entity_id UUID,  -- NULL for default/global settings
  
  -- Commission structure
  commission_type VARCHAR(20) NOT NULL CHECK (commission_type IN ('percentage', 'fixed', 'tiered')),
  commission_value DECIMAL(10, 2) NOT NULL,
  
  -- For tiered commission
  min_amount DECIMAL(12, 2),
  max_amount DECIMAL(12, 2),
  
  -- Category specific (e.g., different rates for different product categories)
  category_id UUID,
  
  -- Active status
  is_active BOOLEAN DEFAULT true,
  effective_from DATE NOT NULL,
  effective_to DATE,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID
);

-- Tax settings table
CREATE TABLE IF NOT EXISTS tax_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Tax details
  tax_name VARCHAR(100) NOT NULL,
  tax_type VARCHAR(50) NOT NULL CHECK (tax_type IN ('vat', 'sales_tax', 'income_tax', 'withholding_tax')),
  tax_rate DECIMAL(5, 2) NOT NULL,
  
  -- Applicability
  applies_to VARCHAR(20) NOT NULL CHECK (applies_to IN ('vendor', 'affiliate', 'customer', 'shipper')),
  country VARCHAR(100),
  region VARCHAR(100),
  
  -- Active status
  is_active BOOLEAN DEFAULT true,
  effective_from DATE NOT NULL,
  effective_to DATE,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID
);

-- Transaction history table
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_number VARCHAR(50) UNIQUE NOT NULL,
  
  -- Related entities
  transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN (
    'order_payment', 'shipping_payment', 'payout', 'commission', 'refund'
  )),
  reference_id UUID,  -- ID of order, shipping request, etc.
  reference_type VARCHAR(50),
  
  -- Parties involved
  from_entity_type VARCHAR(20),
  from_entity_id UUID,
  to_entity_type VARCHAR(20),
  to_entity_id UUID,
  
  -- Amount
  amount DECIMAL(12, 2) NOT NULL,
  currency VARCHAR(10) DEFAULT 'USD',
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'completed', 'failed', 'reversed'
  )),
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  notes TEXT
);

-- Indexes
CREATE INDEX idx_payouts_recipient ON payouts(recipient_type, recipient_id);
CREATE INDEX idx_payouts_status ON payouts(status);
CREATE INDEX idx_payouts_created_at ON payouts(created_at DESC);
CREATE INDEX idx_commission_entity ON commission_settings(entity_type, entity_id);
CREATE INDEX idx_tax_applies_to ON tax_settings(applies_to, country);
CREATE INDEX idx_transactions_reference ON transactions(reference_type, reference_id);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);

-- Sample data
INSERT INTO commission_settings (entity_type, commission_type, commission_value, effective_from, is_active) VALUES
('vendor', 'percentage', 10.00, '2025-01-01', true),
('affiliate', 'percentage', 5.00, '2025-01-01', true),
('shipper', 'percentage', 8.00, '2025-01-01', true);

INSERT INTO tax_settings (tax_name, tax_type, tax_rate, applies_to, country, effective_from, is_active) VALUES
('VAT', 'vat', 7.50, 'vendor', 'Nigeria', '2025-01-01', true),
('Withholding Tax', 'withholding_tax', 5.00, 'vendor', 'Nigeria', '2025-01-01', true);

COMMENT ON TABLE payouts IS 'Payout transactions for vendors, affiliates, and shippers';
COMMENT ON TABLE commission_settings IS 'Commission configuration for different entity types';
COMMENT ON TABLE tax_settings IS 'Tax configuration and rates';
COMMENT ON TABLE transactions IS 'Complete transaction history for audit trail';
