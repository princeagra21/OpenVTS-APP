import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedFilePayload {
  final String filename;
  final Uint8List bytes;

  const PickedFilePayload({required this.filename, required this.bytes});
}

/// Placeholder helper for multipart upload flows.
///
/// Keeps file picking out of the repository logic while still providing a
/// ready-to-use shape (`bytes` + `filename`) for `MultipartFile.fromBytes(...)`.
Future<PickedFilePayload?> pickSingleFilePayload() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;

  final file = result.files.single;
  final bytes = file.bytes;
  final name = file.name;
  if (bytes == null) return null;

  return PickedFilePayload(filename: name, bytes: bytes);
}
