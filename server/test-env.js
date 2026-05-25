require('dotenv').config();
const { Client } = require('pg');

console.log('DATABASE_URL from .env:', process.env.DATABASE_URL ? 'FOUND' : 'NOT FOUND');
console.log('Full URL:', process.env.DATABASE_URL);

const client = new Client({
  connectionString: process.env.DATABASE_URL
});

client.connect()
  .then(() => {
    console.log('✅ SUCCESS! Connected to AWS RDS using .env DATABASE_URL!');
    return client.query('SELECT version()');
  })
  .then(res => {
    console.log('PostgreSQL version:', res.rows[0].version);
    client.end();
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ ERROR:', err.message);
    process.exit(1);
  });
