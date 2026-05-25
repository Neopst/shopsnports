const { Client } = require('pg');

const client = new Client({
  host: 'marketplace-db.ceno66e8mz81.us-east-1.rds.amazonaws.com',
  port: 5432,
  user: 'admin0',
  password: 'Marketplace2025SecurePass!',
  database: 'marketplace',
  ssl: { rejectUnauthorized: false }
});

async function setupBanners() {
  try {
    await client.connect();
    console.log('✅ Connected to PostgreSQL');
    
    // Create banners table
    console.log('\n🔨 Creating banners table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS banners (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255),
        description TEXT,
        image_url TEXT NOT NULL,
        link_url TEXT,
        placement VARCHAR(50) DEFAULT 'home',
        active BOOLEAN DEFAULT TRUE,
        display_order INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      
      CREATE INDEX IF NOT EXISTS idx_banners_active ON banners(active);
      CREATE INDEX IF NOT EXISTS idx_banners_placement ON banners(placement);
    `);
    console.log('✅ Banners table created');
    
    // Seed with sample banners/sliders
    console.log('\n📸 Seeding banners...');
    const banners = [
      {
        title: 'Welcome to ShopsNSports',
        description: 'Your one-stop shop for everything',
        image_url: 'https://images.unsplash.com/photo-1556740758-90de374c12ad?w=800',
        display_order: 1
      },
      {
        title: 'New Electronics Collection',
        description: 'Latest gadgets and devices',
        image_url: 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=800',
        display_order: 2
      },
      {
        title: 'Fitness Equipment Sale',
        description: 'Up to 50% off on selected items',
        image_url: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
        display_order: 3
      },
      {
        title: 'Premium Audio Gear',
        description: 'Experience superior sound quality',
        image_url: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800',
        display_order: 4
      },
      {
        title: 'Smart Home Devices',
        description: 'Make your home smarter',
        image_url: 'https://images.unsplash.com/photo-1558089687-0e4866f9d67d?w=800',
        display_order: 5
      }
    ];
    
    for (const banner of banners) {
      await client.query(
        `INSERT INTO banners (title, description, image_url, placement, active, display_order) 
         VALUES ($1, $2, $3, 'home', TRUE, $4)`,
        [banner.title, banner.description, banner.image_url, banner.display_order]
      );
    }
    
    const count = await client.query('SELECT COUNT(*) FROM banners');
    console.log(`✅ Created ${count.rows[0].count} banners`);
    
    // Show sample
    const sample = await client.query('SELECT * FROM banners ORDER BY display_order LIMIT 3');
    console.log('\n📊 Sample banners:');
    sample.rows.forEach(b => {
      console.log(`   ${b.display_order}. ${b.title} - ${b.image_url.substring(0, 50)}...`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

setupBanners();
