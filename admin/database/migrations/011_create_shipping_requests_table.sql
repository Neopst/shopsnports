-- Migration: Create shipping_requests table
-- Description: Shipping requests for air/sea cargo services

CREATE TABLE IF NOT EXISTS shipping_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_number VARCHAR(50) UNIQUE NOT NULL,
  
  -- Requester info
  requester_type VARCHAR(20) NOT NULL CHECK (requester_type IN ('customer', 'affiliate')),
  requester_id UUID NOT NULL,
  requester_name VARCHAR(255) NOT NULL,
  requester_email VARCHAR(255) NOT NULL,
  requester_phone VARCHAR(50),
  
  -- Shipment details
  shipping_type VARCHAR(20) NOT NULL CHECK (shipping_type IN ('air', 'sea')),
  cargo_type VARCHAR(100) NOT NULL,
  cargo_description TEXT NOT NULL,
  
  -- Origin and destination
  origin_country VARCHAR(100) NOT NULL,
  origin_city VARCHAR(100) NOT NULL,
  origin_address TEXT NOT NULL,
  origin_postal_code VARCHAR(20),
  
  destination_country VARCHAR(100) NOT NULL,
  destination_city VARCHAR(100) NOT NULL,
  destination_address TEXT NOT NULL,
  destination_postal_code VARCHAR(20),
  
  -- Cargo specifications
  weight_kg DECIMAL(10, 2) NOT NULL,
  volume_cbm DECIMAL(10, 2),
  quantity INTEGER NOT NULL DEFAULT 1,
  packaging_type VARCHAR(100),
  
  -- Pricing
  estimated_cost DECIMAL(10, 2),
  final_cost DECIMAL(10, 2),
  currency VARCHAR(10) DEFAULT 'USD',
  
  -- Status workflow
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'reviewing', 'approved', 'rejected', 
    'carrier_assigned', 'in_transit', 'delivered', 'cancelled'
  )),
  
  -- Carrier assignment
  carrier_name VARCHAR(255),
  carrier_contact VARCHAR(255),
  tracking_number VARCHAR(100),
  
  -- Dates
  requested_pickup_date DATE,
  actual_pickup_date DATE,
  estimated_delivery_date DATE,
  actual_delivery_date DATE,
  
  -- Additional info
  special_instructions TEXT,
  insurance_required BOOLEAN DEFAULT false,
  insurance_value DECIMAL(10, 2),
  
  -- Admin notes
  admin_notes TEXT,
  rejection_reason TEXT,
  
  -- Audit fields
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID,
  updated_by UUID
);

-- Indexes for performance
CREATE INDEX idx_shipping_requests_requester ON shipping_requests(requester_type, requester_id);
CREATE INDEX idx_shipping_requests_status ON shipping_requests(status);
CREATE INDEX idx_shipping_requests_type ON shipping_requests(shipping_type);
CREATE INDEX idx_shipping_requests_created_at ON shipping_requests(created_at DESC);
CREATE INDEX idx_shipping_requests_number ON shipping_requests(request_number);

-- Sample data
INSERT INTO shipping_requests (
  request_number, requester_type, requester_id, requester_name, requester_email, 
  shipping_type, cargo_type, cargo_description, 
  origin_country, origin_city, origin_address, 
  destination_country, destination_city, destination_address,
  weight_kg, quantity, estimated_cost, status
) VALUES
('SR-2025-001', 'customer', gen_random_uuid(), 'John Doe', 'john@example.com', 
 'air', 'Electronics', 'Laptop computers and accessories',
 'USA', 'New York', '123 Main St', 
 'Nigeria', 'Lagos', '456 Victoria Island',
 50.00, 5, 1200.00, 'pending'),
('SR-2025-002', 'affiliate', gen_random_uuid(), 'ABC Logistics', 'contact@abc.com',
 'sea', 'General Cargo', 'Household items and furniture',
 'China', 'Shanghai', '789 Port Road',
 'Nigeria', 'Port Harcourt', '321 Market St',
 500.00, 1, 3500.00, 'approved');

COMMENT ON TABLE shipping_requests IS 'Shipping requests for air and sea cargo services';
