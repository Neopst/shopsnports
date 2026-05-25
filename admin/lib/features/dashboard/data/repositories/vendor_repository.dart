// lib/features/dashboard/data/repositories/vendor_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor_model.dart';

class VendorRepository {
  final _db = FirebaseFirestore.instance;
  final _collection = 'vendors';

  /// Create a new vendor
  Future<void> createVendor(VendorModel vendor) async {
    await _db.collection(_collection).doc(vendor.vendorId).set(vendor.toMap());
  }

  /// Get all vendors as a stream
  Stream<List<VendorModel>> getAllVendors() {
    return _db.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => VendorModel.fromDoc(doc)).toList();
    });
  }

  /// Get vendor by ID
  Future<VendorModel?> getVendorById(String vendorId) async {
    final doc = await _db.collection(_collection).doc(vendorId).get();
    if (!doc.exists) return null;
    return VendorModel.fromDoc(doc);
  }

  /// Approve or disapprove vendor
  Future<void> updateApproval(String vendorId, bool approved) async {
    await _db.collection(_collection).doc(vendorId).update({
      'approved': approved,
    });
  }

  /// Delete vendor
  Future<void> deleteVendor(String vendorId) async {
    await _db.collection(_collection).doc(vendorId).delete();
  }
}
