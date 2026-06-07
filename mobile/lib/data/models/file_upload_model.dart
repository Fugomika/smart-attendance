class FileUploadModel {
  const FileUploadModel({
    required this.id,
    required this.originalName,
    required this.contentType,
    required this.context,
    required this.url,
    required this.status,
    this.createdAt,
  });

  factory FileUploadModel.fromJson(Map<String, dynamic> json) {
    return FileUploadModel(
      id: json['id']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? '',
      contentType: json['contentType']?.toString() ?? '',
      context: json['context']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  final String id;
  final String originalName;
  final String contentType;
  final String context;
  final String url;
  final String status;
  final DateTime? createdAt;
}
