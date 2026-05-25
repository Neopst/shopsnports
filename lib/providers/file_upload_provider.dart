import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shopsnports/services/file_upload_service.dart';

/// File upload service provider (singleton)
final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  return FileUploadService();
});

/// File picker provider - manages selected files (local, not uploaded)
class FilePickerNotifier extends StateNotifier<List<PlatformFile>> {
  FilePickerNotifier() : super([]);

  Future<void> pickFiles({int maxFiles = 5}) async {
    final fileUploadService =
        FileUploadService(); // Use temporary instance or inject
    try {
      final pickedFiles = await fileUploadService.pickFiles(maxFiles: maxFiles);
      if (pickedFiles != null) {
        state = [...state, ...pickedFiles];
      }
    } catch (e) {
      rethrow;
    }
  }

  void removeFile(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
  }

  void clearAll() {
    state = [];
  }

  int getTotalSize() {
    return state.fold<int>(0, (sum, file) => sum + file.size);
  }

  bool canAddMore({int maxFiles = 5}) {
    return state.length < maxFiles;
  }
}

final filePickerProvider =
    StateNotifierProvider<FilePickerNotifier, List<PlatformFile>>((ref) {
  return FilePickerNotifier();
});

/// File upload progress provider
class FileUploadNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final FileUploadService _fileUploadService;

  FileUploadNotifier(this._fileUploadService)
      : super(const AsyncValue.data([]));

  Future<void> uploadFiles({
    required List<PlatformFile> files,
    required String requestId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final uploadedFiles = await _fileUploadService.uploadFiles(
          files: files, requestId: requestId);
      state = AsyncValue.data(uploadedFiles);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void reset() {
    state = const AsyncValue.data([]);
  }
}

final fileUploadProvider = StateNotifierProvider<FileUploadNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final fileUploadService = ref.watch(fileUploadServiceProvider);
  return FileUploadNotifier(fileUploadService);
});
