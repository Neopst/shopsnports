const { Client } = require('pg');

const client = new Client({
  host: 'marketplace-db.ceno66e8mz81.us-east-1.rds.amazonaws.com',
  port: 5432,
  user: 'admin0',
  password: 'Marketplace2025SecurePass!',
  database: 'marketplace',
  ssl: {
    rejectUnauthorized: false
  }
});

async function seedDatabase() {
  try {
    await client.connect();
    console.log('✅ Connected to PostgreSQL');
    
    // Create sample vendors with users
    console.log('\n👥 Creating sample vendors...');
    
    const vendors = [
      { firebase_uid: 'vendor1_uid', email: 'tech@shopsnports.com', name: 'Tech Innovations', business_name: 'Tech Innovations', business_description: 'Premium technology products' },
      { firebase_uid: 'vendor2_uid', email: 'audio@shopsnports.com', name: 'Audio World', business_name: 'Audio World', business_description: 'High-quality audio equipment' },
      { firebase_uid: 'vendor3_uid', email: 'wearables@shopsnports.com', name: 'Smart Wearables', business_name: 'Smart Wearables', business_description: 'Latest wearable technology' },
      { firebase_uid: 'vendor4_uid', email: 'packaging@shopsnports.com', name: 'Package Pro', business_name: 'Package Pro', business_description: 'Professional packaging solutions' },
      { firebase_uid: 'vendor5_uid', email: 'furniture@shopsnports.com', name: 'Office Essentials', business_name: 'Office Essentials', business_description: 'Quality office furniture' },
      { firebase_uid: 'vendor6_uid', email: 'photo@shopsnports.com', name: 'Camera Hub', business_name: 'Camera Hub', business_description: 'Photography equipment and accessories' },
      { firebase_uid: 'vendor7_uid', email: 'fitness@shopsnports.com', name: 'Fitness Plus', business_name: 'Fitness Plus', business_description: 'Yoga and fitness equipment' },
      { firebase_uid: 'vendor8_uid', email: 'kitchen@shopsnports.com', name: 'Kitchen Masters', business_name: 'Kitchen Masters', business_description: 'Premium kitchen appliances' },
      { firebase_uid: 'vendor9_uid', email: 'travel@shopsnports.com', name: 'Travel Gear', business_name: 'Travel Gear', business_description: 'Quality travel accessories' },
    ];
    
    const vendorIds = [];
    for (const vendor of vendors) {
      // Create user
      const userResult = await client.query(
        `INSERT INTO users (firebase_uid, email, name, role) 
         VALUES ($1, $2, $3, 'vendor') 
         ON CONFLICT (firebase_uid) DO UPDATE SET email = EXCLUDED.email
         RETURNING id`,
        [vendor.firebase_uid, vendor.email, vendor.name]
      );
      
      // Create vendor
      const vendorResult = await client.query(
        `INSERT INTO vendors (user_id, business_name, business_description, status, commission_rate) 
         VALUES ($1, $2, $3, 'approved', 10.00) 
         RETURNING id`,
        [userResult.rows[0].id, vendor.business_name, vendor.business_description]
      );
      
      vendorIds.push(vendorResult.rows[0].id);
    }
    console.log(`✅ Created ${vendorIds.length} vendors`);
    
    // Create categories
    console.log('\n📁 Creating categories...');
    const categories = [
      { name: 'Electronics', description: 'Electronic devices and gadgets', image_url: 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=400' },
      { name: 'Audio', description: 'Audio equipment and accessories', image_url: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400' },
      { name: 'Wearables', description: 'Smart watches and fitness trackers', image_url: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400' },
      { name: 'Packaging', description: 'Shipping and packaging supplies', image_url: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=400' },
      { name: 'Furniture', description: 'Office and home furniture', image_url: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400' },
      { name: 'Photography', description: 'Cameras and photography equipment', image_url: 'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=400' },
      { name: 'Fitness', description: 'Yoga and fitness equipment', image_url: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400' },
      { name: 'Kitchen', description: 'Kitchen appliances and gadgets', image_url: 'https://images.unsplash.com/photo-1556911073-38141963c9e0?w=400' },
      { name: 'Travel', description: 'Travel bags and accessories', image_url: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400' },
      { name: 'Monitors', description: 'Computer monitors and displays', image_url: 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=400' },
    ];
    
    const categoryIds = [];
    for (const category of categories) {
      const result = await client.query(
        `INSERT INTO categories (name, description, image_url) 
         VALUES ($1, $2, $3) 
         RETURNING id`,
        [category.name, category.description, category.image_url]
      );
      categoryIds.push(result.rows[0].id);
    }
    console.log(`✅ Created ${categoryIds.length} categories`);
    
    // Create products
    console.log('\n📦 Creating products...');
    const products = [
      {
        vendor_id: vendorIds[0],
        category_id: categoryIds[0],
        name: 'iPhone 15 Pro',
        description: 'Latest flagship smartphone with A17 Pro chip, titanium design, and advanced camera system',
        price: 999.99,
        stock_quantity: 50,
        sku: 'TECH-IP15P-001',
        image_url: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400',
      },
      {
        vendor_id: vendorIds[1],
        category_id: categoryIds[1],
        name: 'Wireless Earbuds',
        description: 'Premium wireless earbuds with active noise cancellation and 24-hour battery life',
        price: 59.99,
        stock_quantity: 150,
        sku: 'AUDIO-WE-002',
        image_url: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=400',
      },
      {
        vendor_id: vendorIds[2],
        category_id: categoryIds[2],
        name: 'Smart Watch',
        description: 'Fitness tracker with heart rate monitor, GPS, and 7-day battery life',
        price: 129.99,
        stock_quantity: 75,
        sku: 'WEAR-SW-003',
        image_url: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
      },
      {
        vendor_id: vendorIds[3],
        category_id: categoryIds[3],
        name: 'Shipping Boxes (Pack of 25)',
        description: 'Heavy-duty corrugated shipping boxes, 12x12x12 inches, perfect for e-commerce',
        price: 24.99,
        stock_quantity: 200,
        sku: 'PKG-BOX-004',
        image_url: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=400',
      },
      {
        vendor_id: vendorIds[4],
        category_id: categoryIds[4],
        name: 'Ergonomic Office Chair',
        description: 'Premium ergonomic chair with lumbar support, adjustable arms, and breathable mesh',
        price: 299.99,
        stock_quantity: 30,
        sku: 'FURN-CHAIR-005',
        image_url: 'https://images.unsplash.com/photo-1592078615290-033ee584e267?w=400',
      },
      {
        vendor_id: vendorIds[5],
        category_id: categoryIds[5],
        name: '50mm Camera Lens',
        description: 'Professional 50mm f/1.8 lens for portrait photography with beautiful bokeh',
        price: 299.99,
        stock_quantity: 40,
        sku: 'CAM-LENS-006',
        image_url: 'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=400',
      },
      {
        vendor_id: vendorIds[6],
        category_id: categoryIds[6],
        name: 'Yoga Mat Premium',
        description: 'Extra thick yoga mat with non-slip surface and carrying strap',
        price: 39.99,
        stock_quantity: 100,
        sku: 'FIT-YOGA-007',
        image_url: 'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?w=400',
      },
      {
        vendor_id: vendorIds[7],
        category_id: categoryIds[7],
        name: 'Coffee Maker Deluxe',
        description: 'Programmable coffee maker with thermal carafe, 12-cup capacity',
        price: 79.99,
        stock_quantity: 60,
        sku: 'KTCH-COFFEE-008',
        image_url: 'https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?w=400',
      },
      {
        vendor_id: vendorIds[8],
        category_id: categoryIds[8],
        name: 'Travel Backpack',
        description: 'Durable travel backpack with laptop compartment and USB charging port',
        price: 49.99,
        stock_quantity: 120,
        sku: 'TRVL-BKPK-009',
        image_url: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
      },
      {
        vendor_id: vendorIds[0],
        category_id: categoryIds[9],
        name: '27" LED Monitor',
        description: '27-inch Full HD monitor with 144Hz refresh rate and IPS panel',
        price: 199.99,
        stock_quantity: 45,
        sku: 'TECH-MON-010',
        image_url: 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=400',
      },
    ];
    
    for (const product of products) {
      await client.query(
        `INSERT INTO products (vendor_id, category_id, name, description, price, stock_quantity, sku, image_url, status) 
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'active')`,
        [product.vendor_id, product.category_id, product.name, product.description, 
         product.price, product.stock_quantity, product.sku, product.image_url]
      );
    }
    console.log(`✅ Created ${products.length} products`);
    
    // Verify data
    const productCount = await client.query('SELECT COUNT(*) FROM products');
    const vendorCount = await client.query('SELECT COUNT(*) FROM vendors');
    const categoryCount = await client.query('SELECT COUNT(*) FROM categories');
    
    console.log('\n✅ Database seeding complete!');
    console.log(`📊 Summary:`);
    console.log(`   - Vendors: ${vendorCount.rows[0].count}`);
    console.log(`   - Categories: ${categoryCount.rows[0].count}`);
    console.log(`   - Products: ${productCount.rows[0].count}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
  } finally {
    await client.end();
  }
}

seedDatabase();
