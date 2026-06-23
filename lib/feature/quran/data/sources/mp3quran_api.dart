import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';

/// A recitation that has ayah-by-ayah timing data (from `ayat_timing/reads`).
class TimingRead {
  /// Creates a [TimingRead].
  const TimingRead({required this.id, required this.folderUrl});

  /// The `read` id used as the `read` parameter when fetching timings.
  final int id;

  /// Audio server folder (matches a [Moshaf.server]) used to link the read to
  /// a reciter's moshaf.
  final String folderUrl;
}

/// Thin client over the mp3quran.net v3 API.
class Mp3QuranApi {
  /// Creates a [Mp3QuranApi].
  Mp3QuranApi({required this._client, required this._logger});

  final http.Client _client;
  final Logger _logger;

  static const _base = 'https://www.mp3quran.net/api/v3';
  static const _language = 'ar';

  /// Fetches the full reciter catalog (without timing links).
  Future<List<Reciter>> fetchReciters() async {
    final json = await _getJson('$_base/reciters?language=$_language');
    final list = (json['reciters'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_parseReciter)
        .where((r) => r.moshaf.isNotEmpty)
        .toList();
  }

  /// Fetches the recitations that have ayah timing data.
  Future<List<TimingRead>> fetchTimingReads() async {
    final json = await _getJson('$_base/ayat_timing/reads?language=$_language');
    // The endpoint returns a bare JSON array; [_getJson] wraps it under `data`.
    final list =
        (json['data'] as List?) ?? (json['reads'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => TimingRead(
            id: _asInt(e['id']),
            folderUrl: (e['folder_url'] as String? ?? '').trim(),
          ),
        )
        .where((r) => r.folderUrl.isNotEmpty)
        .toList();
  }

  /// Fetches per-ayah timing for [surah] from [readId].
  Future<SurahTiming> fetchSurahTiming(int surah, int readId) async {
    final json = await _getJson(
      '$_base/ayat_timing?surah=$surah&read=$readId',
    );
    // The endpoint returns a bare JSON array; [_getJson] wraps it under `data`.
    final list = (json['data'] as List?) ?? const [];
    final ayat = list
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => AyahTiming(
            ayah: _asInt(e['ayah']),
            startMs: _asInt(e['start_time']),
            endMs: _asInt(e['end_time']),
          ),
        )
        .toList();
    return SurahTiming(surah: surah, readId: readId, ayat: ayat);
  }

  Reciter _parseReciter(Map<String, dynamic> json) {
    final moshafList = (json['moshaf'] as List?) ?? const [];
    return Reciter(
      id: _asInt(json['id']),
      name: (json['name'] as String? ?? '').trim(),
      moshaf: moshafList
          .whereType<Map<String, dynamic>>()
          .map(_parseMoshaf)
          .toList(),
    );
  }

  Moshaf _parseMoshaf(Map<String, dynamic> json) {
    final surahCsv = json['surah_list'] as String? ?? '';
    final surahList = surahCsv
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
    return Moshaf(
      id: _asInt(json['id']),
      name: (json['name'] as String? ?? '').trim(),
      server: (json['server'] as String? ?? '').trim(),
      surahList: surahList,
      surahTotal: _asInt(json['surah_total']),
    );
  }

  /// GETs [url] and decodes JSON. A top-level array is wrapped as
  /// `{data: [...]}`.
  Future<Map<String, dynamic>> _getJson(String url) async {
    try {
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Mp3QuranApiException(
          'GET $url failed with ${response.statusCode}',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is List) return {'data': decoded};
      if (decoded is Map<String, dynamic>) return decoded;
      throw Mp3QuranApiException(
        'GET $url returned unexpected JSON',
      );
    } on Object catch (error, stack) {
      _logger.e('mp3quran request failed', error: error, stackTrace: stack);
      rethrow;
    }
  }

  static int _asInt(Object? value) => switch (value) {
    final int v => v,
    final String v => int.tryParse(v) ?? 0,
    final double v => v.toInt(),
    _ => 0,
  };
}

/// Raised when an mp3quran request fails.
class Mp3QuranApiException implements Exception {
  /// Creates an [Mp3QuranApiException].
  const Mp3QuranApiException(this.message);

  /// Human-readable cause.
  final String message;

  @override
  String toString() => 'Mp3QuranApiException: $message';
}
