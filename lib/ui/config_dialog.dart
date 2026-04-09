import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roblox_monitor/services/app_state.dart';
import 'package:roblox_monitor/services/database_helper.dart';
import 'package:roblox_monitor/ui/schedule_grid.dart';
import 'package:roblox_monitor/services/telegram_service.dart'; // Add import

class ConfigDialog extends StatefulWidget {
  const ConfigDialog({super.key});

  @override
  State<ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> {
  bool _isAuthenticated = false;
  final TextEditingController _authPassController = TextEditingController();
  
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  
  final TextEditingController _botTokenController = TextEditingController();
  final TextEditingController _chatIdController = TextEditingController();
  final TextEditingController _telegramFrequencyController = TextEditingController();
  final TextEditingController _telegramTemplateController = TextEditingController();
  final TextEditingController _screenshotIntervalController = TextEditingController();

  late Map<String, bool> _tempSchCapture;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tempSchCapture = {};
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final appState = context.read<AppState>();
      _tempSchCapture = Map<String, bool>.from(appState.scheduleCapture);
    }
  }

  Future<void> _loadSettings() async {
    final appState = context.read<AppState>();
    _botTokenController.text = appState.telegramBotToken;
    _chatIdController.text = appState.telegramChatId;
    _telegramFrequencyController.text = appState.telegramDebounceMinutes.toString();
    _telegramTemplateController.text = appState.telegramMessageTemplate;
    _screenshotIntervalController.text = appState.screenshotIntervalMinutes.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.read<AppState>().t('auth_required'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: _authPassController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(border: const OutlineInputBorder(), labelText: context.read<AppState>().t('admin_password')),
                onSubmitted: (_) => _authenticate(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   TextButton(
                    onPressed: () => context.read<AppState>().setWindowMode(WindowMode.tray),
                    child: Text(context.read<AppState>().t('cancel')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: Text(context.read<AppState>().t('confirm')),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Container(
        color: const Color(0xFF121212),
        child: Column(
          children: [
            AppBar(
              title: const Text('Cấu hình MoniGuard'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.read<AppState>().setWindowMode(WindowMode.tray),
              ),
            ),
            TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: context.watch<AppState>().t('tab_schedule')),
                Tab(text: context.watch<AppState>().t('tab_stats')),
                Tab(text: context.watch<AppState>().t('tab_system_logs')), 
                Tab(text: context.watch<AppState>().t('tab_notification')),
                Tab(text: context.watch<AppState>().t('tab_account')),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                   _buildScheduleTab(),
                   _buildStatsTab(),
                   _buildSystemLogsTab(),
                   _buildNotificationTab(),
                   _buildAccountTab(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   TextButton(
                    onPressed: () => context.read<AppState>().setWindowMode(WindowMode.tray),
                    child: Text(context.watch<AppState>().t('cancel')),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(context.watch<AppState>().t('save_all')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ScheduleGrid(
            title: context.watch<AppState>().t('schedule_capture'),
            initialSchedule: _tempSchCapture,
            onChanged: (val) => _tempSchCapture = val,
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.watch<AppState>().t('account_note'),
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemLogsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.getSystemLogs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final logs = snapshot.data!;
        if (logs.isEmpty) return Center(child: Text(context.watch<AppState>().t('no_system_logs')));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final timestamp = DateTime.parse(log['timestamp']);
            final level = log['level'] as String;
            final message = log['message'] as String;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                   Text(
                    "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}",
                    style: const TextStyle(fontSize: 10, color: Colors.white54, fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 2, height: 10, color: level == 'ERROR' ? Colors.redAccent : (level == 'WARNING' ? Colors.orangeAccent : Colors.blueAccent)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 11,
                        color: level == 'ERROR' ? Colors.redAccent : Colors.white.withOpacity(0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsTab() {
     // For now, reuse logs but focus on screenshots sent
     return _buildSystemLogsTab(); 
  }

  Widget _buildNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.watch<AppState>().t('tele_config_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            context.watch<AppState>().t('tele_desc'),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _botTokenController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: context.watch<AppState>().t('bot_token'),
              hintText: '123456:ABC-DEF...',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _chatIdController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: context.watch<AppState>().t('chat_id'),
              hintText: '123456789',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _telegramFrequencyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: context.watch<AppState>().t('debounce'),
                    suffixText: 'm',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _telegramTemplateController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: context.watch<AppState>().t('msg_template'),
                    hintText: context.watch<AppState>().t('template_hint'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _screenshotIntervalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: context.watch<AppState>().t('screenshot_interval'),
                    suffixText: 'm',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 8),
          Text(context.watch<AppState>().t('template_note'), style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.send),
            label: Text(context.watch<AppState>().t('send_test')),
            onPressed: () async {
               final token = _botTokenController.text;
               final chat = _chatIdController.text;
               if (token.isEmpty || chat.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Token và Chat ID')));
                 return;
               }
               
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AppState>().t('test_sending')), duration: const Duration(seconds: 1)));
               
               bool success = await TelegramService.captureAndSend(
                 botToken: token,
                 chatId: chat,
                 caption: context.read<AppState>().t('test_msg_content'),
               );
               
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AppState>().t('test_success')), backgroundColor: Colors.green));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AppState>().t('test_fail')), backgroundColor: Colors.red));
                  }
                }
            },
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          _buildTelegramGuide(),
        ],
      ),
    );
  }

  Widget _buildTelegramGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(context.watch<AppState>().t('tele_guide_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          _guideStep('1', context.watch<AppState>().t('guide_step_1')),
          _guideStep('2', context.watch<AppState>().t('guide_step_2')),
          _guideStep('3', context.watch<AppState>().t('guide_step_3')),
          _guideStep('4', context.watch<AppState>().t('guide_step_4')),
        ],
      ),
    );
  }

  Widget _guideStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           CircleAvatar(radius: 9, backgroundColor: Colors.blueAccent, child: Text(num, style: const TextStyle(fontSize: 11, color: Colors.white))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.white70))),
        ],
      ),
    );
  }

  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.read<AppState>().t('change_pass_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _currentPassController,
            obscureText: true,
            decoration: InputDecoration(border: const OutlineInputBorder(), labelText: context.read<AppState>().t('current_pass')),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newPassController,
            obscureText: true,
            decoration: InputDecoration(border: const OutlineInputBorder(), labelText: context.read<AppState>().t('new_pass')),
            onSubmitted: (_) => _saveSettings(),
          ),
          const SizedBox(height: 32),
          Text(context.read<AppState>().t('language'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: context.watch<AppState>().currentLanguage,
            dropdownColor: const Color(0xFF1E1E1E),
            items: const [
              DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (val) {
              if (val != null) {
                context.read<AppState>().setLanguage(val);
              }
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticate() async {
    final appState = context.read<AppState>();
    if (await appState.verifyPassword(_authPassController.text)) {
      setState(() => _isAuthenticated = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<AppState>().t('password_incorrect'))),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    final appState = context.read<AppState>();
    
    // Save Telegram config
    await appState.saveTelegramConfig(_botTokenController.text, _chatIdController.text);

    // Save common settings
    await appState.saveSettings(
      telegramDebounce: int.tryParse(_telegramFrequencyController.text) ?? 5,
      telegramTemplate: _telegramTemplateController.text,
      screenshotIntervalMinutes: int.tryParse(_screenshotIntervalController.text) ?? 5,
    );

    // Save unified schedule
    await appState.saveSchedules(_tempSchCapture);
    
    // Handle password change if filled
    if (_currentPassController.text.isNotEmpty && _newPassController.text.isNotEmpty) {
      final correct = await appState.verifyPassword(_currentPassController.text);
      if (correct) {
        await appState.changePassword(_currentPassController.text, _newPassController.text);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(context.read<AppState>().t('current_pass_incorrect'))),
        );
        return;
      }
    }

    if (mounted) {
      await appState.refreshState();
      await appState.setWindowMode(WindowMode.tray);
    }
  }
}
