class AIModel {
  final String id;
  final String name;
  final String size;
  final String ramRequired;
  final String quantization;
  final String description;
  final String downloadUrl;
  final String fileName;
  bool installed;
  bool isDownloaded;
  bool isDownloading;
  double downloadProgress;
  final bool isRecommended;

  AIModel({
    required this.id,
    required this.name,
    required this.size,
    required this.ramRequired,
    required this.quantization,
    required this.description,
    required this.downloadUrl,
    required this.fileName,
    this.installed = false,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.isRecommended = false,
  });

  AIModel copyWith({
    bool? installed,
    bool? isDownloaded,
    bool? isDownloading,
    double? downloadProgress,
  }) {
    return AIModel(
      id: id,
      name: name,
      size: size,
      ramRequired: ramRequired,
      quantization: quantization,
      description: description,
      downloadUrl: downloadUrl,
      fileName: fileName,
      installed: installed ?? this.installed,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isRecommended: isRecommended,
    );
  }
}
export_model_example() {}

