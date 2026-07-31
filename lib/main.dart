import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/models_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/model_app_state.dart';

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
  int _currentTabIndex = 0;
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
      setState(() {
        _currentTabIndex = 2; // Direct jump to downloads tab
      });
      _pageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await state.startDownload(modelId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleCancelDownload() {
    Provider.of<ModelAppState>(context, listen: false).cancelDownload();
  }

  void _handleCompleteDownload() {
    // The state manager handles download completion transitions internally.
  }

  void _handleDeleteModel(String modelId) {
    Provider.of<ModelAppState>(context, listen: false).deleteModel(modelId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = Provider.of<ModelAppState>(context);

    final List<Widget> screens = [
      ChatScreen(
        installedModels: state.installedModels,
        onSendMessage:
            (txt, modelId) {}, // Handled locally via Provider within ChatScreen
        isGenerating: false, // Handled locally via Provider within ChatScreen
        isSidebarOpen: _isSidebarOpen,
        onToggleSidebar: (isOpen) {
          setState(() {
            _isSidebarOpen = isOpen;
          });
        },
        selectedModelId: state.selectedModelId ?? '',
      ),
      ModelsScreen(
        models: state.models,
        onStartDownload: _handleStartDownload,
      ),
      DownloadsScreen(
        downloadingModel: state.downloadingModel,
        onCancelDownload: _handleCancelDownload,
        onCompleteDownload: _handleCompleteDownload,
      ),
      SettingsScreen(
        installedModels: state.installedModels,
        onDeleteModel: _handleDeleteModel,
        isDarkMode: theme.brightness == Brightness.dark,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            border:
                Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'assets/images/Icon.png',
              width: 18,
              height: 18,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.psychology,
                  color: theme.colorScheme.primary,
                  size: 20,
                );
              },
            ),
          ),
        ),
        title: Text(
          'LocalMind',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child:
                Icon(Icons.memory, color: theme.colorScheme.primary, size: 20),
          )
        ],
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.colorScheme.outline.withOpacity(0.15),
            height: 1,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.15),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) => setState(() {
            _currentTabIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            if (index != 0) {
              _isSidebarOpen = false;
            }
          }),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              activeIcon:
                  Icon(Icons.chat_bubble, color: theme.colorScheme.primary),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.layers_outlined),
              activeIcon: Icon(Icons.layers, color: theme.colorScheme.primary),
              label: 'Models',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.download_outlined),
                  if (state.downloadingModel != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              activeIcon:
                  Icon(Icons.download, color: theme.colorScheme.primary),
              label: 'Downloads',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_applications),
              activeIcon:
                  Icon(Icons.settings, color: theme.colorScheme.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

export_main_example() {}
