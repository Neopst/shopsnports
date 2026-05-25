import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import '../utils/app_logger.dart';

class StorageService {
  /// Uploads a local file to Firebase Storage under `avatars/{uid}_{ts}` and
  /// returns the public download URL.
  /// Throws on error.
  static Future<String> uploadAvatar({
    required String uid,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref =
        FirebaseStorage.instance.ref().child('avatars').child('${uid}_$ts');
    final uploadTask = ref.putFile(file);

    if (onProgress != null) {
      // Listen to snapshot events and report progress
      final sub = uploadTask.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        if (total > 0) {
          try {
            onProgress(transferred / total);
          } catch (e) {
            AppLogger.error('Progress callback error', e);
          }
        }
      });
      try {
        final snapshot = await uploadTask;
        await sub.cancel();
        final url = await snapshot.ref.getDownloadURL();
        return url;
      } catch (e) {
        await sub.cancel();
        AppLogger.error('Avatar upload failed', e);
        rethrow;
      }
    } else {
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      return url;
    }
  }

  /// Uploads a file to Firebase Storage under the provided folder and returns
  /// the download URL.
  static Future<String> uploadFile({
    required String folder,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance.ref().child(folder).child('file_$ts');
    final uploadTask = ref.putFile(file);

    if (onProgress != null) {
      final sub = uploadTask.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        if (total > 0) {
          try {
            onProgress(transferred / total);
          } catch (e) {
            AppLogger.error('Progress callback error', e);
          }
        }
      });
      try {
        final snapshot = await uploadTask;
        await sub.cancel();
        return await snapshot.ref.getDownloadURL();
      } catch (e) {
        await sub.cancel();
        AppLogger.error('File upload failed', e);
        rethrow;
      }
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}

/// Top-level helper to upload a file to Firebase Storage.
/// Kept as a function to avoid potential static method resolution issues
/// in some dev/hot-reload environments.
Future<String> uploadFileToStorage({
  required String folder,
  required File file,
  void Function(double progress)? onProgress,
}) async {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final ref = FirebaseStorage.instance.ref().child(folder).child('file_$ts');
  final uploadTask = ref.putFile(file);

  if (onProgress != null) {
    final sub = uploadTask.snapshotEvents.listen((snapshot) {
      final total = snapshot.totalBytes;
      final transferred = snapshot.bytesTransferred;
      if (total > 0) {
        try {
          onProgress(transferred / total);
        } catch (e) {
          AppLogger.error('Progress callback error', e);
        }
      }
    });
    try {
      final snapshot = await uploadTask;
      await sub.cancel();
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      await sub.cancel();
      AppLogger.error('File upload failed', e);
      rethrow;
    }
  }

  final snapshot = await uploadTask;
  return await snapshot.ref.getDownloadURL();
}
