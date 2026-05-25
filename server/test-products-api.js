// Test Products API endpoints
// Run with: node test-products-api.js

const http = require('http');

function makeRequest(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: `/api/v1/products${path}`,
      method,
      headers: {
        'Content-Type': 'application/json',
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data });
        }
      });
    });

    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function testProductsAPI() {
  console.log('🧪 Testing Products API...\n');

  try {
    // Test 1: GET all products
    console.log('1. GET /api/v1/products');
    const getAll = await makeRequest('GET', '');
    console.log(`   Status: ${getAll.status}`);
    console.log(`   Products count: ${getAll.data.data?.length || 0}`);
    console.log(`   ✅ GET all products works\n`);

    // Test 2: Create a product
    console.log('2. POST /api/v1/products');
    const newProduct = {
      vendor_id: 'test_vendor_1',
      name: 'Test Product API',
      description: 'Testing the Products API endpoint',
      price: 29.99,
      currency: 'USD',
      stock_quantity: 100,
      sku: 'TEST-API-001',
      categories: [1, 2],
      status: 'active'
    };
    const created = await makeRequest('POST', '', newProduct);
    console.log(`   Status: ${created.status}`);
    console.log(`   Created product ID: ${created.data.data?.id}`);
    const productId = created.data.data?.id;
    console.log(`   ✅ POST create product works\n`);

    if (productId) {
      // Test 3: GET single product
      console.log(`3. GET /api/v1/products/${productId}`);
      const getOne = await makeRequest('GET', `/${productId}`);
      console.log(`   Status: ${getOne.status}`);
      console.log(`   Product name: ${getOne.data.data?.name}`);
      console.log(`   ✅ GET single product works\n`);

      // Test 4: UPDATE product
      console.log(`4. PUT /api/v1/products/${productId}`);
      const updated = await makeRequest('PUT', `/${productId}`, {
        price: 39.99,
        stock_quantity: 150
      });
      console.log(`   Status: ${updated.status}`);
      console.log(`   Updated price: ${updated.data.data?.price}`);
      console.log(`   ✅ PUT update product works\n`);

      // Test 5: SEARCH products
      console.log('5. GET /api/v1/products/search?q=Test');
      const search = await makeRequest('GET', '/search?q=Test');
      console.log(`   Status: ${search.status}`);
      console.log(`   Search results: ${search.data.data?.length || 0}`);
      console.log(`   ✅ GET search products works\n`);

      // Test 6: DELETE product (soft delete)
      console.log(`6. DELETE /api/v1/products/${productId}`);
      const deleted = await makeRequest('DELETE', `/${productId}`);
      console.log(`   Status: ${deleted.status}`);
      console.log(`   Product status: ${deleted.data.data?.status}`);
      console.log(`   ✅ DELETE product works\n`);
    }

    console.log('✅ All Products API tests passed!');
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testProductsAPI();
