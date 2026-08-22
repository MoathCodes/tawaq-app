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
  const FortressShareOptions(this.includes);

  factory FortressShareOptions.defaults({
    required bool hasSource,
    required bool hasRepetition,
  }) {
    return FortressShareOptions({
      if (hasSource) FortressShareInclude.source,
      if (hasRepetition) FortressShareInclude.repetition,
      FortressShareInclude.appName,
    });
  }

  final Set<FortressShareInclude> includes;

  bool contains(FortressShareInclude value) => includes.contains(value);

  FortressShareOptions copyWith(Set<FortressShareInclude> next) =>
      FortressShareOptions(next);
}
