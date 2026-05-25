/*
Generate a local JSON file with sample invoices for development/demo.
This does NOT write to any remote DB.

Usage:
  node scripts/generate_invoices_seed.js --count=50

Output: scripts/invoices_seed.json
*/

const fs = require('fs');
const path = require('path');
const { program } = require('commander');

program.option('-c, --count <n>', 'number of invoices', '50');
program.parse(process.argv);
const opts = program.opts();
const COUNT = parseInt(opts.count, 10) || 50;

const vendors = ['Acme Corp', 'Smart Solutions', 'BlueGoods', 'GearWorks'];
const customers = ['Alpha LLC', 'Beta Co', 'Gamma Inc', 'Delta Ltd'];
const statuses = ['draft','sent','paid','cancelled'];

function makeLine(i, j) {
  return {
    description: `Item ${i}-${j}`,
    quantity: (j % 3) + 1,
    unitPrice: Math.round((10 + Math.random() * 90) * 100) / 100,
  };
}

const out = [];
for (let i = 0; i < COUNT; i++) {
  const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
  const due = new Date(date.getTime() + 30 * 24 * 60 * 60 * 1000);
  const lines = [];
  for (let j = 0; j < 1 + (i % 3); j++) lines.push(makeLine(i + 1, j + 1));
  const obj = {
    id: `seed_inv_${i + 1}`,
    invoiceNumber: `INV-${1000 + i}`,
    date: date.toISOString(),
    dueDate: due.toISOString(),
    customerId: `cust_${(i % customers.length) + 1}`,
    customerName: customers[i % customers.length],
    status: statuses[i % statuses.length],
    lines,
    taxRate: 0.15,
    seeded: true,
    seedTag: 'dev_invoices_v1',
  };
  out.push(obj);
}

const outPath = path.join(__dirname, 'invoices_seed.json');
fs.writeFileSync(outPath, JSON.stringify(out, null, 2));
console.log(`Wrote ${out.length} invoices to ${outPath}`);
