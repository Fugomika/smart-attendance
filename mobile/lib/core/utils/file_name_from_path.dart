String fileNameFromPath(String path, {String fallback = 'upload.jpg'}) {
  final normalized = path.replaceAll('\\', '/');
  final segments = normalized.split('/');
  final fileName = segments.isNotEmpty ? segments.last : '';
  return fileName.trim().isEmpty ? fallback : fileName;
}
