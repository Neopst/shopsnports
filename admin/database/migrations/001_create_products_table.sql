-- Migration: Create products table
-- Description: Products catalog with approval workflow

CREATE TABLE IF NOT EXISTS products (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  discount_price DECIMAL(10, 2),
  category_id VARCHAR(50),
  vendor_id VARCHAR(50),
  images TEXT[], -- Array of image URLs
  stock_quantity INT DEFAULT 0,
  sku VARCHAR(100) UNIQUE,
  status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected, active, inactive
  tags TEXT[],
  rating DECIMAL(3, 2) DEFAULT 0.0,
  review_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  approved_by VARCHAR(50), -- Admin UID from Firebase
  approved_at TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_products_vendor ON products(vendor_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_created_at ON products(created_at DESC);

-- Seed some test products
INSERT INTO products (id, name, description, price, discount_price, category_id, vendor_id, images, stock_quantity, sku, status, tags, rating, review_count) VALUES
('prod_001', 'Wireless Headphones', 'Premium noise-cancelling wireless headphones with 30-hour battery life', 149.99, 129.99, 'cat_electronics', 'vendor_101', ARRAY['https://via.placeholder.com/400'], 50, 'WH-001', 'approved', ARRAY['electronics', 'audio', 'wireless'], 4.5, 120),
('prod_002', 'Smart Watch', 'Fitness tracking smartwatch with heart rate monitor', 299.99, NULL, 'cat_electronics', 'vendor_102', ARRAY['https://via.placeholder.com/400'], 30, 'SW-002', 'approved', ARRAY['electronics', 'wearable', 'fitness'], 4.7, 85),
('prod_003', 'Running Shoes', 'Lightweight running shoes with breathable mesh', 89.99, 79.99, 'cat_sports', 'vendor_103', ARRAY['https://via.placeholder.com/400'], 100, 'RS-003', 'approved', ARRAY['sports', 'footwear', 'running'], 4.3, 200),
('prod_004', 'Laptop Backpack', 'Water-resistant laptop backpack with USB charging port', 49.99, NULL, 'cat_accessories', 'vendor_101', ARRAY['https://via.placeholder.com/400'], 75, 'LB-004', 'pending', ARRAY['accessories', 'bags', 'tech'], 0.0, 0),
('prod_005', 'Coffee Maker', 'Programmable coffee maker with thermal carafe', 79.99, 69.99, 'cat_home', 'vendor_104', ARRAY['https://via.placeholder.com/400'], 40, 'CM-005', 'approved', ARRAY['home', 'kitchen', 'appliances'], 4.6, 150);

COMMENT ON TABLE products IS 'Product catalog with vendor and category associations';
