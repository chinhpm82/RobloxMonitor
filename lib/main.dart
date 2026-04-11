import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roblox_monitor/services/app_state.dart';
import 'package:roblox_monitor/services/database_helper.dart';
import 'package:roblox_monitor/services/system_tray_manager.dart';
import 'package:roblox_monitor/ui/config_dialog.dart';
import 'package:roblox_monitor/ui/home_page.dart';
import 'package:roblox_monitor/ui/tray_popup.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  // Determine if we should start silently (background mode)
  final bool isSilent = args.contains('--silent');
  final bool forceOpen = args.contains('open') || args.isEmpty;

  // 1. Strict single instance check (BEFORE starting Flutter engine)
  try {
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, 54321, timeout: const Duration(milliseconds: 300));
    
    // If we're not starting silently, signal the existing instance to open
    if (forceOpen) {
      socket.write('open');
      await socket.flush();
    }
    
    socket.destroy();
    // Exit immediately to prevent process duplication
    exit(0); 
  } catch (_) {
    // No instance running, continue to start this instance as the primary
  }

  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    if (Platform.isWindows) {
      Directory.current = p.dirname(Platform.resolvedExecutable);
    }
    await windowManager.ensureInitialized();

    final appState = AppState();
    
    // If this primary instance is launched manually (forceOpen), show settings
    if (forceOpen && !isSilent) {
      await appState.setWindowMode(WindowMode.settings);
    }
    
    // Install LaunchAgent on macOS for auto-start
    if (Platform.isMacOS) {
      _installLaunchAgentIfNeeded();
    }
    
    // 2. Start IPC server to listen for commands
    try {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 54321);
      server.listen((client) {
        client.listen((data) async {
          final msg = String.fromCharCodes(data).trim();
          if (msg == 'open') {
            await appState.setWindowMode(WindowMode.settings);
            await windowManager.show();
            await windowManager.focus();
          }
        });
      });
    } catch (e) {
      debugPrint("ServerSocket Bind Error: $e");
    }

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
    
    // Use the absolute path to the binary inside the app bundle
    // e.g. /Applications/MoniGuard.app/Contents/MacOS/MoniGuard
    
    final plistContent = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.chinhpm.moniguard</string>
    <key>ProgramArguments</key>
    <array>
        <string>$executablePath</string>
        <string>--silent</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>''';

    final plistFile = File(plistPath);
    // Only write if content has changed (avoid unnecessary writes)
    if (!plistFile.existsSync() || plistFile.readAsStringSync() != plistContent) {
      plistFile.writeAsStringSync(plistContent);
      // Load/reload the agent
      Process.run('launchctl', ['unload', plistPath]);
      Process.run('launchctl', ['load', '-w', plistPath]);
      DatabaseHelper.logSystemEvent("LaunchAgent installed (silent mode): $plistPath");
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
    // Use a size that can fit config UI
    await windowManager.setSize(const Size(600, 700));
    await windowManager.setPreventClose(true); // Prevent window from closing
    await windowManager.setResizable(true);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.center();
    
    // Show window if in settings mode, otherwise hide (agent mode)
    final appState = context.read<AppState>();
    if (appState.windowMode == WindowMode.settings) {
      await windowManager.show();
      await windowManager.focus();
    } else {
      await windowManager.hide();
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // Hide window instead of quitting
    await windowManager.hide();
  }

  @override
  void onWindowBlur() async {
  }

  @override
  Widget build(BuildContext context) {
    final windowMode = context.select<AppState, WindowMode>((s) => s.windowMode);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: windowMode == WindowMode.tray ? const TrayPopup() : const ConfigDialog(),
    );
  }
}
