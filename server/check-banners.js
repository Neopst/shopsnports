const { Client } = require('pg');

const client = new Client({
  host: 'marketplace-db.ceno66e8mz81.us-east-1.rds.amazonaws.com',
  port: 5432,
  user: 'admin0',
  password: 'Marketplace2025SecurePass!',
  database: 'marketplace',
  ssl: { rejectUnauthorized: false }
});

async function checkBanners() {
  try {
    await client.connect();
    console.log('✅ Connected to PostgreSQL');
    
    // Check if banners table exists
    const tableCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'banners'
      );
    `);
    
    console.log('\n📊 Banners table exists:', tableCheck.rows[0].exists);
    
    if (tableCheck.rows[0].exists) {
      const count = await client.query('SELECT COUNT(*) FROM banners');
      console.log('📊 Banners count:', count.rows[0].count);
      
      if (parseInt(count.rows[0].count) > 0) {
        const banners = await client.query('SELECT * FROM banners LIMIT 5');
        console.log('\n📸 Sample banners:', JSON.stringify(banners.rows, null, 2));
      }
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

checkBanners();
