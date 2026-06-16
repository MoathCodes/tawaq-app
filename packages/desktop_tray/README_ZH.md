# desktop_tray

轻量级 Flutter 插件，用于在桌面平台（Windows、macOS、Linux）管理**系统托盘**图标和右键菜单。

零第三方 Dart 依赖，仅使用原生平台 API：

| 平台          | 底层实现                                         |
|-------------|----------------------------------------------|
| **Linux**   | libayatana-appindicator（或旧版 libappindicator） |
| **macOS**   | NSStatusBar + NSMenu                         |
| **Windows** | Win32 Shell_NotifyIcon + GDI+（PNG/JPG/BMP/ICO） |

> 🇬🇧 [English](README.md)

## 功能特性

- 🖨️ 从 Flutter 资源路径设置托盘图标（`.png` / `.jpg` / `.bmp` / `.ico`）
- 💬 设置鼠标悬停提示文字（Windows / macOS 支持）
- 📋 构建右键菜单，支持普通项、分隔线、复选框和嵌套子菜单
- 🖱️ 通过监听器混入类接收左键、右键及菜单项点击回调
- 🧩 自动递增的唯一菜单项 ID，无需外部 ID 生成器
- 🔍 `checkAvailable()` 检测 Linux StatusNotifierWatcher 可用性

## 快速开始

### 安装

在应用的 `pubspec.yaml` 中添加路径依赖：

```yaml
dependencies:
  desktop_tray: ^lasted
```

### Linux 系统依赖

Linux 端需要安装 `libayatana-appindicator3`（推荐）或 `libappindicator3`：

```bash
# Ubuntu / Debian
sudo apt install libayatana-appindicator3-dev

# Fedora
sudo dnf install libayatana-appindicator-gtk3-devel

# Arch
sudo pacman -S libayatana-appindicator
```

## 使用方法

### 基本设置

```dart
import 'package:desktop_tray/desktop_tray.dart';

// 1. 设置托盘图标
await desktopTray.setIcon('assets/logo/logo.png');

// 2. 设置悬停提示
await desktopTray.setToolTip('My App');

// 3. 构建右键菜单
final menu = TrayMenu(items: [
  TrayMenuItem(key: 'show', label: '显示窗口'),
  TrayMenuItem.separator(),
  TrayMenuItem(key: 'exit', label: '退出'),
]);
await desktopTray.setContextMenu(menu);
```

### 监听事件

实现 `DesktopTrayListener` 并注册：

```dart
class MyTrayHandler with DesktopTrayListener {
  MyTrayHandler() {
    desktopTray.addListener(this);
  }

  @override
  void onTrayIconMouseDown() {
    // 左键点击托盘图标
  }

  @override
  void onTrayMenuItemClick(TrayMenuItem item) {
    switch (item.key) {
      case 'show':
        // 显示窗口
        break;
      case 'exit':
        // 退出应用
        break;
    }
  }
}
```

### 菜单项类型

```dart
// 普通菜单项
TrayMenuItem(key: 'action', label: '执行操作')

// 分隔线
TrayMenuItem.separator()

// 复选框
TrayMenuItem.checkbox(key: 'mute', label: '静音', checked: true)

// 子菜单
TrayMenuItem.submenu(
  key: 'more',
  label: '更多选项',
  children: [
    TrayMenuItem(key: 'option_a', label: '选项 A'),
    TrayMenuItem(key: 'option_b', label: '选项 B'),
  ],
)
```

### 清理资源

```dart
desktopTray.removeListener(this);
await desktopTray.destroy();
```

## API 参考

### `DesktopTray`（通过全局单例 `desktopTray` 访问）

| 方法                                    | 说明                      |
|---------------------------------------|-------------------------|
| `checkAvailable()`                    | 检测托盘后端是否可用（仅 Linux 有实际意义） |
| `setIcon(String assetPath)`           | 从 Flutter 资源路径设置托盘图标    |
| `setToolTip(String toolTip)`          | 设置悬停提示文字（Linux 上无效）     |
| `setContextMenu(TrayMenu menu)`       | 替换右键上下文菜单               |
| `popUpContextMenu()`                  | 以编程方式弹出上下文菜单（Linux 上无效） |
| `destroy()`                           | 移除托盘图标并释放原生资源           |
| `addListener(DesktopTrayListener)`    | 注册事件监听器                 |
| `removeListener(DesktopTrayListener)` | 移除事件监听器                 |

### `DesktopTrayListener`（混入类）

| 回调                                  | 触发时机       |
|-------------------------------------|------------|
| `onTrayIconMouseDown()`             | 鼠标左键按下托盘图标 |
| `onTrayIconMouseUp()`               | 鼠标左键释放托盘图标 |
| `onTrayIconRightMouseDown()`        | 鼠标右键按下托盘图标 |
| `onTrayIconRightMouseUp()`          | 鼠标右键释放托盘图标 |
| `onTrayMenuItemClick(TrayMenuItem)` | 右键菜单项被点击   |

## 平台说明

- **Linux**：AppIndicator 在左键点击时也会显示上下文菜单。`popUpContextMenu()` 无效。AppIndicator API 不支持 Tooltip。新版 libayatana-appindicator 的弃用警告已被静默抑制。
- **macOS**：图标数据以 base64 编码发送到原生层，用于构造 `NSImage`。
- **Windows**：同时支持 `.ico` / `.png` / `.jpg` / `.bmp` / `.gif`。`.ico` 通过 `LoadImage` 加载，其他格式使用 GDI+ 解码并缩放至系统小图标尺寸。若解码失败会抛出 `PlatformException`（code 为 `ICON_LOAD_FAILED`），而不会再造成“有按钮无图标”的情况。

## 运行示例

[`example/`](example) 目录提供了覆盖全部 API 的完整演示。参见 [example/README.md](example/README.md) 了解图标资源放置和运行命令。

## 许可证

详见 [LICENSE](LICENSE)。
