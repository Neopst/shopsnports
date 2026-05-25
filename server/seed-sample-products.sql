-- =====================================================
-- ShopsNSports Database Seeding Script
-- Populates PostgreSQL with all sample data from Admin Dashboard
-- =====================================================

-- Create vendor users
INSERT INTO users (email, name, role, created_at, updated_at)
VALUES 
  ('techcorp@shopsnports.com', 'TechCorp', 'vendor', NOW(), NOW()),
  ('audioplus@shopsnports.com', 'AudioPlus', 'vendor', NOW(), NOW()),
  ('weartech@shopsnports.com', 'WearTech', 'vendor', NOW(), NOW()),
  ('packmaster@shopsnports.com', 'PackMaster', 'vendor', NOW(), NOW()),
  ('furnitureco@shopsnports.com', 'FurnitureCo', 'vendor', NOW(), NOW()),
  ('photogear@shopsnports.com', 'PhotoGear', 'vendor', NOW(), NOW()),
  ('fitnesspro@shopsnports.com', 'FitnessPro', 'vendor', NOW(), NOW()),
  ('kitchenessentials@shopsnports.com', 'KitchenEssentials', 'vendor', NOW(), NOW()),
  ('travelgear@shopsnports.com', 'TravelGear', 'vendor', NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- Create categories
INSERT INTO categories (name, slug, description, created_at, updated_at)
VALUES 
  ('Electronics', 'electronics', 'Electronic devices and accessories', NOW(), NOW()),
  ('Mobile', 'mobile', 'Mobile phones and accessories', NOW(), NOW()),
  ('Audio', 'audio', 'Audio equipment and accessories', NOW(), NOW()),
  ('Wearables', 'wearables', 'Wearable technology', NOW(), NOW()),
  ('Supplies', 'supplies', 'General supplies', NOW(), NOW()),
  ('Packaging', 'packaging', 'Packaging materials', NOW(), NOW()),
  ('Furniture', 'furniture', 'Furniture and home furnishings', NOW(), NOW()),
  ('Office', 'office', 'Office supplies and equipment', NOW(), NOW()),
  ('Photography', 'photography', 'Photography equipment', NOW(), NOW()),
  ('Sports', 'sports', 'Sports and fitness equipment', NOW(), NOW()),
  ('Fitness', 'fitness', 'Fitness equipment and accessories', NOW(), NOW()),
  ('Home', 'home', 'Home products', NOW(), NOW()),
  ('Kitchen', 'kitchen', 'Kitchen appliances and accessories', NOW(), NOW()),
  ('Fashion', 'fashion', 'Fashion and accessories', NOW(), NOW()),
  ('Accessories', 'accessories', 'General accessories', NOW(), NOW()),
  ('Computers', 'computers', 'Computer equipment and accessories', NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;

-- Get vendor IDs (assuming sequential IDs)
-- Insert all 10 products from admin dashboard
INSERT INTO products (
  name, 
  description, 
  price,
  compare_at_price,
  cost,
  stock_quantity,
  sku,
  vendor_id,
  image_url,
  status,
  created_at,
  updated_at
) VALUES 
  -- Product 1: iPhone 15 Pro
  (
    'iPhone 15 Pro',
    'Latest iPhone with advanced camera system',
    999.99,
    1099.99,
    650.00,
    156,
    'IP15-PRO-256',
    (SELECT id FROM users WHERE email = 'techcorp@shopsnports.com' LIMIT 1),
    'https://picsum.photos/400/400?random=1',
    'active',
    NOW(),
    NOW()
  ),
  -- Product 2: Wireless Earbuds
  (
    'Wireless Earbuds',
    'Noise cancelling wireless earbuds',
    59.99,
    79.99,
    35.00,
    12,
    'WEB-NC-2024',
    (SELECT id FROM users WHERE email = 'audioplus@shopsnports.com' LIMIT 1),
    'https://picsum.photos/400/400?random=2',
    'active',
    NOW(),
    NOW()
  ),
  -- Product 3: Smart Watch
  (
    'Smart Watch',
    'Fitness tracker with heart rate monitor',
    129.99,
    149.99,
    80.00,
    50,
    'SW-FIT-PRO',
    (SELECT id FROM users WHERE email = 'weartech@shopsnports.com' LIMIT 1),
    'https://picsum.photos/400/400?random=3',
    'active',
    NOW(),
    NOW()
  ),
  -- Product 4: Shipping Boxes
  (
    'Shipping Boxes',
    'Cardboard shipping boxes for ecommerce',
    24.99,
    NULL,
    12.00,
    45,
    'BOX-12X8X4',
    (SELECT id FROM users WHERE email = 'packmaster@shopsnports.com' LIMIT 1),
    'https://picsum.photos/400/400?random=4',
    'pending',
    NOW(),
    NOW()
  ),
  -- Product 5: Office Chair
  (
    'Office Chair',
    'Ergonomic office chair with lumbar support',
    299.99,
    349.99,
    180.00,
    8,
    'CHAIR-ERG-01',
    (SELECT id FROM users WHERE email = 'furnitureco@shopsnports.com' LIMIT 1),
    'https://picsum.photos/400/400?random=5',
    'active',
    NOW(),
    NOW()
  ),
  -- Product 6: Camera Lens
  (
    'Camera Lens',
    'Professional camera lens for DSLR',
    299.99,
    399.99,
    200.00,
    25,
    'LENS-50MM',
    (SELECT id FROM users WHERE email = 'photogear@shopsnports.com' LIMIT 1),
    'https://picsum.photos/400/400?random=6',
    'active',
    NOW(),
    NOW()
  ),
  -- Product 7: Yoga Mat
  (
    'Yoga Mat',
    'Non-slip yoga mat for fitness',
    39.99,
    49.99,
    22.00,
    89,
    'YOGAMAT-PRO',
    (SELECT id FROM users WHERE email = 'fitnesspro@shopsnports.com' LIMIT 1),
    'https://picsum.photos/400/400?random=7',
    'active',
    NOW(),
    NOW()
  ),
  -- Product 8: Coffee Maker
  (
    'Coffee Maker',
    'Automatic drip coffee maker',
    79.99,
    99.99,
    45.00,
    34,
    'COFFEE-DRIP',
    (SELECT id FROM users WHERE email = 'kitchenessentials@shopsnports.com' LIMIT 1),
    'https://picsum.photos/400/400?random=8',
    'active',
    NOW(),
    NOW()
  ),
  -- Product 9: Backpack
  (
    'Backpack',
    'Waterproof backpack for travel',
    49.99,
    69.99,
    28.00,
    67,
    'BAG-TRAVEL-20',
    (SELECT id FROM users WHERE email = 'travelgear@shopsnports.com' LIMIT 1),
    'https://picsum.photos/400/400?random=9',
    'active',
    NOW(),
    NOW()
  ),
  -- Product 10: LED Monitor
  (
    'LED Monitor',
    '27-inch 4K LED monitor',
    199.99,
    249.99,
    130.00,
    3,
    'MON-27-4K',
    (SELECT id FROM users WHERE email = 'techcorp@shopsnports.com' LIMIT 1),
    'https://picsum.photos/400/400?random=10',
    'active',
    NOW(),
    NOW()
  );

-- Verify the data
SELECT COUNT(*) as total_vendors FROM users WHERE role = 'vendor';
SELECT COUNT(*) as total_categories FROM categories;
SELECT COUNT(*) as total_products FROM products;
SELECT name, price, stock_quantity, status FROM products ORDER BY id LIMIT 10;
