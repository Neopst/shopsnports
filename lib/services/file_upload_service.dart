import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

/// File upload service for Cloud Storage
class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Constants
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxTotalSizeBytes = 50 * 1024 * 1024; // 50MB
  static const String allowedExtensions = 'pdf,doc,docx,jpg,jpeg,png,xlsx,xls';

  /// Pick files from device
  /// Returns list of PlatformFile with validation
  Future<List<PlatformFile>?> pickFiles({int maxFiles = 5}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions.split(','),
        allowMultiple: true,
        onFileLoading: (FilePickerStatus status) {},
        withData: false,
        withReadStream: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      // Validate file count
      if (result.files.length > maxFiles) {
        throw Exception('Maximum $maxFiles files allowed');
      }

      // Validate individual file sizes
      for (final file in result.files) {
        if (file.size > maxFileSizeBytes) {
          throw Exception(
            '${file.name} exceeds 10MB limit (${(file.size / 1024 / 1024).toStringAsFixed(2)}MB)',
          );
        }
      }

      // Validate total size
      final totalSize = result.files.fold<int>(0, (sum, f) => sum + f.size);
      if (totalSize > maxTotalSizeBytes) {
        throw Exception(
          'Total file size exceeds 50MB limit (${(totalSize / 1024 / 1024).toStringAsFixed(2)}MB)',
        );
      }

      return result.files;
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('File picker error: $e');
    }
  }

  /// Upload a single file to Cloud Storage
  /// Returns file URL and metadata
  Future<Map<String, dynamic>> uploadFile({
    required PlatformFile file,
    required String requestId,
    String fileType = 'other',
  }) async {
    try {
      // Generate unique file name
      final fileId = const Uuid().v4();
      final extension = file.name.split('.').last;
      final fileName = '$fileId.$extension';

      // Cloud Storage path: shipping_requests/{requestId}/{fileName}
      final storageRef =
          _storage.ref().child('shipping_requests/$requestId/$fileName');

      // Upload with metadata
      final uploadTask = storageRef.putFile(
        File(file.path!),
        SettableMetadata(
          contentType: _getMimeType(extension),
          customMetadata: {
            'originalName': file.name,
            'fileType': fileType,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL (valid for ~7 days by default)
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return {
        'id': fileId,
        'fileName': file.name,
        'fileUrl': downloadUrl,
        'fileType': fileType,
        'fileSizeBytes': file.size,
        'uploadedAt': DateTime.now(),
      };
    } on FirebaseException catch (e) {
      throw Exception('Upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  /// Upload multiple files
  Future<List<Map<String, dynamic>>> uploadFiles({
    required List<PlatformFile> files,
    required String requestId,
  }) async {
    final uploadedFiles = <Map<String, dynamic>>[];

    for (final file in files) {
      try {
        final result = await uploadFile(
          file: file,
          requestId: requestId,
          fileType: _detectFileType(file.name),
        );
        uploadedFiles.add(result);
      } catch (e) {
        // Log error but continue with other files
        rethrow;
      }
    }

    return uploadedFiles;
  }

  /// Delete a file from Cloud Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Extract path from URL
      final decodedUrl = Uri.decodeFull(fileUrl);
      final startIndex = decodedUrl.indexOf('/o/') + 3;
      final endIndex = decodedUrl.indexOf('?');
      final filePath = decodedUrl.substring(
        startIndex,
        endIndex > 0 ? endIndex : decodedUrl.length,
      );

      await _storage.ref(filePath).delete();
    } on FirebaseException catch (e) {
      throw Exception('Delete failed: ${e.message}');
    } catch (e) {
      throw Exception('Delete error: $e');
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String extension) {
    final mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'xls': 'application/vnd.ms-excel',
    };
    return mimeTypes[extension.toLowerCase()] ?? 'application/octet-stream';
  }

  /// Detect file type from file name
  String _detectFileType(String fileName) {
    final nameLower = fileName.toLowerCase();
    if (nameLower.contains('invoice')) return 'invoice';
    if (nameLower.contains('proforma') || nameLower.contains('pro forma')) {
      return 'proforma';
    }
    if (nameLower.contains('packing') || nameLower.contains('pack list')) {
      return 'packing_list';
    }
    if (nameLower.contains('insurance') || nameLower.contains('cert')) {
      return 'other';
    }
    return 'other';
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}
