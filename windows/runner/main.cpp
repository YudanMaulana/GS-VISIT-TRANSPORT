#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <string>
#include <vector>

#include "flutter_window.h"
#include "utils.h"

// Force high-performance dedicated GPU (NVIDIA RTX / AMD High Performance)
// Detected at binary load time by NVIDIA Optimus and AMD Enduro driver switchers
// before Direct3D / ANGLE initializes, preventing blank white screen / device loss.
extern "C" {
  __declspec(dllexport) DWORD NvOptimusEnablement = 0x00000001;
  __declspec(dllexport) int AmdPowerXpressRequestHighPerformance = 1;
}

// Ensure Windows OS Graphics Settings (DWM / DXGI) registers this executable for High Performance GPU
static void EnsureHighPerformanceGpuPreference() {
  wchar_t exePath[MAX_PATH];
  if (GetModuleFileNameW(nullptr, exePath, MAX_PATH) == 0) {
    return;
  }
  HKEY hKey;
  const wchar_t* subKey = L"Software\\Microsoft\\DirectX\\UserGpuPreferences";
  if (RegCreateKeyExW(HKEY_CURRENT_USER, subKey, 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_SET_VALUE | KEY_QUERY_VALUE,
                      nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
    wchar_t existingValue[64] = {0};
    DWORD dataSize = sizeof(existingValue);
    DWORD type = 0;
    LSTATUS status = RegQueryValueExW(hKey, exePath, nullptr, &type,
                                      reinterpret_cast<LPBYTE>(existingValue), &dataSize);
    const wchar_t* preferredSetting = L"GpuPreference=2;";
    if (status != ERROR_SUCCESS || wcscmp(existingValue, preferredSetting) != 0) {
      RegSetValueExW(hKey, exePath, 0, REG_SZ,
                     reinterpret_cast<const BYTE*>(preferredSetting),
                     static_cast<DWORD>((wcslen(preferredSetting) + 1) * sizeof(wchar_t)));
    }
    RegCloseKey(hKey);
  }
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Ensure Windows graphics registry assigns High Performance dedicated GPU
  EnsureHighPerformanceGpuPreference();

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  // Explicitly tell Flutter ANGLE engine to select High Performance discrete GPU (NVIDIA RTX)
  project.set_gpu_preference(flutter::GpuPreference::HighPerformancePreference);

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Garudashield Transporter", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
