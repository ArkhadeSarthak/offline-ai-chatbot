import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/models_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/model_app_state.dart';
import 'widgets/app_feedback_service.dart';

void main() {
  runApp(const LocalMindApp());
}

class NoScrollbarBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class LocalMindApp extends StatefulWidget {
  const LocalMindApp({Key? key}) : super(key: key);

  @override
  State<LocalMindApp> createState() => _LocalMindAppState();
}

class _LocalMindAppState extends State<LocalMindApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ModelAppState(),
      child: MaterialApp(
        title: 'LocalMind',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        scrollBehavior: NoScrollbarBehavior(),
        home: SplashScreen(
          themeMode: _themeMode,
          onThemeChanged: _toggleTheme,
        ),
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<bool> onThemeChanged;

  const MainNavigationShell({
    Key? key,
    required this.themeMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  // Chat is index 1 — Default Startup Screen!
  int _currentTabIndex = 1;
  bool _isSidebarOpen = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleStartDownload(String modelId) async {
    final state = Provider.of<ModelAppState>(context, listen: false);
    try {
      // Switch to Models tab (Index 0) so user sees inline download progress card
      _onTabSelected(0);
      await state.startDownload(modelId);
    } catch (e) {
      if (mounted) {
        AppFeedbackService.showToast(
          context,
          'Download failed: $e',
          isError: true,
        );
      }
    }
  }

  void _handleDeleteModel(String modelId) {
    Provider.of<ModelAppState>(context, listen: false).deleteModel(modelId);
  }

  void _onTabSelected(int index) {
    if (_currentTabIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentTabIndex = index;
      if (index != 1) {
        _isSidebarOpen = false;
      }
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<ModelAppState>(context);

    final List<Widget> screens = [
      ModelsScreen(
        models: state.models,
        onStartDownload: _handleStartDownload,
      ),
      ChatScreen(
        installedModels: state.installedModels,
        onSendMessage: (txt, modelId) {},
        isGenerating: false,
        isSidebarOpen: _isSidebarOpen,
        onToggleSidebar: (isOpen) {
          setState(() {
            _isSidebarOpen = isOpen;
          });
        },
        selectedModelId: state.selectedModelId ?? '',
      ),
      SettingsScreen(
        installedModels: state.installedModels,
        onDeleteModel: _handleDeleteModel,
        isDarkMode: isDark,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/Icon.png',
              width: 14,
              height: 14,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.psychology_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                );
              },
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LocalMind',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Text(
                'OFFLINE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
            height: 1,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: screens,
      ),
      bottomNavigationBar: CustomProminentBottomBar(
        currentIndex: _currentTabIndex,
        isDownloading: state.downloadingModel != null,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

/// Modern Custom Floating Bottom Navigation Bar
class CustomProminentBottomBar extends StatelessWidget {
  final int currentIndex;
  final bool isDownloading;
  final ValueChanged<int> onTabSelected;

  const CustomProminentBottomBar({
    Key? key,
    required this.currentIndex,
    required this.isDownloading,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navBg = isDark ? const Color(0xFF0D121F) : const Color(0xFFFFFFFF);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.15);
    final primaryAccent = const Color(0xFF00E5FF);
    final inactiveColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ?? Colors.grey;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // LEFT ITEM: MODELS
            Expanded(
              child: _buildSecondaryNavItem(
                context: context,
                index: 0,
                label: 'Models',
                icon: Icons.layers_outlined,
                activeIcon: Icons.layers_rounded,
                hasBadge: isDownloading,
              ),
            ),

            // CENTER CHAT ITEM (NO CIRCLE, LARGER ICON, DEFAULT INACTIVE COLOR)
            Expanded(
              child: _buildCenterChatItem(
                context: context,
                isSelected: currentIndex == 1,
                primaryAccent: primaryAccent,
                inactiveColor: inactiveColor,
              ),
            ),

            // RIGHT ITEM: SETTINGS
            Expanded(
              child: _buildSecondaryNavItem(
                context: context,
                index: 2,
                label: 'Settings',
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    bool hasBadge = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = currentIndex == index;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ?? Colors.grey;

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(16),
      splashColor: activeColor.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                if (hasBadge)
                  Positioned(
                    right: -3,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E5FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterChatItem({
    required BuildContext context,
    required bool isSelected,
    required Color primaryAccent,
    required Color inactiveColor,
  }) {
    final color = isSelected ? primaryAccent : inactiveColor;

    return InkWell(
      onTap: () => onTabSelected(1),
      borderRadius: BorderRadius.circular(16),
      splashColor: primaryAccent.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
              size: isSelected ? 27 : 25,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              'CHAT',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.8,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
