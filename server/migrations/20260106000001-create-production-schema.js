/* 
 * Production Schema - ShopsNSports
 * Creates tables for orders, payouts, and other transactional data
 * User profiles, products, categories stay in Firestore
 */

exports.shorthands = undefined;

exports.up = (pgm) => {
  // ========== PRODUCTS & CATEGORIES ==========
  pgm.createTable('categories', {
    id: { type: 'serial', primaryKey: true },
    name: { type: 'varchar(100)', notNull: true },
    slug: { type: 'varchar(100)', notNull: true, unique: true },
    description: { type: 'text' },
    image_url: { type: 'text' },
    parent_id: { type: 'integer', references: 'categories(id)', onDelete: 'SET NULL' },
    is_active: { type: 'boolean', notNull: true, default: true },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') },
    updated_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') }
  });

  pgm.createTable('products', {
    id: { type: 'serial', primaryKey: true },
    vendor_id: { type: 'text', notNull: true }, // Firebase UID
    category_id: { type: 'integer', references: 'categories(id)', onDelete: 'SET NULL' },
    name: { type: 'varchar(200)', notNull: true },
    slug: { type: 'varchar(200)', notNull: true, unique: true },
    description: { type: 'text' },
    price: { type: 'decimal(10,2)', notNull: true },
    compare_at_price: { type: 'decimal(10,2)' },
    cost_price: { type: 'decimal(10,2)' },
    sku: { type: 'varchar(100)', unique: true },
    barcode: { type: 'varchar(100)' },
    quantity: { type: 'integer', notNull: true, default: 0 },
    images: { type: 'jsonb', default: '[]' },
    variants: { type: 'jsonb', default: '[]' },
    weight: { type: 'decimal(8,2)' },
    dimensions: { type: 'jsonb' }, // {length, width, height}
    is_active: { type: 'boolean', notNull: true, default: true },
    is_featured: { type: 'boolean', notNull: true, default: false },
    tags: { type: 'jsonb', default: '[]' },
    seo_title: { type: 'varchar(200)' },
    seo_description: { type: 'text' },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') },
    updated_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') }
  });

  pgm.createIndex('products', 'vendor_id');
  pgm.createIndex('products', 'category_id');
  pgm.createIndex('products', 'is_active');

  // ========== ORDERS ==========
  pgm.createTable('orders', {
    id: { type: 'text', primaryKey: true }, // ORD-XXX
    customer_id: { type: 'text', notNull: true }, // Firebase UID
    order_number: { type: 'varchar(50)', unique: true, notNull: true },
    status: { 
      type: 'varchar(50)', 
      notNull: true, 
      default: 'pending',
      check: "status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded')"
    },
    payment_status: {
      type: 'varchar(50)',
      notNull: true,
      default: 'pending',
      check: "payment_status IN ('pending', 'paid', 'failed', 'refunded', 'partial')"
    },
    payment_method: { type: 'varchar(50)' }, // paystack, flutterwave, cash
    subtotal: { type: 'decimal(10,2)', notNull: true },
    tax: { type: 'decimal(10,2)', default: 0 },
    shipping_fee: { type: 'decimal(10,2)', default: 0 },
    discount: { type: 'decimal(10,2)', default: 0 },
    total: { type: 'decimal(10,2)', notNull: true },
    currency: { type: 'varchar(3)', notNull: true, default: 'NGN' },
    
    // Shipping info
    shipping_address: { type: 'jsonb', notNull: true },
    billing_address: { type: 'jsonb' },
    shipping_method: { type: 'varchar(100)' },
    tracking_number: { type: 'varchar(100)' },
    
    // Additional data
    customer_notes: { type: 'text' },
    admin_notes: { type: 'text' },
    metadata: { type: 'jsonb', default: '{}' },
    
    // Timestamps
    paid_at: { type: 'timestamp' },
    shipped_at: { type: 'timestamp' },
    delivered_at: { type: 'timestamp' },
    cancelled_at: { type: 'timestamp' },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') },
    updated_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') }
  });

  pgm.createIndex('orders', 'customer_id');
  pgm.createIndex('orders', 'status');
  pgm.createIndex('orders', 'payment_status');
  pgm.createIndex('orders', 'created_at');

  // ========== ORDER ITEMS ==========
  pgm.createTable('order_items', {
    id: { type: 'serial', primaryKey: true },
    order_id: { type: 'text', references: 'orders(id)', onDelete: 'CASCADE', notNull: true },
    product_id: { type: 'integer', references: 'products(id)', onDelete: 'SET NULL' },
    vendor_id: { type: 'text', notNull: true }, // Firebase UID
    product_name: { type: 'varchar(200)', notNull: true },
    product_sku: { type: 'varchar(100)' },
    variant_details: { type: 'jsonb' },
    quantity: { type: 'integer', notNull: true },
    unit_price: { type: 'decimal(10,2)', notNull: true },
    subtotal: { type: 'decimal(10,2)', notNull: true },
    tax: { type: 'decimal(10,2)', default: 0 },
    discount: { type: 'decimal(10,2)', default: 0 },
    total: { type: 'decimal(10,2)', notNull: true },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') }
  });

  pgm.createIndex('order_items', 'order_id');
  pgm.createIndex('order_items', 'product_id');
  pgm.createIndex('order_items', 'vendor_id');

  // ========== SHIPPING REQUESTS (PostgreSQL backup of Firestore) ==========
  pgm.createTable('shipping_requests', {
    id: { type: 'text', primaryKey: true }, // REQ-XXX
    requester_id: { type: 'text', notNull: true }, // Firebase UID
    affiliate_id: { type: 'text' }, // Firebase UID
    shipper_id: { type: 'text' }, // Firebase UID (assigned shipper)
    
    type: { type: 'varchar(50)', notNull: true, check: "type IN ('air', 'sea', 'road')" },
    status: { 
      type: 'varchar(50)', 
      notNull: true, 
      default: 'pending',
      check: "status IN ('pending', 'accepted', 'in_transit', 'delivered', 'cancelled')"
    },
    priority: { type: 'varchar(50)', notNull: true, default: 'standard' },
    
    origin: { type: 'varchar(200)', notNull: true },
    destination: { type: 'varchar(200)', notNull: true },
    
    shipper_details: { type: 'jsonb' },
    consignee_details: { type: 'jsonb' },
    cargo_details: { type: 'jsonb' },
    
    tracking_number: { type: 'varchar(100)' },
    carrier: { type: 'varchar(100)' },
    
    estimated_cost: { type: 'decimal(10,2)' },
    actual_cost: { type: 'decimal(10,2)' },
    commission: { type: 'decimal(10,2)' },
    
    accepted_at: { type: 'timestamp' },
    completed_at: { type: 'timestamp' },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') },
    updated_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') }
  });

  pgm.createIndex('shipping_requests', 'requester_id');
  pgm.createIndex('shipping_requests', 'affiliate_id');
  pgm.createIndex('shipping_requests', 'shipper_id');
  pgm.createIndex('shipping_requests', 'status');

  // ========== PAYOUTS ==========
  pgm.createTable('payouts', {
    id: { type: 'serial', primaryKey: true },
    recipient_id: { type: 'text', notNull: true }, // Firebase UID
    recipient_type: { 
      type: 'varchar(50)', 
      notNull: true,
      check: "recipient_type IN ('vendor', 'affiliate', 'shipper')"
    },
    amount: { type: 'decimal(10,2)', notNull: true },
    currency: { type: 'varchar(3)', notNull: true, default: 'NGN' },
    status: {
      type: 'varchar(50)',
      notNull: true,
      default: 'pending',
      check: "status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')"
    },
    method: { type: 'varchar(50)' }, // bank_transfer, mobile_money, etc.
    
    // Bank details
    bank_details: { type: 'jsonb' },
    
    // Transaction reference
    transaction_ref: { type: 'varchar(100)' },
    provider_ref: { type: 'varchar(100)' },
    
    // Related records
    related_orders: { type: 'jsonb', default: '[]' }, // Array of order IDs
    related_shipments: { type: 'jsonb', default: '[]' }, // Array of shipment IDs
    
    notes: { type: 'text' },
    failure_reason: { type: 'text' },
    
    processed_at: { type: 'timestamp' },
    completed_at: { type: 'timestamp' },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') },
    updated_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') }
  });

  pgm.createIndex('payouts', 'recipient_id');
  pgm.createIndex('payouts', 'recipient_type');
  pgm.createIndex('payouts', 'status');

  // ========== REVIEWS ==========
  pgm.createTable('reviews', {
    id: { type: 'serial', primaryKey: true },
    product_id: { type: 'integer', references: 'products(id)', onDelete: 'CASCADE', notNull: true },
    customer_id: { type: 'text', notNull: true }, // Firebase UID
    order_id: { type: 'text', references: 'orders(id)', onDelete: 'SET NULL' },
    rating: { type: 'integer', notNull: true, check: 'rating >= 1 AND rating <= 5' },
    title: { type: 'varchar(200)' },
    comment: { type: 'text' },
    images: { type: 'jsonb', default: '[]' },
    is_verified_purchase: { type: 'boolean', default: false },
    is_approved: { type: 'boolean', default: false },
    helpful_count: { type: 'integer', default: 0 },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') },
    updated_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') }
  });

  pgm.createIndex('reviews', 'product_id');
  pgm.createIndex('reviews', 'customer_id');
  pgm.createIndex('reviews', 'is_approved');

  // ========== CART (session-based) ==========
  pgm.createTable('cart_items', {
    id: { type: 'serial', primaryKey: true },
    customer_id: { type: 'text', notNull: true }, // Firebase UID or session ID
    product_id: { type: 'integer', references: 'products(id)', onDelete: 'CASCADE', notNull: true },
    variant_details: { type: 'jsonb' },
    quantity: { type: 'integer', notNull: true, default: 1 },
    created_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') },
    updated_at: { type: 'timestamp', notNull: true, default: pgm.func('current_timestamp') }
  });

  pgm.createIndex('cart_items', 'customer_id');
  pgm.createIndex('cart_items', 'product_id');
  pgm.createConstraint('cart_items', 'unique_cart_item', {
    unique: ['customer_id', 'product_id']
  });

  // ========== TRIGGERS FOR UPDATED_AT ==========
  pgm.sql(`
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = current_timestamp;
      RETURN NEW;
    END;
    $$ language 'plpgsql';
  `);

  const tablesWithUpdatedAt = [
    'categories', 'products', 'orders', 'shipping_requests', 
    'payouts', 'reviews', 'cart_items'
  ];

  tablesWithUpdatedAt.forEach(table => {
    pgm.sql(`
      CREATE TRIGGER update_${table}_updated_at 
      BEFORE UPDATE ON ${table}
      FOR EACH ROW 
      EXECUTE PROCEDURE update_updated_at_column();
    `);
  });
};

exports.down = (pgm) => {
  // Drop triggers
  const tablesWithUpdatedAt = [
    'categories', 'products', 'orders', 'shipping_requests', 
    'payouts', 'reviews', 'cart_items'
  ];
  
  tablesWithUpdatedAt.forEach(table => {
    pgm.sql(`DROP TRIGGER IF EXISTS update_${table}_updated_at ON ${table};`);
  });
  
  pgm.sql('DROP FUNCTION IF EXISTS update_updated_at_column();');

  // Drop tables in reverse order (to handle foreign keys)
  pgm.dropTable('cart_items');
  pgm.dropTable('reviews');
  pgm.dropTable('payouts');
  pgm.dropTable('shipping_requests');
  pgm.dropTable('order_items');
  pgm.dropTable('orders');
  pgm.dropTable('products');
  pgm.dropTable('categories');
};
