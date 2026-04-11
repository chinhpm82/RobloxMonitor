import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:roblox_monitor/services/database_helper.dart';
import 'package:win32/win32.dart' as win32;

class NativeService {
  // Keeping this for potential future use or debugging, but it won't be used in the main loop anymore.
  static bool isProcessRunning(String processName) {
    if (Platform.isWindows) {
      return _isWindowsProcessRunning(processName);
    } else if (Platform.isMacOS) {
      return _isMacOSProcessRunning(processName);
    }
    return false;
  }

  // --- macOS Implementations ---

  static bool _isMacOSProcessRunning(String processName) {
    try {
      final name = processName.replaceAll('.exe', '');
      final result = Process.runSync('pgrep', ['-ix', name]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint("MacOS Process Check Error: $e");
      return false;
    }
  }

  // --- Windows Implementations ---

  static bool _isWindowsProcessRunning(String processName) {
    final processIds = calloc<win32.DWORD>(1024);
    final bytesReturned = calloc<win32.DWORD>();

    try {
      if (win32.EnumProcesses(processIds, 1024 * sizeOf<win32.DWORD>(), bytesReturned) == 0) {
        return false;
      }

      final count = bytesReturned.value ~/ sizeOf<win32.DWORD>();
      for (var i = 0; i < count; i++) {
        final processId = processIds[i];
        if (processId == 0) continue;

        final hProcess = win32.OpenProcess(win32.PROCESS_QUERY_INFORMATION | win32.PROCESS_VM_READ, win32.FALSE, processId);
        if (hProcess != 0) {
          final hModule = calloc<win32.HMODULE>();
          final moduleBytesReturned = calloc<win32.DWORD>();
          try {
            if (win32.EnumProcessModules(hProcess, hModule, sizeOf<win32.HMODULE>(), moduleBytesReturned) != 0) {
              final moduleName = calloc<Uint16>(win32.MAX_PATH).cast<Utf16>();
              win32.GetModuleBaseName(hProcess, hModule.value, moduleName.cast(), win32.MAX_PATH);
              final name = moduleName.toDartString();
              calloc.free(moduleName);
              if (name.toLowerCase() == processName.toLowerCase()) {
                return true;
              }
            }
          } finally {
            calloc.free(hModule);
            calloc.free(moduleBytesReturned);
            win32.CloseHandle(hProcess);
          }
        }
      }
    } finally {
      calloc.free(processIds);
      calloc.free(bytesReturned);
    }
    return false;
  }

  static bool isScreenLocked() {
    if (Platform.isMacOS) {
      try {
        final result = Process.runSync('lsappinfo', ['front']);
        return result.stdout.toString().contains('loginwindow');
      } catch (e) {
        debugPrint("MacOS Screen Lock Check Error: $e");
        return false;
      }
    }
    return false;
  }
}
