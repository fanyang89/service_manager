import 'package:file_picker/file_picker.dart';

Future<String?> pickExecutablePath() async {
  final result = await FilePicker.pickFiles(
    type: FileType.any,
    allowMultiple: false,
  );
  return result?.files.single.path;
}

Future<String?> pickDirectoryPath() => FilePicker.getDirectoryPath();
