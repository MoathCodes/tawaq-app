#include "single_instance.h"

SingleInstance::SingleInstance() {
#ifndef _DEBUG
  // Open the event before publishing ownership via the mutex. Otherwise a
  // simultaneous duplicate could signal and close it before we opened it.
  activation_event_ =
      CreateEventW(nullptr, FALSE, FALSE, L"Local\\me.moathdev.tawaq.activate");
  if (activation_event_ == nullptr) {
    failed_ = true;
    return;
  }
  mutex_ = CreateMutexW(nullptr, FALSE, L"Local\\me.moathdev.tawaq.instance");
  const DWORD mutex_error = GetLastError();
  if (mutex_ == nullptr) {
    failed_ = true;
    return;
  }
  is_primary_ = mutex_error != ERROR_ALREADY_EXISTS;
  if (!is_primary_) {
    HWND window = FindWindowW(kTawaqWindowClass, nullptr);
    if (window != nullptr) {
      DWORD process_id = 0;
      GetWindowThreadProcessId(window, &process_id);
      AllowSetForegroundWindow(process_id);
    }
    // Wakes the primary's message loop; no duplicate Flutter engine or window.
    if (!SetEvent(activation_event_)) failed_ = true;
  }
#endif
}

SingleInstance::~SingleInstance() {
  if (activation_event_ != nullptr) CloseHandle(activation_event_);
  if (mutex_ != nullptr) CloseHandle(mutex_);
}
