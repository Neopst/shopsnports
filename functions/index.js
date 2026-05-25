// Import all Cloud Functions
const { onCustomerCreated, sendWelcomeEmailHttp } = require('./lib/onCustomerCreated');

// Export functions
module.exports = {
  onCustomerCreated,
  sendWelcomeEmailHttp,
};
