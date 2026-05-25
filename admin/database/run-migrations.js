// Run all database migrations using Node.js
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  host: 'marketplace-db.ceno66e8mz81.us-east-1.rds.amazonaws.com',
  user: 'admin0',
  password: 'ShopsNSports2024!',
  database: 'marketplace',
  port: 5432,
  ssl: { rejectUnauthorized: false }
});

async function runMigrations() {
  console.log('\n🚀 Starting database migrations...\n');
  
  const migrationsDir = path.join(__dirname, 'migrations');
  const files = fs.readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql'))
    .sort();
  
  console.log(`Found ${files.length} migration files\n`);
  
  for (const file of files) {
    try {
      console.log(`▶ Running: ${file}`);
      const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
      await pool.query(sql);
      console.log(`✅ ${file} completed\n`);
    } catch (error) {
      console.error(`❌ ${file} failed:`);
      console.error(error.message);
      process.exit(1);
    }
  }
  
  console.log('========================================');
  console.log('✨ All migrations completed successfully!');
  console.log('========================================\n');
  
  // Show created tables
  console.log('📊 Verifying tables created...\n');
  const result = await pool.query(`
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    ORDER BY table_name
  `);
  
  result.rows.forEach(row => {
    console.log(`  ✓ ${row.table_name}`);
  });
  
  await pool.end();
}

runMigrations().catch(console.error);
