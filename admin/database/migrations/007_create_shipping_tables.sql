-- Migration: Create shipping tables
-- Description: Shipping zones, rates, and tracking

CREATE TABLE IF NOT EXISTS shipping_zones (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  countries VARCHAR(100)[], -- Array of country codes
  states VARCHAR(100)[],
  cities VARCHAR(100)[],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shipping_rates (
  id VARCHAR(50) PRIMARY KEY,
  zone_id VARCHAR(50),
  carrier VARCHAR(100), -- DHL, FedEx, UPS, Local, etc.
  min_weight DECIMAL(10, 2),
  max_weight DECIMAL(10, 2),
  rate DECIMAL(10, 2) NOT NULL,
  estimated_days INT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (zone_id) REFERENCES shipping_zones(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_shipping_zones_active ON shipping_zones(is_active);
CREATE INDEX idx_shipping_rates_zone ON shipping_rates(zone_id);
CREATE INDEX idx_shipping_rates_carrier ON shipping_rates(carrier);

-- Seed test shipping zones
INSERT INTO shipping_zones (id, name, countries, states, is_active) VALUES
('zone_001', 'Domestic - East Coast', ARRAY['US'], ARRAY['NY', 'NJ', 'PA', 'MA', 'CT'], true),
('zone_002', 'Domestic - West Coast', ARRAY['US'], ARRAY['CA', 'OR', 'WA', 'NV'], true),
('zone_003', 'Domestic - Central', ARRAY['US'], ARRAY['TX', 'IL', 'OH', 'MI'], true),
('zone_004', 'International - Europe', ARRAY['GB', 'FR', 'DE', 'IT', 'ES'], ARRAY[], true),
('zone_005', 'International - Asia', ARRAY['JP', 'CN', 'KR', 'SG'], ARRAY[], true);

-- Seed test shipping rates
INSERT INTO shipping_rates (id, zone_id, carrier, min_weight, max_weight, rate, estimated_days, is_active) VALUES
('rate_001', 'zone_001', 'USPS', 0.0, 5.0, 8.99, 3, true),
('rate_002', 'zone_001', 'FedEx', 0.0, 5.0, 12.99, 2, true),
('rate_003', 'zone_002', 'USPS', 0.0, 5.0, 10.99, 5, true),
('rate_004', 'zone_002', 'UPS', 0.0, 5.0, 14.99, 3, true),
('rate_005', 'zone_004', 'DHL International', 0.0, 10.0, 45.99, 10, true),
('rate_006', 'zone_005', 'DHL International', 0.0, 10.0, 55.99, 14, true);

COMMENT ON TABLE shipping_zones IS 'Shipping zones by geography';
COMMENT ON TABLE shipping_rates IS 'Shipping rates per zone and carrier';
