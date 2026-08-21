import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_model.dart';
import '../services/device_info_helper.dart';
import '../widgets/app_feedback_service.dart';
import 'diagnostics_screen.dart';

class SettingsScreen extends StatefulWidget {
  final List<AIModel> installedModels;
  final Function(String) onDeleteModel;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsScreen({
    Key? key,
    required this.installedModels,
    required this.onDeleteModel,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final bool _quantization = true;
  final bool _gpuAcceleration = true;

  double _totalStorageGB = 0.0;
  double _freeStorageGB = 0.0;
  double _totalRamGB = 0.0;
  double _usedRamGB = 0.0;

  bool _isEditing = false;
  String _savedName = 'User';
  String _savedUsername = '@user_dev';
  String _savedContact = 'user@example.com';
  int _savedAvatarColorIndex = 0;
  bool _savedImageDeleted = false;
  String? _savedImagePath;

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _contactController;
  late int _selectedAvatarColorIndex;
  late bool _selectedImageDeleted;
  String? _selectedImagePath;

  String _getInitials(String fullName) {
    final names =
        fullName.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (names.isEmpty) return 'U';
    if (names.length == 1) return names[0][0].toUpperCase();
    return (names.first[0] + names.last[0]).toUpperCase();
  }

  ImageProvider _getProfileImage(String path) {
    if (kIsWeb) {
      return NetworkImage(path);
    } else {
      return FileImage(io.File(path));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _selectedImageDeleted = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      AppFeedbackService.showToast(context, 'Failed to pick image: $e', isError: true);
    }
  }

  void _showImageSourcePicker(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Image Source',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageSourceButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        theme: theme,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                      _buildImageSourceButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        theme: theme,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final List<List<Color>> _avatarGradients = [
    [const Color(0xFF1AD1D1), const Color(0xFF00F5D4)], // Cyan/Teal
    [const Color(0xFF8A2BE2), const Color(0xFFFF007F)], // Purple/Pink
    [const Color(0xFFFF8C00), const Color(0xFFFFD700)], // Orange/Yellow
    [const Color(0xFF0052D4), const Color(0xFF4364F7)], // Blue/Indigo
  ];

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _savedName = prefs.getString('profile_name') ?? 'User';
        _savedUsername = prefs.getString('profile_username') ?? '@user_dev';
        _savedContact =
            prefs.getString('profile_contact') ?? 'user@example.com';
        _savedAvatarColorIndex = prefs.getInt('profile_color_index') ?? 0;
        _savedImageDeleted = prefs.getBool('profile_image_deleted') ?? false;
        _savedImagePath = prefs.getString('profile_image_path');

        _nameController.text = _savedName;
        _usernameController.text = _savedUsername;
        _contactController.text = _savedContact;
        _selectedAvatarColorIndex = _savedAvatarColorIndex;
        _selectedImageDeleted = _savedImageDeleted;
        _selectedImagePath = _savedImagePath;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _saveProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', _savedName);
      await prefs.setString('profile_username', _savedUsername);
      await prefs.setString('profile_contact', _savedContact);
      await prefs.setInt('profile_color_index', _savedAvatarColorIndex);
      await prefs.setBool('profile_image_deleted', _savedImageDeleted);
      if (_savedImagePath != null) {
        await prefs.setString('profile_image_path', _savedImagePath!);
      } else {
        await prefs.remove('profile_image_path');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
  }

  Future<void> _loadDeviceSpecs() async {
    try {
      final specs = await DeviceInfoHelper.getDeviceSpecs();
      if (mounted) {
        setState(() {
          _totalStorageGB = specs.totalStorageGB;
          _freeStorageGB = specs.freeStorageGB;
          _totalRamGB = specs.totalRamGB;
          _usedRamGB = specs.usedRamGB;
        });
      }
    } catch (e) {
      debugPrint("Error loading device specs: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _savedName);
    _usernameController = TextEditingController(text: _savedUsername);
    _contactController = TextEditingController(text: _savedContact);
    _selectedAvatarColorIndex = _savedAvatarColorIndex;
    _selectedImageDeleted = _savedImageDeleted;
    _selectedImagePath = _savedImagePath;
    _loadProfileData();
    _loadDeviceSpecs();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteModelConfirmation(
      String modelId, String modelName, ThemeData theme) async {
    final modelObj = widget.installedModels.firstWhere((m) => m.id == modelId, orElse: () => widget.installedModels.first);
    final sizeGB = modelObj.fileSizeBytes / (1024.0 * 1024.0 * 1024.0);
    final confirmed = await AppFeedbackService.showDeleteConfirmation(
      context,
      modelName: modelName,
      fileSizeGB: sizeGB,
    );
    if (confirmed) {
      widget.onDeleteModel(modelId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dynamic storage formulas based on real device stats
    final double installedSum = widget.installedModels.fold(0.0, (sum, m) {
      final val = double.tryParse(m.size.split(' ').first) ?? 0.0;
      return sum + val;
    });
    final double totalStorageUsed =
        (_totalStorageGB - _freeStorageGB) + installedSum;
    final double storagePercent = _totalStorageGB > 0
        ? (totalStorageUsed / _totalStorageGB).clamp(0.0, 1.0)
        : 0.0;

    // Dynamic Memory formulas based on real device stats
    double finalRamUsed = _usedRamGB;
    if (_gpuAcceleration) {
      finalRamUsed += _quantization ? 1.5 : 3.0;
    }
    finalRamUsed = finalRamUsed.clamp(0.0, _totalRamGB);
    final double ramPercent =
        _totalRamGB > 0 ? (finalRamUsed / _totalRamGB).clamp(0.0, 1.0) : 0.0;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          children: [
            // Profile Section
            _isEditing
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Profile',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Centered Profile Image & Three Dots Menu
                        Center(
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Profile Picture Circle
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    gradient: _selectedImageDeleted
                                        ? null
                                        : LinearGradient(
                                            colors: _avatarGradients[
                                                _selectedAvatarColorIndex],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    color: _selectedImageDeleted
                                        ? theme.colorScheme.outline
                                            .withValues(alpha: 0.15)
                                        : null,
                                    shape: BoxShape.circle,
                                    image: (_selectedImagePath != null &&
                                            !_selectedImageDeleted)
                                        ? DecorationImage(
                                            image: _getProfileImage(
                                                _selectedImagePath!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    boxShadow: [
                                      if (!_selectedImageDeleted)
                                        BoxShadow(
                                          color: _avatarGradients[
                                                  _selectedAvatarColorIndex][0]
                                              .withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                    ],
                                  ),
                                  child: (_selectedImagePath != null &&
                                          !_selectedImageDeleted)
                                      ? null
                                      : Center(
                                          child: Text(
                                            _getInitials(_nameController.text),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedImageDeleted
                                                  ? theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.4)
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                ),
                                // Positioned Vertical Three Dots Menu Button very close to bottom
                                Positioned(
                                  bottom: -8,
                                  right: -8,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.outline
                                            .withValues(alpha: 0.15),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert_rounded,
                                        size: 14,
                                        color: theme.colorScheme.primary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: theme.colorScheme.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'change') {
                                          _showImageSourcePicker(theme);
                                        } else if (value == 'delete') {
                                          setState(() {
                                            _selectedImageDeleted = true;
                                            _selectedImagePath = null;
                                          });
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'change',
                                          child: Row(
                                            children: [
                                              Icon(Icons.image_outlined,
                                                  size: 16,
                                                  color: theme
                                                      .colorScheme.onSurface),
                                              const SizedBox(width: 8),
                                              const Text('Change Image',
                                                  style:
                                                      TextStyle(fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline_rounded,
                                                  size: 16,
                                                  color: Colors.redAccent),
                                              SizedBox(width: 8),
                                              Text('Delete Image',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.redAccent)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 13),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.3)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary),
                            ),
                          ),
                          style: TextStyle(
                              color: theme.colorScheme.onSurface, fontSize: 14),
                          onChanged: (val) {
                            // Rebuild to update live initials preview
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 13),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.3)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary),
                            ),
                          ),
                          style: TextStyle(
                              color: theme.colorScheme.onSurface, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contactController,
                          decoration: InputDecoration(
                            labelText: 'Email / Mobile Number',
                            labelStyle: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 13),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.3)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary),
                            ),
                          ),
                          style: TextStyle(
                              color: theme.colorScheme.onSurface, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _selectedAvatarColorIndex =
                                      _savedAvatarColorIndex;
                                  _selectedImageDeleted = _savedImageDeleted;
                                  _selectedImagePath = _savedImagePath;
                                });
                              },
                              child: Text(
                                'Discard',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _savedName = _nameController.text.trim();
                                  _savedUsername =
                                      _usernameController.text.trim();
                                  _savedContact =
                                      _contactController.text.trim();
                                  _savedAvatarColorIndex =
                                      _selectedAvatarColorIndex;
                                  _savedImageDeleted = _selectedImageDeleted;
                                  _savedImagePath = _selectedImagePath;
                                  _isEditing = false;
                                });
                                _saveProfileData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: _savedImageDeleted
                                ? null
                                : LinearGradient(
                                    colors: _avatarGradients[
                                        _savedAvatarColorIndex],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            color: _savedImageDeleted
                                ? theme.colorScheme.outline.withValues(alpha: 0.15)
                                : null,
                            shape: BoxShape.circle,
                            image: (_savedImagePath != null &&
                                    !_savedImageDeleted)
                                ? DecorationImage(
                                    image: _getProfileImage(_savedImagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              if (!_savedImageDeleted)
                                BoxShadow(
                                  color:
                                      _avatarGradients[_savedAvatarColorIndex]
                                              [0]
                                          .withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                            ],
                          ),
                          child:
                              (_savedImagePath != null && !_savedImageDeleted)
                                  ? null
                                  : Center(
                                      child: Text(
                                        _getInitials(_savedName),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _savedImageDeleted
                                              ? theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.4)
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _savedUsername,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _savedContact,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              color: theme.colorScheme.primary, size: 20),
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                              _nameController.text = _savedName;
                              _usernameController.text = _savedUsername;
                              _contactController.text = _savedContact;
                              _selectedAvatarColorIndex =
                                  _savedAvatarColorIndex;
                              _selectedImageDeleted = _savedImageDeleted;
                            });
                          },
                          tooltip: 'Edit Profile',
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 16),

            // Theme Mode Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.isDarkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Mode',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.isDarkMode ? 'Dark Mode' : 'Light Mode',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: widget.isDarkMode,
                    activeThumbColor: theme.colorScheme.secondary,
                    onChanged: (val) => widget.onThemeChanged(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Engine Diagnostics Card
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DiagnosticsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.developer_board_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Engine Diagnostics',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'View llama.cpp metrics, t/s, nCtx & debug state',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Resource Gauges
            _buildGaugeCard(
              title: kIsWeb
                  ? 'Storage Capacity (Web Sandbox)'
                  : 'Storage Capacity',
              subtitle: kIsWeb
                  ? '${totalStorageUsed.toStringAsFixed(1)} GB Used of ${_totalStorageGB.toStringAsFixed(0)} GB Browser Quota'
                  : '${totalStorageUsed.toStringAsFixed(1)} GB Used of ${_totalStorageGB.toStringAsFixed(0)} GB Available',
              percent: storagePercent,
              percentageLabel: '${(storagePercent * 100).round()}% USED',
              icon: Icons.storage_rounded,
              theme: theme,
              helperText: kIsWeb
                  ? 'Web browsers restrict origin storage sandbox to a fraction of disk space (~10-20 GB). Run as a native app to access your full 256 GB.'
                  : null,
            ),
            const SizedBox(height: 12),
            _buildGaugeCard(
              title: 'Neural Engine RAM',
              subtitle:
                  '${finalRamUsed.toStringAsFixed(1)} GB Active of ${_totalRamGB.toStringAsFixed(0)} GB Physical Memory',
              percent: ramPercent,
              percentageLabel: '${(ramPercent * 100).round()}% ACTIVE',
              icon: Icons.memory_rounded,
              theme: theme,
            ),
            const SizedBox(height: 30),

            // Installed Intelligence header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Installed Models',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface),
                ),
              ],
            ),

            // Dynamic user-installed models
            ...widget.installedModels.map((m) => Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: _buildInstalledModelRow(
                    name: m.name,
                    quantization: m.quantization,
                    description: m.description,
                    meta: '${m.size} • Verified',
                    onDelete: () =>
                        _showDeleteModelConfirmation(m.id, m.name, theme),
                    theme: theme,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeCard({
    required String title,
    required String subtitle,
    required double percent,
    required String percentageLabel,
    required IconData icon,
    required ThemeData theme,
    String? helperText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: theme.colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                percentageLabel,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 5,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.1),
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 10),
            Text(
              helperText,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: theme.colorScheme.primary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstalledModelRow({
    required String name,
    required String quantization,
    required String description,
    required String meta,
    VoidCallback? onDelete,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_awesome_rounded,
                color: theme.colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                        border: Border.all(
                            color:
                                theme.colorScheme.secondary.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        quantization,
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary),
                      ),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: onDelete,
                        child: Icon(Icons.delete_outline_rounded,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            size: 18),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  meta,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
