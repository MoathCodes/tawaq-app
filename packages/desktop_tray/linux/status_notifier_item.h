#ifndef DESKTOP_TRAY_STATUS_NOTIFIER_ITEM_H_
#define DESKTOP_TRAY_STATUS_NOTIFIER_ITEM_H_

#include <gio/gio.h>

#include <functional>
#include <string>

// Owns the StatusNotifierItem export. GTK/dbusmenu owns the menu export at
// /StatusNotifierItem/Menu on the same shared session-bus connection.
class StatusNotifierItem {
 public:
  explicit StatusNotifierItem(std::function<void()> activate);
  ~StatusNotifierItem();
  StatusNotifierItem(const StatusNotifierItem&) = delete;
  StatusNotifierItem& operator=(const StatusNotifierItem&) = delete;

  bool Start(const char* icon_path, GError** error);
  void SetTitle(const char* title);
  bool SetIcon(const char* icon_path, GError** error);
  static bool IsAvailable();

 private:
  void Emit(const char* signal, GVariant* parameters = nullptr);
  void RegisterWithWatcher();
  GVariant* Property(const char* name);
  static void MethodCall(GDBusConnection*, const gchar*, const gchar*,
                         const gchar*, const gchar*, GVariant*,
                         GDBusMethodInvocation*, gpointer);
  static GVariant* GetProperty(GDBusConnection*, const gchar*, const gchar*,
                               const gchar*, const gchar*, GError**, gpointer);
  static void WatcherAppeared(GDBusConnection*, const gchar*, const gchar*,
                              gpointer);

  std::function<void()> activate_;
  GDBusConnection* connection_ = nullptr;
  guint registration_ = 0;
  guint watcher_ = 0;
  std::string icon_name_;
  std::string icon_directory_;
  std::string title_ = "Tawaq";
};

#endif
