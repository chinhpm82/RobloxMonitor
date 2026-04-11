import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:roblox_monitor/services/database_helper.dart';
import 'package:roblox_monitor/services/native_service.dart';
import 'package:roblox_monitor/services/telegram_service.dart';
import 'package:roblox_monitor/utils/constants.dart';
import 'package:roblox_monitor/utils/translations.dart';
import 'package:window_manager/window_manager.dart';

enum WindowMode { tray, settings }

class AppState extends ChangeNotifier {
  bool _isMonitorEnabled = true;
  
  Timer? _timer;
  bool _isChecking = false;
  bool _isTransitioning = false;
  WindowMode _windowMode = WindowMode.tray;

  // Unified schedule: key: "day_hour" (e.g. "1_18" for Mon 18:00), value: true/false
  Map<String, bool> _scheduleCapture = {};

  bool _isScreenshotMode = kIsWeb ? false : Platform.isMacOS;
  int _macOSCaptureCounter = 0;
  int _screenshotIntervalSeconds = 300; // Default 5 minutes

  bool get isScreenshotMode => _isScreenshotMode;
  bool get isTransitioning => _isTransitioning;
  bool get isMonitorEnabled => _isMonitorEnabled;
  WindowMode get windowMode => _windowMode;

  Map<String, bool> get scheduleCapture => _scheduleCapture;

  // Telegram Config
  String _telegramBotToken = '';
  String _telegramChatId = '';
  String _telegramMessageTemplate = "Báo cáo định kỳ";

  // Localization
  String _language = 'vi';
  String get currentLanguage => _language;
  DateTime? _lastTelegramSentTime;

  String get telegramBotToken => _telegramBotToken;
  String get telegramChatId => _telegramChatId;
  int get screenshotIntervalMinutes => _screenshotIntervalSeconds ~/ 60;
  String get telegramMessageTemplate => _telegramMessageTemplate;

  AppState() {
    DatabaseHelper.logSystemEvent("MoniGuard Started");
    _loadSettings();
    _startMonitor();
  }

  Future<void> refreshState() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await DatabaseHelper.getSetting('monitor_enabled');
    if (enabled != null) {
      _isMonitorEnabled = enabled == 'true';
    }
    
    // Migration: Load from schedule_roblox as the new unified schedule
    final sch = await DatabaseHelper.getSetting('schedule_capture') ?? await DatabaseHelper.getSetting('schedule_roblox');
    if (sch != null) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(sch));
        _scheduleCapture = decoded.map((k, v) => MapEntry(k, v as bool));
      } catch (_) {}
    }

    _telegramBotToken = await DatabaseHelper.getSetting('telegram_bot_token') ?? '';
    _telegramChatId = await DatabaseHelper.getSetting('telegram_chat_id') ?? '';

    // Load language
    _language = await DatabaseHelper.getSetting('language') ?? 'vi';

    // Load Telegram extra configs
    _telegramMessageTemplate = await DatabaseHelper.getSetting('telegram_template') ?? "Báo cáo định kỳ";

    _isScreenshotMode = (await DatabaseHelper.getSetting('mode_screenshot') ?? 'true') == 'true';
    _screenshotIntervalSeconds = int.tryParse(await DatabaseHelper.getSetting('screenshot_interval') ?? '') ?? 300;

    notifyListeners();
  }

  Future<void> saveSettings({
    required String telegramTemplate,
    required int screenshotIntervalMinutes,
  }) async {
    _telegramMessageTemplate = telegramTemplate;
    _screenshotIntervalSeconds = screenshotIntervalMinutes * 60;

    await DatabaseHelper.saveSetting('telegram_template', telegramTemplate);
    await DatabaseHelper.saveSetting('screenshot_interval', _screenshotIntervalSeconds.toString());
    
    notifyListeners();
  }

  Future<void> saveSchedules(Map<String, bool> captureSchedule) async {
    _scheduleCapture = captureSchedule;
    await DatabaseHelper.saveSetting('schedule_capture', jsonEncode(captureSchedule));
    notifyListeners();
  }

  Future<void> saveTelegramConfig(String token, String chatId) async {
    _telegramBotToken = token;
    _telegramChatId = chatId;
    await DatabaseHelper.saveSetting('telegram_bot_token', token);
    await DatabaseHelper.saveSetting('telegram_chat_id', chatId);
    notifyListeners();
  }

  Future<void> toggleScreenshotMode() async {
    _isScreenshotMode = !_isScreenshotMode;
    await DatabaseHelper.saveSetting('mode_screenshot', _isScreenshotMode.toString());
    notifyListeners();
  }

  Future<bool> toggleMonitor(String? password) async {
    if (_isMonitorEnabled) {
      if (password == null || !(await verifyPassword(password))) {
        return false;
      }
    }
    
    _isMonitorEnabled = !_isMonitorEnabled;
    DatabaseHelper.saveSetting('monitor_enabled', _isMonitorEnabled.toString());
    notifyListeners();
    return true;
  }

  void _startMonitor() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkStatus();
    });
  }

  Future<void> setLanguage(String lang) async {
    if (_language != lang) {
      _language = lang;
      await DatabaseHelper.saveSetting('language', lang);
      notifyListeners();
    }
  }

  String t(String key, {List<String>? args}) {
    String? val = AppTranslations.languages[_language]?[key];
    val ??= AppTranslations.languages['vi']?[key] ?? key;
    if (args != null && args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        val = val!.replaceAll('{$i}', args[i]);
      }
    }
    return val!;
  }

  Future<String> get _password async => await DatabaseHelper.getSetting('app_password') ?? Constants.defaultPassword;

  Future<bool> verifyPassword(String input) async {
    return input == await _password;
  }

  Future<void> changePassword(String current, String next) async {
    if (current == await _password) {
      await DatabaseHelper.saveSetting('app_password', next);
    }
  }

  void _checkStatus() {
    if (_isChecking || !_isMonitorEnabled) return;
    _isChecking = true;
    
    try {
      _performCheck();
    } catch (e, stack) {
      DatabaseHelper.logSystemEvent("Monitoring Error: $e", level: 'ERROR');
    } finally {
      _isChecking = false;
    }
  }

  void _performCheck() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final hour = now.hour;
    final key = "${weekday}_${hour}";

    bool isScheduled = _scheduleCapture[key] ?? false;

    // Screenshot logic (adjustable interval)
    if (_isScreenshotMode && isScheduled) {
      _macOSCaptureCounter++;
      if (_macOSCaptureCounter >= _screenshotIntervalSeconds) {
        _macOSCaptureCounter = 0;
        _performScreenshotAction();
      }
    } else {
      _macOSCaptureCounter = 0;
    }
  }

  Future<void> _performScreenshotAction() async {
     // Check for screen lock
    if (NativeService.isScreenLocked()) {
      debugPrint("Screen is locked, skipping screenshot");
      DatabaseHelper.logSystemEvent("Màn hình đang khóa - Bỏ qua chụp ảnh");
      await _checkAndSendTelegramAlert(t('msg_screen_locked'), isLocked: true);
    } else {
      await _checkAndSendTelegramAlert(t('msg_scheduled_monitoring'));
    }
  }

  Future<void> _checkAndSendTelegramAlert(String reason, {bool isLocked = false}) async {
    if (_telegramBotToken.isEmpty || _telegramChatId.isEmpty) {
        return;
    }
    
    final now = DateTime.now();
    _lastTelegramSentTime = now;
    
    final message = _telegramMessageTemplate
        .replaceAll('{reason}', reason)
        .replaceAll('{time}', "${now.hour}:${now.minute.toString().padLeft(2, '0')}");

    try {
      if (isLocked) {
        await TelegramService.sendMessage(
          botToken: _telegramBotToken,
          chatId: _telegramChatId,
          message: message,
        );
      } else {
        await TelegramService.captureAndSend(
          botToken: _telegramBotToken,
          chatId: _telegramChatId,
          caption: message,
        );
      }
    } catch (e) {
      DatabaseHelper.logSystemEvent("Telegram Error: $e", level: 'ERROR');
    }
  }

  Future<void> setWindowMode(WindowMode mode) async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    
    try {
      _windowMode = mode;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 50));
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      debugPrint("Window Mode Error: $e");
    } finally {
      _isTransitioning = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
