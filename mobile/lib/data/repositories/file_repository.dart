import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/file_upload_model.dart';

class FileRepository {
  const FileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<FileUploadModel> uploadProfilePhoto(String filePath) {
    return _upload(filePath: filePath, context: 'profile_photo');
  }

  Future<FileUploadModel> uploadAttendanceSelfie(String filePath) {
    return _upload(filePath: filePath, context: 'attendance_selfie');
  }

  Future<FileUploadModel> _upload({
    required String filePath,
    required String context,
  }) async {
    final response = await _apiClient.postMultipart<FileUploadModel>(
      '/files',
      data: FormData.fromMap({
        'context': context,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: _fileNameFromPath(filePath),
        ),
      }),
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return FileUploadModel.fromJson(json);
        }

        throw const FormatException('Invalid file upload response.');
      },
    );

    return response.data;
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    final fileName = segments.isNotEmpty ? segments.last : '';
    return fileName.trim().isEmpty ? 'upload.jpg' : fileName;
  }
}
