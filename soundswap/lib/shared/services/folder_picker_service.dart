import 'package:file_picker/file_picker.dart';

class FolderPickerService {
  Future<String?> pickFolder({required String dialogTitle}) {
    return FilePicker.platform.getDirectoryPath(dialogTitle: dialogTitle);
  }
}
