-- Migration: Create customers table
-- Description: Customer accounts and profiles

CREATE TABLE IF NOT EXISTS customers (
  id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50), -- Firebase Auth UID
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(50),
  avatar_url VARCHAR(500),
  addresses JSONB[], -- Array of address objects
  default_address_index INT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'active', -- active, blocked, deleted
  total_orders INT DEFAULT 0,
  total_spent DECIMAL(12, 2) DEFAULT 0,
  loyalty_points INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP
);

-- Indexes
CREATE INDEX idx_customers_user_id ON customers(user_id);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_status ON customers(status);

-- Seed test customers
INSERT INTO customers (id, user_id, first_name, last_name, email, phone, status, total_orders, total_spent, loyalty_points) VALUES
('cust_001', 'uid_customer_1', 'John', 'Doe', 'john.doe@example.com', '+1234567890', 'active', 15, 1250.50, 125),
('cust_002', 'uid_customer_2', 'Jane', 'Smith', 'jane.smith@example.com', '+1234567891', 'active', 8, 780.00, 78),
('cust_003', 'uid_customer_3', 'Mike', 'Johnson', 'mike.johnson@example.com', '+1234567892', 'active', 22, 2100.00, 210),
('cust_004', 'uid_customer_4', 'Sarah', 'Williams', 'sarah.williams@example.com', '+1234567893', 'active', 5, 450.75, 45);

COMMENT ON TABLE customers IS 'Customer profiles with order history and loyalty points';
