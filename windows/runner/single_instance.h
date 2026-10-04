#ifndef RUNNER_SINGLE_INSTANCE_H_
#define RUNNER_SINGLE_INSTANCE_H_

#include <windows.h>

// Lifetime ownership is held until the native message loop and window teardown
// finish. The event also retains launches received before a window exists.
class SingleInstance {
 public:
  SingleInstance();
  ~SingleInstance();
  bool is_primary() const { return is_primary_; }
  bool failed() const { return failed_; }
  HANDLE activation_event() const { return activation_event_; }

 private:
  HANDLE mutex_ = nullptr;
  HANDLE activation_event_ = nullptr;
  bool is_primary_ = true;
  bool failed_ = false;
};

constexpr wchar_t kTawaqWindowClass[] = L"TAWAQ_RUNNER_WIN32_WINDOW";

#endif  // RUNNER_SINGLE_INSTANCE_H_
