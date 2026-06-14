import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() {
  group('MushafStyle.modify factory', () {
    test('sets modifier hooks with short names', () {
      final style = MushafStyle.modify(
        ayah: (s) => s.copyWith(color: Colors.red),
        basmalah: (s) => s.copyWith(color: Colors.green),
      );

      expect(style.ayahStyle, isNull);
      expect(style.ayahStyleModifier, isNotNull);
      expect(style.basmalahStyleModifier, isNotNull);
      expect(
        style.ayahStyleModifier!(const TextStyle()).color,
        Colors.red,
      );
    });

    test('passes through non-style fields', () {
      const bg = Color(0xFFFFFBF0);
      const scale = MushafScale(readingBoost: 1.08);

      final style = MushafStyle.modify(
        backgroundColor: bg,
        scale: scale,
        highlightColor: Colors.amber,
      );

      expect(style.backgroundColor, bg);
      expect(style.scale.readingBoost, 1.08);
      expect(style.highlightColor, Colors.amber);
    });
  });

  group('MushafStyle surah header images', () {
    test('passes through surah header image fields', () {
      const style = MushafStyle(
        surahHeaderImage: 'assets/light.svg',
        surahHeaderImageDark: 'assets/dark.svg',
      );

      expect(style.surahHeaderImage, 'assets/light.svg');
      expect(style.surahHeaderImageDark, 'assets/dark.svg');
    });

    test('modify supports surahHeaderImageDark', () {
      final style = MushafStyle.modify(
        surahHeaderImage: 'assets/light.svg',
        surahHeaderImageDark: 'assets/dark.svg',
      );

      expect(style.surahHeaderImage, 'assets/light.svg');
      expect(style.surahHeaderImageDark, 'assets/dark.svg');
    });
  });

  group('MushafStyleCustomization.modify', () {
    test('chains modifiers for the same element', () {
      final style = MushafStyle.modify(
        ayah: (s) => s.copyWith(color: Colors.red),
      ).modify(
        ayah: (s) => s.copyWith(fontWeight: FontWeight.bold),
      );

      final merged = style.ayahStyleModifier!(const TextStyle());
      expect(merged.color, Colors.red);
      expect(merged.fontWeight, FontWeight.bold);
    });

    test('preserves explicit TextStyle bases from constructor', () {
      const base = TextStyle(color: Colors.blue);
      final style = const MushafStyle(ayahStyle: base).modify(
        ayah: (s) => s.copyWith(fontWeight: FontWeight.w600),
      );

      expect(style.ayahStyle, base);
      expect(
        style.ayahStyleModifier!(base).fontWeight,
        FontWeight.w600,
      );
    });

    test('updates scale without clearing modifiers', () {
      final style = MushafStyle.modify(
        ayah: (s) => s.copyWith(color: Colors.red),
      ).modify(scale: const MushafScale(readingBoost: 1.1));

      expect(style.scale.readingBoost, 1.1);
      expect(style.ayahStyleModifier, isNotNull);
    });
  });

  group('composeStyleModifiers', () {
    test('returns null when both inputs are null', () {
      expect(composeStyleModifiers(null, null), isNull);
    });

    test('composes in order', () {
      final composed = composeStyleModifiers(
        (s) => s.copyWith(color: Colors.red),
        (s) => s.copyWith(fontSize: 32),
      )!;

      final result = composed(const TextStyle(fontSize: 28));
      expect(result.color, Colors.red);
      expect(result.fontSize, 32);
    });
  });
}
