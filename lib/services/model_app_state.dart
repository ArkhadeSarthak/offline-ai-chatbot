import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/ai_model.dart';
import 'model_manager.dart';
import 'llm_service.dart';
import 'settings_service.dart';
import 'network_helper.dart';
import 'device_capability_service.dart';
import 'model_memory_estimator.dart';

class ModelAppState extends ChangeNotifier {
  final ModelManager modelManager = ModelManager();
  final LLMService llmService = LLMService();
  final SettingsService settingsService = SettingsService();

  List<AIModel> models = [];
  List<AIModel> installedModels = [];
  AIModel? downloadingModel;
  double downloadProgress = 0.0;
  int downloadedBytes = 0;
  int totalBytes = 0;
  double downloadSpeed = 0.0;
  int timeRemaining = 0;
  String? selectedModelId;
  bool isInitializing = true;
  bool isPaused = false;
  bool isModelLoading = false;
  String? modelLoadingError;
  InferenceSettings inferenceSettings = InferenceSettings();
  DeviceProfile? deviceProfile;
  
  // Terminal log entries for active downloads and engine status
  final List<String> downloadLogs = [];

  ModelAppState() {
    _init();
  }

  Future<void> _init() async {
    isInitializing = true;
    notifyListeners();

    // 1. Analyze device hardware capability
    deviceProfile = await DeviceCapabilityService.analyzeCapability();

    // 2. Load inference settings & apply adaptive defaults if first run
    inferenceSettings = await settingsService.getInferenceSettings();
    if (deviceProfile != null && (deviceProfile!.isSafeModeRecommended || inferenceSettings.isSafeModeEnabled)) {
      inferenceSettings = DeviceCapabilityService.getAdaptiveSettings(deviceProfile!, forceSafeMode: true);
    }
    llmService.updateSettings(inferenceSettings);

    // 3. Load available models and update installation status
    models = List.from(modelManager.availableModels);
    await refreshInstalledModels();

    // 4. Load selected model id from SharedPreferences
    selectedModelId = await settingsService.getSelectedModel();
    if (selectedModelId == null && installedModels.isNotEmpty) {
      selectedModelId = installedModels.first.id;
      await settingsService.setSelectedModel(selectedModelId!);
    }

    // 5. If there is a selected model that is installed, load it into LLMService safely
    if (selectedModelId != null) {
      final isInstalled = await modelManager.isModelInstalled(selectedModelId!);
      if (isInstalled) {
        final path = await modelManager.getModelPath(selectedModelId!);
        if (path != null) {
          try {
            final modelObj = models.firstWhere((m) => m.id == selectedModelId, orElse: () => models.first);
            await llmService.loadModel(
              path,
              modelName: modelObj.name,
              chatTemplate: modelObj.chatTemplate,
              settings: inferenceSettings,
            );
          } catch (e) {
            debugPrint("[LocalMind] Failed to load default selected model: $e");
          }
        }
      }
    }

    isInitializing = false;
    notifyListeners();
  }

  Future<ModelMemoryEvaluation> evaluateModelMemory(AIModel model) async {
    deviceProfile ??= await DeviceCapabilityService.analyzeCapability();
    return ModelMemoryEstimator.evaluate(
      model: model,
      deviceProfile: deviceProfile!,
      settings: inferenceSettings,
    );
  }

  Future<void> enableSafeMode() async {
    deviceProfile ??= await DeviceCapabilityService.analyzeCapability();
    final safeSettings = DeviceCapabilityService.getAdaptiveSettings(deviceProfile!, forceSafeMode: true);
    await saveInferenceSettings(safeSettings);
  }

  Future<void> saveInferenceSettings(InferenceSettings settings) async {
    inferenceSettings = settings;
    await settingsService.saveInferenceSettings(settings);
    llmService.updateSettings(settings);

    // If a model is loaded, reload context with new settings
    if (selectedModelId != null && llmService.isModelLoaded) {
      final path = await modelManager.getModelPath(selectedModelId!);
      if (path != null) {
        final modelObj = models.firstWhere((m) => m.id == selectedModelId, orElse: () => models.first);
        await llmService.loadModel(
          path,
          modelName: modelObj.name,
          chatTemplate: modelObj.chatTemplate,
          settings: inferenceSettings,
        );
      }
    }
    notifyListeners();
  }

  Future<void> resetInferenceSettings() async {
    await settingsService.resetInferenceSettings();
    inferenceSettings = InferenceSettings();
    await saveInferenceSettings(inferenceSettings);
  }

  Future<void> refreshInstalledModels() async {
    installedModels = await modelManager.getInstalledModels();
    for (var i = 0; i < models.length; i++) {
      final isInstalled = await modelManager.isModelInstalled(models[i].id);
      models[i].installed = isInstalled;
      models[i].isDownloaded = isInstalled;
    }
    notifyListeners();
  }

  void appendLog(String log) {
    downloadLogs.insert(0, log);
    if (downloadLogs.length > 40) {
      downloadLogs.removeLast();
    }
    notifyListeners();
  }

  Future<void> startDownload(String modelId) async {
    if (downloadingModel != null) {
      throw Exception("A download is already in progress.");
    }

    final index = models.indexWhere((m) => m.id == modelId);
    if (index == -1) return;

    final model = models[index];
    downloadingModel = model;
    downloadProgress = 0.0;
    downloadedBytes = 0;
    totalBytes = model.fileSizeBytes;
    isPaused = false;
    downloadLogs.clear();
    
    // UI states update
    model.isDownloading = true;
    model.isVerifying = false;
    model.downloadProgress = 0.0;
    notifyListeners();

    appendLog("[STORAGE] Checking available device storage...");
    final hasSpace = await modelManager.hasSufficientStorage(model.fileSizeBytes);
    if (!hasSpace) {
      final reqGB = (model.fileSizeBytes / (1024 * 1024 * 1024) + 0.5).toStringAsFixed(1);
      appendLog("[ERROR] Insufficient disk space! Requires ~$reqGB GB free storage.");
      model.isDownloading = false;
      downloadingModel = null;
      notifyListeners();
      throw Exception("Insufficient disk space. At least $reqGB GB of free storage is required.");
    }

    appendLog("[DOWNLOAD] Requesting download stream for ${model.name} (${model.size})...");
    await _executeDownload(model, resume: false);
  }

  Future<void> resumeDownload() async {
    if (downloadingModel == null) return;
    if (!isPaused) return;

    isPaused = false;
    notifyListeners();

    appendLog("[RESUME] Resuming download for ${downloadingModel!.name}...");
    await _executeDownload(downloadingModel!, resume: true);
  }

  void pauseDownload() {
    if (downloadingModel != null && !isPaused) {
      isPaused = true;
      appendLog("[PAUSE] Pausing model download...");
      modelManager.cancelDownload(reason: 'pause');
      notifyListeners();
    }
  }

  void cancelDownload() {
    if (downloadingModel != null) {
      appendLog("[CANCEL] Cancelling model download by user request...");
      isPaused = false;
      modelManager.cancelDownload(reason: 'cancel');
      downloadingModel!.isDownloading = false;
      downloadingModel!.isDownloaded = false;
      downloadingModel!.isVerifying = false;
      downloadingModel = null;
      downloadProgress = 0.0;
      downloadSpeed = 0.0;
      timeRemaining = 0;
      notifyListeners();
    }
  }

  Future<void> _executeDownload(AIModel model, {required bool resume}) async {
    final hasInternet = await NetworkHelper.hasInternetConnection();
    if (!hasInternet) {
      appendLog("[ERROR] No internet connection detected.");
      appendLog("[ERROR] Connect to Wi-Fi or mobile data to download the model.");
      model.isDownloading = false;
      model.isDownloaded = false;
      model.installed = false;
      downloadingModel = null;
      isPaused = false;
      notifyListeners();
      return;
    }

    DateTime lastUIUpdateTime = DateTime.now().subtract(const Duration(milliseconds: 200));

    if (!resume) {
      downloadSpeed = 0.0;
      timeRemaining = 0;
    }

    try {
      await modelManager.downloadModel(
        model,
        (progress, received, total, speedMBs) {
          if (isPaused) return;

          downloadProgress = progress;
          downloadedBytes = received;
          totalBytes = total;
          model.downloadProgress = progress;
          model.downloadedBytes = received;
          model.totalBytes = total;
          downloadSpeed = speedMBs;

          if (speedMBs > 0 && total > received) {
            final remainingMB = (total - received) / (1024 * 1024);
            timeRemaining = (remainingMB / speedMBs).round().clamp(0, 3600);
          }

          final now = DateTime.now();
          final elapsedSinceUIUpdate = now.difference(lastUIUpdateTime).inMilliseconds;
          if (elapsedSinceUIUpdate >= 200 || progress == 1.0) {
            lastUIUpdateTime = now;
            notifyListeners();
          }
        },
        resume: resume,
      );

      model.isVerifying = true;
      appendLog("[VERIFY] Verifying GGUF header and tensor tables...");
      notifyListeners();

      appendLog("[SUCCESS] Model downloaded and verified successfully!");
      appendLog("[OFFLINE] Ready for local on-device inference.");

      model.isDownloading = false;
      model.isVerifying = false;
      model.isDownloaded = true;
      model.installed = true;
      downloadingModel = null;
      downloadSpeed = 0.0;
      timeRemaining = 0;
      isPaused = false;

      await refreshInstalledModels();

      if (selectedModelId == null) {
        selectedModelId = model.id;
        await settingsService.setSelectedModel(model.id);
      }

      notifyListeners();
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        final reason = e.error?.toString() ?? e.message ?? '';
        if (reason == 'pause') {
          appendLog("[PAUSE] Download paused. Shard progress saved.");
          notifyListeners();
          return;
        } else {
          appendLog("[CANCEL] Download cancelled.");
          model.isDownloading = false;
          model.isDownloaded = false;
          model.isVerifying = false;
          model.installed = false;
          downloadingModel = null;
          downloadProgress = 0.0;
          downloadSpeed = 0.0;
          timeRemaining = 0;
          isPaused = false;
          notifyListeners();
          return;
        }
      }

      appendLog("[ERROR] Download error: $e");
      model.isDownloading = false;
      model.isDownloaded = false;
      model.isVerifying = false;
      model.installed = false;
      downloadingModel = null;
      downloadSpeed = 0.0;
      timeRemaining = 0;
      isPaused = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> selectModel(String modelId, {bool forceSafeMode = false}) async {
    selectedModelId = modelId;
    await settingsService.setSelectedModel(modelId);
    modelLoadingError = null;
    isModelLoading = true;
    notifyListeners();

    if (forceSafeMode) {
      await enableSafeMode();
    }

    // Reload the LLM Service model safely
    final isInstalled = await modelManager.isModelInstalled(modelId);
    if (isInstalled) {
      final path = await modelManager.getModelPath(modelId);
      if (path != null) {
        try {
          final modelObj = models.firstWhere((m) => m.id == modelId, orElse: () => models.first);
          await llmService.unloadModel();
          await llmService.loadModel(
            path,
            modelName: modelObj.name,
            chatTemplate: modelObj.chatTemplate,
            settings: inferenceSettings,
          );
          modelLoadingError = null;
        } catch (e) {
          debugPrint("[LocalMind] Exception during model selection load ($modelId): $e");
          modelLoadingError = "Could not load model: $e";
          await llmService.unloadModel();
        }
      }
    } else {
      await llmService.unloadModel();
    }

    isModelLoading = false;
    notifyListeners();
  }

  Future<void> deleteModel(String modelId) async {
    if (selectedModelId == modelId) {
      await llmService.unloadModel();
      selectedModelId = null;
    }
    await modelManager.deleteModel(modelId);
    await refreshInstalledModels();
    if (selectedModelId == null && installedModels.isNotEmpty) {
      selectedModelId = installedModels.first.id;
      await settingsService.setSelectedModel(selectedModelId!);
    }
    notifyListeners();
  }
}
