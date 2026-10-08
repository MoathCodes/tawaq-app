import 'dart:async';

import 'package:flutter/foundation.dart';

enum FortressFocusPause { study, share, inactive, menu }

/// One transient chapter reading session, including its advance boundary.
class FortressFocusSession extends ChangeNotifier {
  FortressFocusSession(List<int> targets, {int initialIndex = 0})
    : targets = List.unmodifiable(targets.map((n) => n < 1 ? 1 : n)),
      _remaining = targets.map((n) => n < 1 ? 1 : n).toList(),
      _index = targets.isEmpty ? 0 : initialIndex.clamp(0, targets.length - 1);

  final List<int> targets;
  final List<int> _remaining;
  final _pauses = <FortressFocusPause>{};
  Timer? _advance;
  int _index;
  int? _lastCountIndex;
  int? _pendingAdvanceIndex;
  bool _ended = false;
  bool _disposed = false;
  int direction = -1;

  int get index => _index;
  List<int> get remainingCounts => List.unmodifiable(_remaining);
  int get remaining => targets.isEmpty ? 0 : _remaining[_index];
  int get completed => targets.isEmpty ? 0 : targets[_index] - remaining;
  double get progress => targets.isEmpty ? 0 : completed / targets[_index];
  bool get paused => _pauses.isNotEmpty;
  bool get ended => _ended;
  bool get canUndo => _lastCountIndex != null;
  int get completedItems => _remaining.where((n) => n == 0).length;
  bool get allComplete =>
      targets.isNotEmpty && completedItems == targets.length;

  void count() {
    if (paused || ended || targets.isEmpty || remaining == 0) return;
    _remaining[_index]--;
    _lastCountIndex = _index;
    if (remaining == 0) _pendingAdvanceIndex = _index;
    notifyListeners();
    _scheduleAdvance();
  }

  void undo() {
    final index = _lastCountIndex;
    if (index == null) return;
    _cancelAdvance();
    _pendingAdvanceIndex = null;
    _remaining[index] = (_remaining[index] + 1).clamp(0, targets[index]);
    direction = index < _index ? 1 : -1;
    _index = index;
    _ended = false;
    _lastCountIndex = null;
    notifyListeners();
  }

  void pause(FortressFocusPause reason, bool value) {
    final changed = value ? _pauses.add(reason) : _pauses.remove(reason);
    if (!changed) return;
    _cancelAdvance();
    notifyListeners();
    if (!paused) _scheduleAdvance();
  }

  void next() {
    if (targets.isEmpty || ended) return;
    _pendingAdvanceIndex = null;
    if (_index == targets.length - 1) {
      _cancelAdvance();
      _ended = true;
      notifyListeners();
    } else {
      goTo(_index + 1);
    }
  }

  void previous() {
    if (_index > 0) goTo(_index - 1);
  }

  void goTo(int index) {
    if (index < 0 || index >= targets.length) return;
    _cancelAdvance();
    _pendingAdvanceIndex = null;
    direction = index < _index ? 1 : -1;
    _index = index;
    _ended = false;
    notifyListeners();
  }

  void continueUnfinished() {
    final index = _remaining.indexWhere((n) => n > 0);
    if (index >= 0) goTo(index);
  }

  void restart() {
    _cancelAdvance();
    _pendingAdvanceIndex = null;
    for (var i = 0; i < targets.length; i++) {
      _remaining[i] = targets[i];
    }
    _index = 0;
    _ended = false;
    _lastCountIndex = null;
    notifyListeners();
  }

  void _scheduleAdvance() {
    if (paused ||
        ended ||
        targets.isEmpty ||
        remaining > 0 ||
        _advance != null ||
        _pendingAdvanceIndex != _index)
      return;
    final completedIndex = _index;
    _advance = Timer(const Duration(milliseconds: 600), () {
      _advance = null;
      if (!_disposed &&
          !paused &&
          !ended &&
          _index == completedIndex &&
          remaining == 0)
        next();
    });
  }

  void _cancelAdvance() {
    _advance?.cancel();
    _advance = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelAdvance();
    super.dispose();
  }
}
