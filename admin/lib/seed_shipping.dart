/// Seeding script disabled - using live Firestore data only
///
/// This script was used for testing with mock data.
/// All historical mock data has been removed.
///
/// To test in production:
/// 1. Create real customer accounts
/// 2. Submit shipping requests through the mobile app
/// 3. View them in the admin dashboard
///
/// NOTE: If you need to populate test data manually in Firestore:
/// 1. Go to Firebase Console
/// 2. Create documents in the 'shippingRequests' collection
/// 3. Use the ShippingRequestSimplified model fields as reference
library;

void main() {
  print('⚠️  Seeding script is disabled - using live Firestore data only');
  print('   Mock data has been removed from all shipping collections');
  print('   Please create real customer submissions for testing');
}
