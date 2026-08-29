import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_picker_service.g.dart';

// Single-method abstract class for DI/mocking, same as every other
// repository/service interface in this codebase.
// ignore: one_member_abstracts
abstract class FilePickerService {
  /// Returns the picked file's path, or `null` if the user cancelled.
  Future<String?> pickJsonFilePath();
}

class DeviceFilePickerService implements FilePickerService {
  @override
  Future<String?> pickJsonFilePath() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return file?.path;
  }
}

@Riverpod(keepAlive: true)
FilePickerService filePickerService(Ref ref) => DeviceFilePickerService();
