-- Migration: Create orders and order_items tables
-- Description: Order management with items and status tracking

CREATE TABLE IF NOT EXISTS orders (
  id VARCHAR(50) PRIMARY KEY,
  order_number VARCHAR(50) UNIQUE NOT NULL,
  customer_id VARCHAR(50),
  vendor_id VARCHAR(50),
  total_amount DECIMAL(10, 2) NOT NULL,
  discount_amount DECIMAL(10, 2) DEFAULT 0,
  shipping_cost DECIMAL(10, 2) DEFAULT 0,
  tax_amount DECIMAL(10, 2) DEFAULT 0,
  grand_total DECIMAL(10, 2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending', -- pending, processing, shipped, delivered, cancelled, refunded
  payment_status VARCHAR(20) DEFAULT 'unpaid', -- unpaid, paid, refunded, failed
  payment_method VARCHAR(50),
  shipping_address JSONB,
  billing_address JSONB,
  tracking_number VARCHAR(100),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  shipped_at TIMESTAMP,
  delivered_at TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
  FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS order_items (
  id VARCHAR(50) PRIMARY KEY,
  order_id VARCHAR(50),
  product_id VARCHAR(50),
  product_name VARCHAR(255),
  product_image VARCHAR(500),
  quantity INT NOT NULL,
  unit_price DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_vendor ON orders(vendor_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- Seed test orders
INSERT INTO orders (id, order_number, customer_id, vendor_id, total_amount, discount_amount, shipping_cost, tax_amount, grand_total, status, payment_status, payment_method) VALUES
('order_001', 'ORD-2025-001', 'cust_001', 'vendor_101', 149.99, 20.00, 10.00, 13.00, 152.99, 'delivered', 'paid', 'credit_card'),
('order_002', 'ORD-2025-002', 'cust_002', 'vendor_102', 299.99, 0.00, 15.00, 31.50, 346.49, 'shipped', 'paid', 'paypal'),
('order_003', 'ORD-2025-003', 'cust_003', 'vendor_103', 89.99, 10.00, 8.00, 8.80, 96.79, 'processing', 'paid', 'credit_card'),
('order_004', 'ORD-2025-004', 'cust_001', 'vendor_104', 79.99, 10.00, 12.00, 8.20, 90.19, 'pending', 'unpaid', NULL);

INSERT INTO order_items (id, order_id, product_id, product_name, quantity, unit_price, total_price) VALUES
('item_001', 'order_001', 'prod_001', 'Wireless Headphones', 1, 129.99, 129.99),
('item_002', 'order_002', 'prod_002', 'Smart Watch', 1, 299.99, 299.99),
('item_003', 'order_003', 'prod_003', 'Running Shoes', 1, 79.99, 79.99),
('item_004', 'order_004', 'prod_005', 'Coffee Maker', 1, 69.99, 69.99);

COMMENT ON TABLE orders IS 'Customer orders with payment and shipping tracking';
COMMENT ON TABLE order_items IS 'Individual items within each order';
