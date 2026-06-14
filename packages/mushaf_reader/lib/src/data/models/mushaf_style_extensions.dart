import 'package:flutter/material.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart';

/// Extension methods for composing [MushafStyle] customizations.
extension MushafStyleCustomization on MushafStyle {
  /// Returns a copy with additional style modifiers chained on top.
  ///
  /// Modifiers for the same element compose left-to-right: existing
  /// modifiers run first, then [ayah], [activeAyah], etc.
  ///
  /// Non-style fields replace the current value when provided.
  ///
  /// ```dart
  /// final style = MushafStyle.modify(
  ///   ayah: (s) => s.copyWith(color: Colors.brown),
  /// ).modify(
  ///   activeAyah: (s) => s.copyWith(backgroundColor: Colors.amber),
  ///   scale: MushafScale(readingBoost: 1.08),
  /// );
  /// ```
  MushafStyle modify({
    StyleModifier? ayah,
    StyleModifier? activeAyah,
    StyleModifier? basmalah,
    StyleModifier? surahName,
    StyleModifier? headerSurahName,
    StyleModifier? juz,
    StyleModifier? pageNumber,
    String? surahHeaderImage,
    String? surahHeaderImageDark,
    Color? highlightColor,
    Color? backgroundColor,
    MushafScale? scale,
  }) {
    return MushafStyle(
      ayahStyle: ayahStyle,
      ayahStyleModifier: composeStyleModifiers(ayahStyleModifier, ayah),
      activeAyahStyle: activeAyahStyle,
      activeAyahStyleModifier: composeStyleModifiers(
        activeAyahStyleModifier,
        activeAyah,
      ),
      basmalahStyle: basmalahStyle,
      basmalahStyleModifier: composeStyleModifiers(
        basmalahStyleModifier,
        basmalah,
      ),
      surahNameStyle: surahNameStyle,
      surahNameStyleModifier: composeStyleModifiers(
        surahNameStyleModifier,
        surahName,
      ),
      headerSurahNameStyle: headerSurahNameStyle,
      headerSurahNameStyleModifier: composeStyleModifiers(
        headerSurahNameStyleModifier,
        headerSurahName,
      ),
      juzStyle: juzStyle,
      juzStyleModifier: composeStyleModifiers(juzStyleModifier, juz),
      pageNumberStyle: pageNumberStyle,
      pageNumberStyleModifier: composeStyleModifiers(
        pageNumberStyleModifier,
        pageNumber,
      ),
      surahHeaderImage: surahHeaderImage ?? this.surahHeaderImage,
      surahHeaderImageDark: surahHeaderImageDark ?? this.surahHeaderImageDark,
      highlightColor: highlightColor ?? this.highlightColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      scale: scale ?? this.scale,
    );
  }
}
