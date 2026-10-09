import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/controller/fortress_focus_session.dart';

void main() {
  test('revisiting a completed item does not create another auto advance', () {
    fakeAsync((clock) {
      final session = FortressFocusSession([1, 3]);
      session.count();
      clock.elapse(const Duration(seconds: 1));
      session.previous();
      session.pause(FortressFocusPause.study, true);
      session.pause(FortressFocusPause.study, false);
      clock.elapse(const Duration(seconds: 2));
      expect(session.index, 0);
      expect(session.completed, 1);
      session.dispose();
    });
  });
  for (final target in [1, 3, 33, 100]) {
    test('target $target advances once after completion dwell', () {
      fakeAsync((clock) {
        final session = FortressFocusSession([target, 3]);
        for (var i = 0; i < target + 2; i++) session.count();
        expect(session.completed, target);
        clock.elapse(const Duration(milliseconds: 599));
        expect(session.index, 0);
        clock.elapse(const Duration(milliseconds: 1));
        expect(session.index, 1);
        expect(session.completed, 0);
        clock.elapse(const Duration(seconds: 2));
        expect(session.index, 1);
        session.dispose();
      });
    });
  }

  test('overlapping pauses cancel advance and resume with a fresh dwell', () {
    fakeAsync((clock) {
      final session = FortressFocusSession([1, 1]);
      session.count();
      clock.elapse(const Duration(milliseconds: 500));
      session.pause(FortressFocusPause.study, true);
      session.pause(FortressFocusPause.share, true);
      clock.elapse(const Duration(seconds: 5));
      session.pause(FortressFocusPause.study, false);
      expect(session.paused, isTrue);
      session.count();
      expect(session.index, 0);
      session.pause(FortressFocusPause.share, false);
      clock.elapse(const Duration(milliseconds: 599));
      expect(session.index, 0);
      clock.elapse(const Duration(milliseconds: 1));
      expect(session.index, 1);
      session.dispose();
    });
  });

  test(
    'skipping and backward navigation retain counts and truthful completion',
    () {
      final session = FortressFocusSession([3, 1, 1]);
      session.count();
      session.next();
      session.count();
      session.next();
      session.count();
      session.next();
      expect(session.ended, isTrue);
      expect(session.allComplete, isFalse);
      expect(session.completedItems, 2);
      session.continueUnfinished();
      expect(session.index, 0);
      expect(session.remaining, 2);
      session.dispose();
    },
  );

  test('undo cancels completion, including after automatic navigation', () {
    fakeAsync((clock) {
      final session = FortressFocusSession([1, 2]);
      session.count();
      session.undo();
      clock.elapse(const Duration(seconds: 1));
      expect(session.index, 0);
      expect(session.remaining, 1);
      session.count();
      clock.elapse(const Duration(milliseconds: 600));
      session.undo();
      expect(session.index, 0);
      expect(session.remaining, 1);
      session.dispose();
    });
  });

  test('last item ends automatically; restart is explicit', () {
    fakeAsync((clock) {
      final session = FortressFocusSession([1]);
      session.count();
      clock.elapse(const Duration(milliseconds: 600));
      expect(session.ended, isTrue);
      expect(session.allComplete, isTrue);
      session.restart();
      expect(session.ended, isFalse);
      expect(session.remaining, 1);
      session.count();
      session.dispose();
      clock.elapse(const Duration(seconds: 1));
    });
  });

  test('manual navigation and inactivity cancel stale timers', () {
    fakeAsync((clock) {
      final session = FortressFocusSession([1, 3]);
      session.count();
      session.next();
      clock.elapse(const Duration(seconds: 1));
      expect(session.index, 1);
      session.previous();
      session.pause(FortressFocusPause.inactive, true);
      clock.elapse(const Duration(seconds: 1));
      expect(session.index, 0);
      session.pause(FortressFocusPause.inactive, false);
      clock.elapse(const Duration(milliseconds: 600));
      expect(session.index, 0);
      session.dispose();
    });
  });
}
