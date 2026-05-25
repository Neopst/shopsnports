-- Migration: Create affiliates and referrals tables
-- Description: Affiliate program with commission tracking

CREATE TABLE IF NOT EXISTS affiliates (
  id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50), -- Firebase Auth UID
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  code VARCHAR(50) UNIQUE NOT NULL, -- Affiliate referral code
  commission_rate DECIMAL(5, 2) DEFAULT 5.00,
  total_earnings DECIMAL(12, 2) DEFAULT 0,
  pending_earnings DECIMAL(12, 2) DEFAULT 0,
  paid_earnings DECIMAL(12, 2) DEFAULT 0,
  total_referrals INT DEFAULT 0,
  total_sales DECIMAL(12, 2) DEFAULT 0,
  status VARCHAR(20) DEFAULT 'active', -- active, suspended, inactive
  payment_details JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS affiliate_referrals (
  id VARCHAR(50) PRIMARY KEY,
  affiliate_id VARCHAR(50),
  customer_id VARCHAR(50),
  order_id VARCHAR(50),
  commission_amount DECIMAL(10, 2),
  status VARCHAR(20) DEFAULT 'pending', -- pending, approved, paid
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  paid_at TIMESTAMP,
  FOREIGN KEY (affiliate_id) REFERENCES affiliates(id) ON DELETE CASCADE,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX idx_affiliates_code ON affiliates(code);
CREATE INDEX idx_affiliates_status ON affiliates(status);
CREATE INDEX idx_referrals_affiliate ON affiliate_referrals(affiliate_id);
CREATE INDEX idx_referrals_status ON affiliate_referrals(status);

-- Seed test affiliates
INSERT INTO affiliates (id, user_id, name, email, code, commission_rate, total_earnings, pending_earnings, paid_earnings, total_referrals, total_sales, status) VALUES
('aff_001', 'uid_aff_1', 'Tech Reviewer Blog', 'techreview@example.com', 'TECHREV20', 8.00, 1500.00, 200.00, 1300.00, 45, 18750.00, 'active'),
('aff_002', 'uid_aff_2', 'Fitness Influencer', 'fitinfluence@example.com', 'FITPRO15', 10.00, 2500.00, 500.00, 2000.00, 80, 25000.00, 'active'),
('aff_003', 'uid_aff_3', 'Sports Channel', 'sportschannel@example.com', 'SPORTS25', 5.00, 800.00, 150.00, 650.00, 30, 16000.00, 'active');

INSERT INTO affiliate_referrals (id, affiliate_id, customer_id, order_id, commission_amount, status) VALUES
('ref_001', 'aff_001', 'cust_001', 'order_001', 12.24, 'paid'),
('ref_002', 'aff_002', 'cust_002', 'order_002', 34.65, 'approved'),
('ref_003', 'aff_003', 'cust_003', 'order_003', 4.84, 'pending');

COMMENT ON TABLE affiliates IS 'Affiliate partners with commission rates and earnings';
COMMENT ON TABLE affiliate_referrals IS 'Individual referrals and commission records';
