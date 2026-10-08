import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Localized operational feedback without leaking source payloads/diagnostics.
String hadithFailureMessage(
  Object? error,
  AppLocalizations l10n,
) => switch (error) {
  HadithRequestInterruption.collectionChanged => l10n.hadithSearchInterrupted,
  DorarSubrequestException(:final cause) => hadithFailureMessage(cause, l10n),
  DorarParseException() => l10n.hadithSourceUnreadable,
  DorarTimeoutException() => l10n.hadithRequestTimedOut,
  DorarRateLimitException(:final resetAt) =>
    resetAt == null
        ? l10n.hadithSourceRateLimited
        : '${l10n.hadithSourceRateLimited} ${resetAt.toLocal()}',
  DorarServerException() => l10n.hadithSourceServerFailed,
  DorarValidationException() => l10n.hadithInvalidSearch,
  _ => l10n.hadithRequestFailed,
};
