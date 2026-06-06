#!/usr/bin/env python3
import sqlite3
from pathlib import Path

conn = sqlite3.connect("assets/database/tafseer_ar/Quraan_IK.db")
cur = conn.cursor()


def ik_text(sura: int, ayah: int) -> str:
    cur.execute("SELECT Tafsir FROM IK WHERE SURA_num=? AND AYA_num=?", (sura, ayah))
    return cur.fetchone()[0]


def slice_text(text: str, start: str, end: str | None = None) -> str:
    i = text.find(start)
    if i < 0:
        return ""
    j = text.find(end, i) if end else len(text)
    if j < 0:
        j = len(text)
    return text[i:j]


def poetry_phrase(raw: str) -> str:
    for line in raw.replace("<br>", "\n").split("\n"):
        trimmed = line.strip()
        if len(trimmed) >= 8 and not trimmed.endswith(":"):
            return trimmed[:24]
    return raw[:24]


t1 = ik_text(1, 1)
t2 = ik_text(1, 2)
t6 = ik_text(1, 6)
ba = sqlite3.connect("assets/database/tafseer_ar/Quraan_Ba.db").execute(
    "SELECT Tafsir FROM Ba WHERE SURA_num=1 AND AYA_num=1"
).fetchone()[0]

u = t1.find("قال أمية")
j = t6.find("جرير بن")
b = ba.find("قال الش")

snips = {
    "ik_shair": slice_text(t2, "يكون بالجنان", "ولكنهم"),
    "ibn_mu": slice_text(t2, "كما قال ابن المعتز", "</div>"),
    "mutanabbi": slice_text(t1, "كما قال المتنبي", "فصل"),
    "dhi_rumma": slice_text(t1, "استشهد بقول ذي الرمة", "يعني"),
    "umayya": t1[u : t1.find("فقال", u)],
    "jarir": t6[j - 4 : t6.find("قال :", j)],
    "ba_shair": ba[b : b + 80],
}

phrases = {k: poetry_phrase(v) for k, v in snips.items()}


def esc(s: str) -> str:
    return s.replace("\\", r"\\").replace("'", r"\'")


lines = [
    "import 'package:flutter_test/flutter_test.dart';",
    "import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';",
    "import 'package:tawaq/feature/quran/domain/services/tafsir_poetry_splitter.dart';",
    "import 'package:tawaq/feature/quran/domain/services/tafsir_text_normalizer.dart';",
    "import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';",
    "",
    "void main() {",
    "  group('TafsirPoetrySplitter', () {",
    "    List<TafsirTextSegment> expandFromRaw(String raw) {",
    "      final text = TafsirTextNormalizer.normalize(raw.replaceAll('<br>', '\\n'));",
    "      return TafsirPoetrySplitter.expand([",
    "        TafsirTextSegment(text: text, kind: TafsirSegmentKind.commentary),",
    "      ]);",
    "    }",
    "",
    "    test('splits wide-gap lines into poetry segments', () {",
    "      const commentary = TafsirTextSegment(",
    "        text: 'مقدمة\\n'"
    "            'ya man alooz beh fima a\\'miluh    la yajbur al-nasa \\'adhan anta kasirah\\n'"
    "            'khatima',",
    "        kind: TafsirSegmentKind.commentary,",
    "      );",
    "      final expanded = TafsirPoetrySplitter.expand([commentary]);",
    "      expect(expanded, hasLength(3));",
    "      expect(expanded[1].kind, TafsirSegmentKind.poetry);",
    "    });",
]


def add(name: str, raw: str, extra: list[str]) -> None:
    lines.extend(
        [
            "",
            f"    test('{name}', () {{",
            f"      const raw = '{esc(raw)}';",
            "      final poetry = expandFromRaw(raw)"
            ".where((s) => s.kind == TafsirSegmentKind.poetry);",
            *extra,
            "    });",
        ]
    )


add(
    "splits IK 1:2 br-separated poetry after qala al-shaair",
    snips["ik_shair"],
    [
        "      expect(poetry, hasLength(1));",
        f"      expect(poetry.first.text, contains('{esc(phrases['ik_shair'][:12])}'));",
    ],
)
add(
    "merges cross-line second hemistich for ibn al-Mutazz bayt",
    snips["ibn_mu"],
    [
        "      expect(poetry, hasLength(1));",
        f"      expect(poetry.first.text, contains('{esc(phrases['ibn_mu'][:12])}'));",
        f"      expect(poetry.first.poetryHemistichs?.last, contains('تدل على أنه'));",
    ],
)
lines.extend(
    [
        "",
        "    test('keeps parallel Mutanabbi hemistich on next line as separate poetry', () {",
        f"      const raw = '{esc(snips['mutanabbi'])}<br>fasl';",
        "      final poetry = expandFromRaw(raw)"
        ".where((s) => s.kind == TafsirSegmentKind.poetry).toList();",
        "      expect(poetry, hasLength(2));",
        f"      expect(poetry.first.text, contains('{esc(phrases['mutanabbi'][-12:])}'));",
        "    });",
    ]
)
add(
    "splits Baghawi br-separated hemistichs after qala al-shaair",
    snips["ba_shair"],
    [
        "      expect(poetry, hasLength(1));",
        f"      expect(poetry.first.text, contains('{esc(phrases['ba_shair'][12:24])}'));",
    ],
)
add(
    "detects single-line bayt after dhi al-Rumma attribution",
    snips["dhi_rumma"],
    [
        "      expect(poetry, hasLength(1));",
        f"      expect(poetry.first.text, contains('{esc(phrases['dhi_rumma'][:12])}'));",
    ],
)
add(
    "detects single-line bayt after umayya attribution",
    snips["umayya"],
    [
        "      expect(poetry, hasLength(1));",
        f"      expect(poetry.first.text, contains('{esc(phrases['umayya'][:12])}'));",
    ],
)
add(
    "splits jarir br-separated hemistichs",
    snips["jarir"],
    [
        "      expect(poetry, hasLength(1));",
        "      expect(poetry.first.poetryHemistichs, hasLength(2));",
    ],
)
lines.extend(
    [
        "",
        "    test('end-to-end parser keeps poetry for wide-gap fixtures', () {",
        f"      const raw = '{esc(snips['mutanabbi'])}';",
        "      final poetry = TafsirTextParser.parse(raw)"
        ".where((s) => s.kind == TafsirSegmentKind.poetry);",
        "      expect(poetry, isNotEmpty);",
        "    });",
        "  });",
        "}",
        "",
    ]
)

Path("test/feature/quran/tafsir_poetry_splitter_test.dart").write_text("\n".join(lines))
print("snips", {k: len(v) for k, v in snips.items()})
print("phrases", phrases)
