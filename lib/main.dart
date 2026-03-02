import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roblox_monitor/services/app_state.dart';
import 'package:roblox_monitor/services/database_helper.dart';
import 'package:roblox_monitor/services/system_tray_manager.dart';
import 'package:roblox_monitor/ui/config_dialog.dart';
import 'package:roblox_monitor/ui/home_page.dart';
import 'package:roblox_monitor/ui/overlay_widget.dart';
import 'package:roblox_monitor/ui/tray_popup.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isWindows) {
      Directory.current = p.dirname(Platform.resolvedExecutable);
    }
    await windowManager.ensureInitialized();

    final appState = AppState();
    
    // Install LaunchAgent on macOS for auto-start
    if (Platform.isMacOS) {
      _installLaunchAgentIfNeeded();
    }
    
    // Initialize tray asynchronously
    Future.delayed(const Duration(milliseconds: 100), () {
      SystemTrayManager(appState).init().catchError((e) => debugPrint("Tray Error: $e"));
    });

    runApp(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text("Startup Error: $e")))));
  }
}

/// Installs a macOS LaunchAgent plist so MoniGuard starts automatically at login
/// and is restarted if it crashes (KeepAlive = true).
void _installLaunchAgentIfNeeded() {
  try {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) return;

    final agentsDir = Directory('$home/Library/LaunchAgents');
    if (!agentsDir.existsSync()) agentsDir.createSync(recursive: true);

    final plistPath = '$home/Library/LaunchAgents/com.chinhpm.moniguard.plist';
    final executablePath = Platform.resolvedExecutable;
    // MoniGuard.app executable is inside the .app bundle
    // e.g. /Applications/MoniGuard.app/Contents/MacOS/MoniGuard
    // We need the .app path for launch
    String appPath = executablePath;
    final appBundleIndex = executablePath.indexOf('.app/');
    if (appBundleIndex != -1) {
      appPath = executablePath.substring(0, appBundleIndex + 4); // up to and including .app
    }

    final plistContent = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.chinhpm.moniguard</string>
    <key>ProgramArguments</key>
    <array>
        <string>open</string>
        <string>-a</string>
        <string>$appPath</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StartInterval</key>
    <integer>0</integer>
</dict>
</plist>''';

    final plistFile = File(plistPath);
    // Only write if content has changed (avoid unnecessary writes)
    if (!plistFile.existsSync() || plistFile.readAsStringSync() != plistContent) {
      plistFile.writeAsStringSync(plistContent);
      // Load/reload the agent
      Process.run('launchctl', ['unload', plistPath]);
      Process.run('launchctl', ['load', '-w', plistPath]);
      DatabaseHelper.logSystemEvent("LaunchAgent installed: $plistPath");
    }
  } catch (e) {
    DatabaseHelper.logSystemEvent("LaunchAgent install error: $e", level: 'WARNING');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoniGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      home: const MainWrapper(),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with WindowListener {
  @override
  void initState() {
    windowManager.addListener(this);
    _initWindow();
    super.initState();
  }

  Future<void> _initWindow() async {
    // Use a size that can fit both tray popup and config UI
    // This avoids having to resize which causes native crashes
    await windowManager.setSize(const Size(600, 700));
    await windowManager.setPreventClose(true);
    await windowManager.setResizable(true);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.center();
    // Always show on startup so user can interact
    await windowManager.show();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // On macOS: Quit from Dock menu just hides to tray. 
    // The LaunchAgent will restart if the process is killed.
    await windowManager.hide();
  }

  @override
  void onWindowBlur() async {
    // Disabled auto-hide since system tray is not working
    // final appState = context.read<AppState>();
    // if (appState.isTransitioning) return;
    // if (appState.windowMode == WindowMode.tray) {
    //   await windowManager.hide();
    // }
  }

  @override
  Widget build(BuildContext context) {
    final showOverlay = context.select<AppState, bool>((s) => s.showOverlay);
    final windowMode = context.select<AppState, WindowMode>((s) => s.windowMode);
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            if (windowMode == WindowMode.tray) ...[
              const TrayPopup(),
            ] else ...[
              const ConfigDialog(),
            ],
            if (showOverlay) const FullScreenOverlay(),
            const WarningBanner(),
          ],
        ),
      ),
    );
  }
}

class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final showWarning = context.select<AppState, bool>((s) => s.showWarning);
    final message = context.select<AppState, String>((s) => s.warningMessage);

    if (!showWarning) return const SizedBox.shrink();

    // If warning is shown, ensure window is visible
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       await windowManager.show();
       await windowManager.setAlwaysOnTop(true);
    });

    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(12),
        color: Colors.redAccent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
