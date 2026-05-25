-- Migration: Create vendors table
-- Description: Vendor/seller management with approval workflow

CREATE TABLE IF NOT EXISTS vendors (
  id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50), -- Firebase Auth UID
  business_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(50),
  description TEXT,
  logo_url VARCHAR(500),
  banner_url VARCHAR(500),
  address JSONB,
  status VARCHAR(20) DEFAULT 'pending', -- pending, approved, active, suspended, rejected
  rating DECIMAL(3, 2) DEFAULT 0.0,
  review_count INT DEFAULT 0,
  total_sales DECIMAL(12, 2) DEFAULT 0,
  commission_rate DECIMAL(5, 2) DEFAULT 10.00, -- Percentage
  bank_details JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  approved_at TIMESTAMP,
  approved_by VARCHAR(50) -- Admin UID
);

-- Indexes
CREATE INDEX idx_vendors_status ON vendors(status);
CREATE INDEX idx_vendors_user_id ON vendors(user_id);
CREATE INDEX idx_vendors_email ON vendors(email);

-- Add foreign key to products table
ALTER TABLE products 
ADD CONSTRAINT fk_products_vendor 
FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE;

-- Seed test vendors
INSERT INTO vendors (id, user_id, business_name, email, phone, description, logo_url, status, rating, review_count, total_sales, commission_rate) VALUES
('vendor_101', 'uid_vendor_1', 'TechGear Electronics', 'techgear@shopsnports.com', '+1234567890', 'Premium electronics and accessories', 'https://via.placeholder.com/100', 'approved', 4.5, 150, 15000.00, 10.00),
('vendor_102', 'uid_vendor_2', 'FitPro Wearables', 'fitpro@shopsnports.com', '+1234567891', 'Fitness trackers and smartwatches', 'https://via.placeholder.com/100', 'approved', 4.7, 200, 25000.00, 8.00),
('vendor_103', 'uid_vendor_3', 'SportMax', 'sportmax@shopsnports.com', '+1234567892', 'Sports equipment and gear', 'https://via.placeholder.com/100', 'approved', 4.3, 180, 18000.00, 12.00),
('vendor_104', 'uid_vendor_4', 'HomeEssentials', 'homeessentials@shopsnports.com', '+1234567893', 'Home and kitchen appliances', 'https://via.placeholder.com/100', 'pending', 0.0, 0, 0.00, 10.00);

COMMENT ON TABLE vendors IS 'Vendor/seller accounts with approval workflow and commission tracking';
