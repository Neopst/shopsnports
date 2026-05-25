#!/usr/bin/env node
// Usage: node create-admin-user.js --username alice --password secret --role admin
const db = require('./db');
const bcrypt = require('bcryptjs');

async function main() {
  const argv = require('minimist')(process.argv.slice(2));
  const username = argv.username || argv.u;
  const password = argv.password || argv.p;
  const role = argv.role || 'admin';
  if (!username || !password) {
    console.error('Usage: node create-admin-user.js --username <name> --password <pw> [--role admin]');
    process.exit(1);
  }
  if (!db || typeof db.createUser !== 'function') {
    console.error('DB not available or does not support createUser. Ensure DATABASE_URL is set and the server has been initialized.');
    process.exit(2);
  }
  try {
    const hash = await bcrypt.hash(password, 10);
    const user = await db.createUser(username, hash, role);
    console.log('User created:', user);
    process.exit(0);
  } catch (err) {
    console.error('Error creating user:', err.message || err);
    process.exit(3);
  }
}

main();
