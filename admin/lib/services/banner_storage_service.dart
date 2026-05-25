import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/utils/app_logger.dart';

/// Service to handle Firebase Storage operations for banner images
class BannerStorageService {
  // Always bind to the canonical bucket to avoid configuration mix‑ups.
  // `FirebaseStorage.instance` will use `Firebase.app().options.storageBucket`
  // which has been misconfigured in some builds, so we opt for an explicit
  // reference. This guarantees that uploads go to the correct bucket and
  // avoids the CORS failures that occur when the default bucket
  // (`shopsnports.appspot.com`) is accidentally used.
  static final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'shopsnports.firebasestorage.app',
  );

  /// Upload banner image to Firebase Storage
  ///
  /// Parameters:
  ///   - imageBytes: The image file bytes
  ///   - fileName: Name for the file (e.g., "fast-shipping.jpg")
  ///
  /// Returns: Download URL or null if upload fails
  static Future<String?> uploadBannerImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      AppLogger.info('Uploading banner image: $fileName', tag: 'Storage');

      // Create reference to storage path: banners/[fileName]
      final ref = _storage.ref().child('banners/$fileName');

      // Upload the file
      final uploadTask = ref.putData(imageBytes);

      // Monitor progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        AppLogger.debug('Upload progress: ${progress.toStringAsFixed(0)}%', tag: 'Storage');
      });

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      AppLogger.info('Banner uploaded successfully', tag: 'Storage');

      return downloadUrl;
    } catch (e) {
      AppLogger.error('Banner upload failed: $e', tag: 'Storage');
      return null;
    }
  }

  /// Upload banner image from file path (for web)
  /// Returns Storage path (e.g., "banners/fast-shipping.jpg") for use in Firestore
  static Future<String?> uploadBannerImageWeb({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      AppLogger.debug('Storage bucket in use: ${_storage.app.options.storageBucket}', tag: 'Storage');
      AppLogger.info('Uploading banner image to Storage: $fileName', tag: 'Storage');
      AppLogger.debug('File size: ${(imageBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB', tag: 'Storage');

      final ref = _storage.ref().child('banners/$fileName');

      // Upload with better error handling
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        AppLogger.debug('Upload progress: ${progress.toStringAsFixed(0)}%', tag: 'Storage');
      });

      // Wait for upload to complete
      final taskSnapshot = await uploadTask;
      AppLogger.info('Uploaded to Storage: ${taskSnapshot.metadata?.fullPath}', tag: 'Storage');

      // Return relative path for Firestore (so mobile app can resolve it)
      final storagePath = 'banners/$fileName';
      AppLogger.info('Stored at path: $storagePath', tag: 'Storage');

      return storagePath;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error (${e.code}): ${e.message}', tag: 'Storage');
      return null;
    } catch (e) {
      AppLogger.error('Upload failed: $e', tag: 'Storage');
      return null;
    }
  }

  /// Get download URL for a banner image
  static Future<String?> getBannerImageUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      AppLogger.error('Failed to get download URL: $e', tag: 'Storage');
      return null;
    }
  }

  /// Delete banner image from Storage
  static Future<bool> deleteBannerImage(String storagePath) async {
    try {
      AppLogger.info('Deleting banner image: $storagePath', tag: 'Storage');
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
      AppLogger.info('Image deleted', tag: 'Storage');
      return true;
    } catch (e) {
      AppLogger.error('Delete failed: $e', tag: 'Storage');
      return false;
    }
  }
}
