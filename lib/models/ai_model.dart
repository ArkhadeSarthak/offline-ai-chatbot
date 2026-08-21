class AIModel {
  final String id;
  final String name;
  final String size;
  final int fileSizeBytes;
  final String ramRequired;
  final double minimumRamGB;
  final double recommendedRamGB;
  final String quantization;
  final String description;
  final String downloadUrl;
  final String fileName;
  final String? sha256;
  final int contextLength;
  final String chatTemplate;
  final List<String> capabilities;
  final bool isRecommended;

  bool installed;
  bool isDownloaded;
  bool isDownloading;
  bool isVerifying;
  double downloadProgress;
  int downloadedBytes;
  int totalBytes;

  AIModel({
    required this.id,
    required this.name,
    required this.size,
    required this.fileSizeBytes,
    required this.ramRequired,
    required this.minimumRamGB,
    required this.recommendedRamGB,
    required this.quantization,
    required this.description,
    required this.downloadUrl,
    required this.fileName,
    this.sha256,
    this.contextLength = 2048,
    this.chatTemplate = 'chatml',
    this.capabilities = const ['Chat', 'Reasoning'],
    this.isRecommended = false,
    this.installed = false,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.isVerifying = false,
    this.downloadProgress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
  });

  AIModel copyWith({
    bool? installed,
    bool? isDownloaded,
    bool? isDownloading,
    bool? isVerifying,
    double? downloadProgress,
    int? downloadedBytes,
    int? totalBytes,
  }) {
    return AIModel(
      id: id,
      name: name,
      size: size,
      fileSizeBytes: fileSizeBytes,
      ramRequired: ramRequired,
      minimumRamGB: minimumRamGB,
      recommendedRamGB: recommendedRamGB,
      quantization: quantization,
      description: description,
      downloadUrl: downloadUrl,
      fileName: fileName,
      sha256: sha256,
      contextLength: contextLength,
      chatTemplate: chatTemplate,
      capabilities: capabilities,
      isRecommended: isRecommended,
      installed: installed ?? this.installed,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      isVerifying: isVerifying ?? this.isVerifying,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }
}
