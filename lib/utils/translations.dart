class AppTranslations {
  static const Map<String, Map<String, String>> languages = {
    'vi': {
      // General
      'app_name': 'MoniGuard',
      'cancel': 'Hủy',
      'confirm': 'Xác nhận',
      'save_all': 'Lưu tất cả',
      'add': 'Thêm',
      'warning': 'Cảnh báo',
      'error': 'Lỗi',
      'success': 'Thành công',
      'password': 'Mật khẩu',
      'enter_password': 'Nhập mật khẩu',
      'admin_password': 'Mật khẩu quản trị',
      'auth_required': 'Xác thực quyền truy cập',
      'password_incorrect': 'Mật khẩu không đúng!',
      'old_password_incorrect': 'Mật khẩu cũ không đúng!',
      
      // Home
      'monitor_status_on': 'Đang bật Monitor',
      'monitor_status_off': 'Đang tắt Monitor',
      'monitor_desc': 'Ứng dụng đang theo dõi hoạt động Roblox trên máy tính này.',
      'turn_on': 'Bật Monitor',
      'turn_off': 'Tắt Monitor',
      'usage_log': 'Nhật ký sử dụng',
      'view_all': 'Xem tất cả',
      'no_recent_activity': 'Chưa có hoạt động nào gần đây.',
      'playing': 'Chơi',
      
      // Tray
      'tray_monitor_on': 'Bật [ON]',
      'tray_monitor_off': 'Tắt [OFF]',
      'tray_open_window': 'Mở cửa sổ',
      'tray_status_on': 'MONITOR: ON',
      'tray_status_off': 'MONITOR: OFF',
      'tray_mode_screenshot': 'Chụp ảnh định kỳ',
      'tray_mode_blocking': 'Cảnh báo & Chặn',
      'tray_quit': 'Thoát ứng dụng',

      // Config - Tabs
      'tab_schedule': 'Lịch báo cáo',
      'tab_activity_logs': 'Nhật ký hoạt động',
      'tab_notification': 'Cấu hình Telegram',
      'tab_account': 'Tài khoản & Ngôn ngữ',
      'tab_general': 'Tổng quan',
      
      // Config - Schedule
      'schedule_capture': 'Lịch thực hiện chụp ảnh màn hình (mỗi 5 phút)',
      
      // Config - Monitoring
      'mode_screenshot': 'Kích hoạt tính năng chụp ảnh định kỳ',
      
      // Config - Stats
      'no_stats_data': 'Chưa có hoạt động chụp ảnh nào được ghi nhận.',
      
      // Config - Notification
      'tele_config_title': 'Cấu hình Telegram:',
      'tele_desc': 'Ảnh chụp màn hình sẽ được gửi về Telegram này.',
      'bot_token': 'Bot Token',
      'chat_id': 'Chat ID',
      'msg_template': 'Mẫu tin nhắn',
      'template_hint': 'Ví dụ: {reason} vào lúc {time}',
      'template_note': 'Mặc định: {reason} = "Báo cáo định kỳ", {time} = mốc giờ',
      'send_test': 'Kiểm tra kết nối Telegram',
      'test_sending': 'Đang gửi ảnh test...',
      'test_success': '✅ Gửi thành công! Hãy kiểm tra Telegram.',
      'test_fail': '❌ Thất bại. Hãy kiểm tra Token/ID.',
      'tele_guide_title': 'Hướng dẫn lấy Bot Token và Chat ID',
      'guide_step_1': 'Mở Telegram, tìm @BotFather và gửi /newbot để lấy Token.',
      'guide_step_2': 'Nhấn Start với Bot của bạn vừa tạo.',
      'guide_step_3': 'Gửi tin nhắn cho @userinfobot để lấy Chat ID của bạn.',
      'guide_step_4': 'Dán thông tin vào đây và nhấn Lưu.',
      'test_msg_content': '🔔 Kết nối thành công từ MoniGuard!',

      // Config - Account
      'change_pass_title': 'Bảo mật ứng dụng (Mật khẩu):',
      'current_pass': 'Mật khẩu hiện tại',
      'new_pass': 'Mật khẩu mới',
      'account_note': 'Lưu ý: Các khung giờ ĐƯỢC TÍCH sẽ thực hiện chụp ảnh màn hình và gửi về Telegram mỗi 5 phút.',
      'language': 'Ngôn ngữ hiển thị',
      'no_system_logs': 'Hệ thống hoạt động bình thường.',
      
      // Overlay
      'sites_blocked_title': 'TRANG WEB BỊ CHẶN',
      'sites_blocked_msg': 'Bạn đang truy cập trang web có nội dung bị giới hạn.\nTrình duyệt sẽ bị tắt sau giây lát.',
      
      // Messages
      'msg_roblox_app': 'Chơi Roblox App',
      'msg_restricted_app': 'Ứng dụng giới hạn: {0}',
      'msg_roblox_web': 'Chơi Roblox trên Web ({0})',
      'msg_restricted_web': 'Truy cập nội dung giới hạn trên trình duyệt ({0})',
      'warn_app': 'Ứng dụng \'{0}\' không được phép lúc này!',
      'warn_roblox': 'Không được phép chơi Roblox vào thời gian này!',
      'warn_web_roblox': 'Không được phép xem nội dung Roblox vào lúc này!',
      'warn_web_restricted': 'Không được phép xem nội dung giới hạn vào lúc này!',
      'msg_scheduled_monitoring': 'Báo cáo định kỳ',
      'screenshot_interval': 'Khoảng thời gian chụp (phút)',
      'msg_screen_locked': 'Màn hình đang khóa - Bỏ qua chụp ảnh',
    },
    'en': {
      // General
      'app_name': 'MoniGuard',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save_all': 'Save All',
      'add': 'Add',
      'warning': 'Warning',
      'error': 'Error',
      'success': 'Success',
      'password': 'Password',
      'enter_password': 'Enter Password',
      'admin_password': 'Admin Password',
      'auth_required': 'Access Authentication',
      'password_incorrect': 'Incorrect password!',
      'old_password_incorrect': 'Incorrect old password!',

      // Home
      'monitor_status_on': 'Monitor is ON',
      'monitor_status_off': 'Monitor is OFF',
      'monitor_desc': 'Application is monitoring Roblox activity on this computer.',
      'turn_on': 'Turn ON',
      'turn_off': 'Turn OFF',
      'usage_log': 'Usage Log',
      'view_all': 'View All',
      'no_recent_activity': 'No recent activity.',
      'playing': 'Playing',

      // Tray
      'tray_monitor_on': 'Enable [ON]',
      'tray_monitor_off': 'Disable [OFF]',
      'tray_open_window': 'Open Window',
      'tray_status_on': 'MONITOR: ON',
      'tray_status_off': 'MONITOR: OFF',
      'tray_mode_screenshot': 'Periodic Screenshots',
      'tray_mode_blocking': 'Blocking & Alerts',
      'tray_quit': 'Quit App',

      // Config - Tabs
      'tab_schedule': 'Schedule',
      'tab_activity_logs': 'Activity Logs',
      'tab_notification': 'Telegram Config',
      'tab_account': 'Account & Language',
      'tab_general': 'General',

      // Config - Schedule
      'schedule_roblox': 'Roblox Schedule',
      'schedule_other': 'Web / Other Apps Schedule',

      // Config - Monitoring
      'keywords_title': 'Browser Keywords',
      'keywords_subtitle': 'Detects when window title contains these words (e.g., facebook, tiktok)',
      'keywords_hint': 'Enter keyword...',
      'apps_title': 'Desktop Apps (.exe)',
      'apps_subtitle': 'Process name in Task Manager (e.g., RobloxPlayerBeta.exe)',
      'apps_hint': 'Enter .exe name...',
      'time_config_title': 'Time Configuration (Seconds)',
      'delay_warning': 'Warn after',
      'delay_overlay': 'Overlay after',
      'delay_kill': 'Kill App after',
      'overlay_note': '* Overlay blocks mouse interaction on detection.',
      'mode_screenshot': 'Periodic Screenshots (every 5 mins)',
      'mode_blocking': 'Alerts and Blocking (Warnings/Kill)',

      // Config - Stats
      'no_stats_data': 'No statistics data available.',

      // Config - Notification
      'tele_config_title': 'Telegram Configuration:',
      'tele_desc': 'Receive notifications when violation detected.',
      'bot_token': 'Bot Token',
      'chat_id': 'Chat ID',
      'msg_template': 'Message Template',
      'template_hint': 'Ex: {reason} at {time}',
      'template_note': 'Hint: {reason} = Reason, {time} = Time',
      'send_test': 'Send Test Message (Save first)',
      'test_sending': 'Sending test message...',
      'test_success': '✅ Sent successfully! Check your Telegram.',
      'test_fail': '❌ Send failed. Check Token/ID and network.',
      'tele_guide_title': 'Telegram Setup Guide',
      'guide_step_1': 'Chat with @BotFather on Telegram, send /newbot to create bot & get Token.',
      'guide_step_2': 'Find your new Bot, press Start and send any message to it.',
      'guide_step_3': 'Visit https://api.telegram.org/bot<TOKEN>/getUpdates to get Chat ID.',
      'guide_step_4': 'Enter Token and Chat ID here, press Save then Send Test.',
      'test_msg_content': '🔔 Test Connect from MoniGuard!\nConnection successful.',

      // Config - Account
      'change_pass_title': 'Change Password:',
      'current_pass': 'Current Password',
      'new_pass': 'New Password',
      'account_note': 'Note: Selected slots are ALLOWED. Unchecked slots will be BLOCKED when Monitor is ON.',
      'language': 'Ngôn ngữ (Language)',
      'no_system_logs': 'No system logs available',

      // Overlay
      'sites_blocked_title': 'WEBSITE BLOCKED',
      'sites_blocked_msg': 'You are accessing restricted content.\nThe browser will close shortly.',

      // Messages
      'msg_roblox_app': 'Playing Roblox App',
      'msg_restricted_app': 'Restricted App: {0}',
      'msg_roblox_web': 'Playing Roblox Web ({0})',
      'msg_restricted_web': 'Restricted Browser Content ({0})',
      'warn_app': 'App \'{0}\' is not allowed right now!',
      'warn_roblox': 'Roblox is not allowed at this time!',
      'warn_web_roblox': 'Roblox content is not allowed right now!',
      'warn_web_restricted': 'Restricted content is not allowed right now!',
      'msg_scheduled_monitoring': 'Scheduled Monitoring',
      'screenshot_interval': 'Screenshot Interval (minutes)',
      'msg_screen_locked': 'Screen is locked - Skipping screenshot',
    },
  };
}
