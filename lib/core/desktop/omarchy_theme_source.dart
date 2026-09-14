import 'dart:async';
import 'dart:io';

import 'package:toml/toml.dart';

/// A parsed snapshot of Omarchy's active color palette.
class OmarchyThemeSnapshot {
  /// Creates a snapshot. Use [OmarchyThemeSnapshot.unavailable] when no active
  /// Omarchy palette is available.
  const new({
    required this.isAvailable,
    required this.values,
  });

  /// Snapshot representing an unavailable Omarchy environment.
  // ignore: unnecessary_type_name_in_constructor
  const OmarchyThemeSnapshot.unavailable()
    : isAvailable = false,
      values = const <String, Object?>{};

  /// Whether the snapshot came from an active Omarchy session and palette.
  final bool isAvailable;

  /// Raw values from Omarchy's `colors.toml`.
  final Map<String, Object?> values;

  /// Returns a string-valued Omarchy token, if present.
  String? colorToken(String key) {
    final value = values[key];
    return value is String ? value : null;
  }
}

/// Reads and watches the active Omarchy theme without depending on the
/// Omarchy widget toolkit.
///
/// Omarchy exposes its generated active theme in
/// `~/.local/state/omarchy/current/theme/colors.toml`. Older installations use
/// `~/.config/omarchy/current/theme`. The session marker prevents a leftover
/// theme directory from enabling the palette on another Linux desktop.
class OmarchyThemeSource {
  /// Creates a source. Optional arguments make filesystem and environment
  /// behavior deterministic in tests.
  new({
    String? home,
    this._stateHome,
    Map<String, String>? environment,
    bool? isLinux,
  }) : _home = home ?? Platform.environment['HOME'] ?? '',
       _environment = environment ?? Platform.environment,
       _isLinux = isLinux ?? Platform.isLinux;

  final String _home;
  final String? _stateHome;
  final Map<String, String> _environment;
  final bool _isLinux;

  /// Whether the process appears to be running inside an Omarchy session.
  bool get isOmarchySession {
    if (!_isLinux) return false;

    final omarchyPath = _environment['OMARCHY_PATH'];
    if (omarchyPath != null && Directory(omarchyPath).existsSync()) return true;

    final sessionValues = <String?>[
      _environment['DESKTOP_SESSION'],
      _environment['XDG_CURRENT_DESKTOP'],
      _environment['XDG_SESSION_DESKTOP'],
    ];
    return sessionValues.any((value) {
      if (value == null) return false;
      return value.toLowerCase().split(RegExp(r'[:;,\s]+')).contains('omarchy');
    });
  }

  /// The active theme directory, preferring the modern state location.
  Directory? get currentThemeDirectory {
    for (final directory in _candidateThemeDirectories) {
      if (File('${directory.path}/colors.toml').existsSync()) return directory;
    }
    return null;
  }

  Iterable<Directory> get _candidateThemeDirectories sync* {
    final stateHome =
        _stateHome ??
        _environment['XDG_STATE_HOME'] ??
        (_home.isEmpty ? '' : '$_home/.local/state');
    if (stateHome.isNotEmpty) {
      yield Directory('$stateHome/omarchy/current/theme');
    }
    if (_home.isNotEmpty) {
      yield Directory('$_home/.config/omarchy/current/theme');
    }
  }

  Iterable<Directory> get _watchDirectories sync* {
    final stateHome =
        _stateHome ??
        _environment['XDG_STATE_HOME'] ??
        (_home.isEmpty ? '' : '$_home/.local/state');
    if (stateHome.isNotEmpty) {
      yield Directory('$stateHome/omarchy/current');
    }
    if (_home.isNotEmpty) {
      yield Directory('$_home/.config/omarchy/current');
    }
  }

  /// Reads the active palette, or returns an unavailable snapshot.
  OmarchyThemeSnapshot read() {
    if (!isOmarchySession) return const OmarchyThemeSnapshot.unavailable();

    final directory = currentThemeDirectory;
    if (directory == null) return const OmarchyThemeSnapshot.unavailable();

    try {
      final values = TomlDocument.parse(
        File('${directory.path}/colors.toml').readAsStringSync(),
      ).toMap();
      return OmarchyThemeSnapshot(
        isAvailable: true,
        values: Map<String, Object?>.from(values),
      );
    } on Object {
      return const OmarchyThemeSnapshot.unavailable();
    }
  }

  /// Watches for active-theme changes and emits debounced snapshots.
  Stream<OmarchyThemeSnapshot> watch() {
    if (!isOmarchySession) return const Stream<OmarchyThemeSnapshot>.empty();

    final controller = StreamController<OmarchyThemeSnapshot>();
    final subscriptions = <StreamSubscription<FileSystemEvent>>[];
    Timer? debounce;

    void emitLatest() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 200), () {
        if (!controller.isClosed) controller.add(read());
      });
    }

    controller
      ..onListen = () {
        for (final directory in _watchDirectories) {
          if (!directory.existsSync()) continue;
          subscriptions.add(
            directory
                .watch(recursive: true)
                .listen(
                  (_) => emitLatest(),
                  onError: (_) {},
                ),
          );
        }
      }
      ..onCancel = () async {
        debounce?.cancel();
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        subscriptions.clear();
      };

    return controller.stream;
  }
}
