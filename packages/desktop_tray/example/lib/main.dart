// A complete demonstration of the `desktop_tray` plugin.
//
// Place your own icon files under `example/assets/icons/` before running:
//   - assets/icons/logo.png   (used on macOS / Linux / Windows via GDI+)
//   - assets/icons/logo.ico   (optional, best quality on Windows)
//   - assets/icons/alt.png    (a second icon to demo live switching)
//
// Then run:  flutter run -d windows   (or macos / linux)

import 'dart:io';

import 'package:desktop_tray/desktop_tray.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'desktop_tray demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DemoHome(),
    );
  }
}

// Menu item keys (shared between building the menu and handling clicks).
const String kShow = 'show';
const String kHide = 'hide';
const String kMute = 'mute';
const String kNotifications = 'notifications';
const String kSubA = 'sub_a';
const String kSubB = 'sub_b';
const String kSubNested = 'sub_nested';
const String kDisabled = 'disabled';
const String kAbout = 'about';
const String kExit = 'exit';

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> with DesktopTrayListener {
  // ───────────── Tray state that the UI edits ─────────────
  final List<String> _icons = const [
    'assets/icons/logo.png',
    'assets/icons/logo.ico',
    'assets/icons/alt.png',
  ];
  String _currentIcon = 'assets/icons/logo.png';
  final TextEditingController _tooltipCtrl = TextEditingController(
    text: 'desktop_tray demo',
  );

  bool _muted = false;
  bool _notifications = true;

  bool _trayAlive = false;
  bool _available = true;

  // Scrolling event log (newest on top).
  final List<_LogEntry> _log = [];
  final ScrollController _logCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    desktopTray.addListener(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapTray());
  }

  @override
  void dispose() {
    desktopTray.removeListener(this);
    desktopTray.destroy();
    _tooltipCtrl.dispose();
    _logCtrl.dispose();
    super.dispose();
  }

  // ───────────── Tray lifecycle ─────────────

  Future<void> _bootstrapTray() async {
    final available = await desktopTray.checkAvailable();
    setState(() => _available = available);
    if (!available) {
      _append('tray unavailable (no StatusNotifierWatcher on D-Bus)');
      return;
    }

    await _applyIcon(_currentIcon);
    await desktopTray.setToolTip(_tooltipCtrl.text);
    await _rebuildMenu();
    setState(() => _trayAlive = true);
    _append('tray initialised');
  }

  Future<void> _applyIcon(String path) async {
    try {
      await desktopTray.setIcon(path);
      setState(() => _currentIcon = path);
      _append('setIcon → $path');
    } on PlatformException catch (e) {
      _append('setIcon failed: ${e.code} ${e.message}');
    }
  }

  Future<void> _applyTooltip() async {
    await desktopTray.setToolTip(_tooltipCtrl.text);
    _append('setToolTip → "${_tooltipCtrl.text}"');
  }

  Future<void> _rebuildMenu() async {
    final menu = TrayMenu(
      items: [
        TrayMenuItem(key: kShow, label: 'Show Window'),
        TrayMenuItem(key: kHide, label: 'Hide Window'),
        TrayMenuItem.separator(),
        TrayMenuItem.checkbox(key: kMute, label: 'Mute', checked: _muted),
        TrayMenuItem.checkbox(
          key: kNotifications,
          label: 'Enable Notifications',
          checked: _notifications,
        ),
        TrayMenuItem.separator(),
        TrayMenuItem.submenu(
          key: 'preferences',
          label: 'Preferences',
          children: [
            TrayMenuItem(key: kSubA, label: 'Option A'),
            TrayMenuItem(key: kSubB, label: 'Option B'),
            TrayMenuItem.submenu(
              key: 'nested',
              label: 'More',
              children: [TrayMenuItem(key: kSubNested, label: 'Nested item')],
            ),
          ],
        ),
        TrayMenuItem(key: kDisabled, label: 'Disabled item', disabled: true),
        TrayMenuItem.separator(),
        TrayMenuItem(key: kAbout, label: 'About'),
        TrayMenuItem(key: kExit, label: 'Exit'),
      ],
    );

    await desktopTray.setContextMenu(menu);

    // Demonstrate findByKey: log the id of the mute item.
    final found = menu.findByKey(kMute);
    _append('findByKey("$kMute") → id=${found?.id}');
  }

  Future<void> _popUp() async {
    await desktopTray.popUpContextMenu();
    _append('popUpContextMenu()');
  }

  Future<void> _destroyTray() async {
    await desktopTray.destroy();
    setState(() => _trayAlive = false);
    _append('destroy()');
  }

  Future<void> _recreateTray() => _bootstrapTray();

  // ───────────── DesktopTrayListener ─────────────

  @override
  void onTrayIconMouseDown() => _append('onTrayIconMouseDown');

  @override
  void onTrayIconMouseUp() {
    _append('onTrayIconMouseUp');
    // Common pattern on Windows / macOS: open menu on left-click-up.
    if (!Platform.isLinux) desktopTray.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() => _append('onTrayIconRightMouseDown');

  @override
  void onTrayIconRightMouseUp() {
    _append('onTrayIconRightMouseUp');
    if (Platform.isMacOS) desktopTray.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(TrayMenuItem item) {
    _append('onTrayMenuItemClick key="${item.key}" id=${item.id}');
    switch (item.key) {
      case kShow:
        // In a real app: call window_manager.show()
        break;
      case kHide:
        break;
      case kMute:
        setState(() => _muted = !_muted);
        _rebuildMenu();
      case kNotifications:
        setState(() => _notifications = !_notifications);
        _rebuildMenu();
      case kAbout:
        _append('About: desktop_tray example');
      case kExit:
        desktopTray.destroy().then((_) => exit(0));
    }
  }

  // ───────────── Logging helper ─────────────

  void _append(String msg) {
    setState(() {
      _log.insert(0, _LogEntry(DateTime.now(), msg));
      if (_log.length > 200) _log.removeLast();
    });
  }

  // ───────────── UI ─────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('desktop_tray demo'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Chip(
              label: Text(_trayAlive ? 'tray: alive' : 'tray: dead'),
              backgroundColor:
                  _trayAlive ? Colors.green.shade100 : Colors.red.shade100,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildControlPanel(theme)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildLogPanel(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section(theme, 'Availability'),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () async {
                  final ok = await desktopTray.checkAvailable();
                  setState(() => _available = ok);
                  _append('checkAvailable → $ok');
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('checkAvailable'),
              ),
              const SizedBox(width: 12),
              Text('available: $_available'),
            ],
          ),
          const SizedBox(height: 24),
          _section(theme, 'Icon'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _icons)
                ChoiceChip(
                  label: Text(p.split('/').last),
                  selected: _currentIcon == p,
                  onSelected: (_) => _applyIcon(p),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _section(theme, 'Tooltip'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tooltipCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tooltip text',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _applyTooltip,
                child: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _section(theme, 'Menu state (checkbox demo)'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Muted'),
            value: _muted,
            onChanged: (v) {
              setState(() => _muted = v);
              _rebuildMenu();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notifications enabled'),
            value: _notifications,
            onChanged: (v) {
              setState(() => _notifications = v);
              _rebuildMenu();
            },
          ),
          const SizedBox(height: 24),
          _section(theme, 'Actions'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _rebuildMenu,
                icon: const Icon(Icons.refresh),
                label: const Text('setContextMenu'),
              ),
              OutlinedButton.icon(
                onPressed: _popUp,
                icon: const Icon(Icons.open_in_new),
                label: const Text('popUpContextMenu'),
              ),
              OutlinedButton.icon(
                onPressed: _trayAlive ? _destroyTray : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('destroy'),
              ),
              FilledButton.tonalIcon(
                onPressed: _trayAlive ? null : _recreateTray,
                icon: const Icon(Icons.play_arrow),
                label: const Text('recreate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogPanel(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Event log', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: 'Clear',
                  onPressed: () => setState(_log.clear),
                  icon: const Icon(Icons.clear_all),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: _logCtrl,
                itemCount: _log.length,
                itemBuilder: (_, i) {
                  final e = _log[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '[${_fmt(e.time)}] ${e.message}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: theme.textTheme.titleMedium),
    );
  }

  static String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}.${t.millisecond.toString().padLeft(3, '0')}';
}

class _LogEntry {
  _LogEntry(this.time, this.message);
  final DateTime time;
  final String message;
}
