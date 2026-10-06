enum FortressShareInclude {
  repetition,
  source,
  virtue,
  sharh,
  hadith,
  benefit,
  appName,
}

class FortressShareOptions {
  const new(this.includes);

  factory defaults({
    required bool hasSource,
    required bool hasRepetition,
    bool hasVirtue = false,
  }) {
    return FortressShareOptions({
      if (hasSource) FortressShareInclude.source,
      if (hasVirtue) FortressShareInclude.virtue,
      if (hasRepetition) FortressShareInclude.repetition,
      FortressShareInclude.appName,
    });
  }

  final Set<FortressShareInclude> includes;

  bool contains(FortressShareInclude value) => includes.contains(value);

  FortressShareOptions copyWith(Set<FortressShareInclude> next) =>
      FortressShareOptions(next);
}
