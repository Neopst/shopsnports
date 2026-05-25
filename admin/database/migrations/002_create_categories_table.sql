-- Migration: Create categories table
-- Description: Product categories with hierarchy support

CREATE TABLE IF NOT EXISTS categories (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  image_url VARCHAR(500),
  parent_id VARCHAR(50), -- For sub-categories
  icon VARCHAR(100),
  display_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_active ON categories(is_active);
CREATE INDEX idx_categories_order ON categories(display_order);

-- Add foreign key to products table
ALTER TABLE products 
ADD CONSTRAINT fk_products_category 
FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL;

-- Seed test categories
INSERT INTO categories (id, name, description, image_url, parent_id, icon, display_order, is_active) VALUES
('cat_electronics', 'Electronics', 'Electronic devices and gadgets', 'https://via.placeholder.com/200', NULL, 'devices', 1, true),
('cat_sports', 'Sports & Fitness', 'Sports equipment and fitness gear', 'https://via.placeholder.com/200', NULL, 'fitness_center', 2, true),
('cat_home', 'Home & Kitchen', 'Home appliances and kitchen essentials', 'https://via.placeholder.com/200', NULL, 'home', 3, true),
('cat_accessories', 'Accessories', 'Bags, wallets, and accessories', 'https://via.placeholder.com/200', NULL, 'shopping_bag', 4, true),
('cat_fashion', 'Fashion', 'Clothing and fashion items', 'https://via.placeholder.com/200', NULL, 'checkroom', 5, true);

COMMENT ON TABLE categories IS 'Product categories with parent-child hierarchy';
