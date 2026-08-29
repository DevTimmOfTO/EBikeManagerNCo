import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_picker_service.g.dart';

abstract class ImagePickerService {
  Future<XFile?> pickFromCamera();

  Future<XFile?> pickFromGallery();
}

class DeviceImagePickerService implements ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<XFile?> pickFromCamera() =>
      _picker.pickImage(source: ImageSource.camera, maxWidth: 1600);

  @override
  Future<XFile?> pickFromGallery() =>
      _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
}

@Riverpod(keepAlive: true)
ImagePickerService imagePickerService(Ref ref) => DeviceImagePickerService();
