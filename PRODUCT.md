# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Tawaq is for Muslims who want a comprehensive Islamic companion available throughout ordinary daily life on their desktop. They may turn to it to follow prayer times and receive prayer alerts, read or listen to the Quran, read their daily adhkar, or investigate Hadith sources and authenticity.

The current product scope is intentionally not treated as final; future audiences and jobs remain open decisions.

## Product Purpose

Tawaq brings recurring Islamic practices and trusted religious reference tools into one dependable desktop application. It should remain useful throughout the day without making people work around the software.

Success means that prayer, Quran, Hadith, and daily adhkar workflows are accurate, readily available, respectful of the source material, and pleasant enough to become a natural part of daily life.

## Positioning

Tawaq combines strong desktop integration—especially first-class Linux support—with a polished experience that feels attractive, snappy, lightweight, and cooperative. It aims to serve desktop Muslims with a level of care that Islamic applications often reserve for other platforms, while avoiding software that feels obstructive or burdensome.

## Operating Context

Tawaq is a desktop application used intermittently throughout the day. Core workflows include:

- checking location-aware prayer times, receiving prayer and iqamah alerts, and reviewing prayer completion history;
- reading the Madinah Mushaf, studying translations and tafsir, taking notes, and listening to Quran recitations;
- searching and filtering Hadith, inspecting source and authenticity information, and saving useful results;
- browsing, searching, and reading Hisn al-Muslim adhkar and duas with commentary and source information;
- keeping the application available through desktop conventions such as the system tray, notifications, launch-at-login, and native window behavior.

## Capabilities and Constraints

- The application currently targets Linux, macOS, and Windows from one Flutter codebase while adapting desktop integration to the host operating system.
- Arabic and English are supported interface languages, including right-to-left and left-to-right operation.
- Prayer times, Quran reading, Hisn al-Muslim, and saved user data are designed to remain useful offline. Hadith search and online recitations connect to their providers when those features are used.
- Religious text, prayer calculations, Hadith attribution and authenticity, Arabic handling, and calendar behavior are trust-critical. Tawaq must not invent religious claims, translations, corrections, or fallbacks.
- Source content must remain distinct from display and search transformations.
- Privacy is a top priority. Product decisions should minimize unnecessary collection, exposure, and transmission of user data.
- Persisted user state is durable product data. Compatibility, hydration ordering, and required flush boundaries must be preserved.
- Linux support is a top priority, not a secondary compatibility target.
- Future capabilities and user-focused differentiators are intentionally undecided rather than constrained by the current feature set.

## Brand Commitments

The product name is **Tawaq** (**تَوَّاق**), evoking deep longing and a pull toward something.

The product should feel calm, focused, trustworthy, attractive, fast, lightweight, and respectful of the person using it. The interface and experience should continually improve and must not regress in usability or quality.

Existing application icons live at `assets/images/app_icon.png` and in the platform runner asset directories. Existing Arabic and English product copy lives in `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`.

## Evidence on Hand

- `README.md` and `README.en.md` describe the current product, distribution model, offline behavior, and content acknowledgements.
- `docs/images/readme/` contains current Arabic and English screenshots across light and dark themes.
- `CONTEXT.md` defines established terminology for Quran recitation, prayer alerts, content sharing, and distribution.
- Bundled Quran, Hisn al-Muslim, Adhan, Iqamah, and typography assets live under `assets/` and package-local data directories.
- Prayer calculations use the in-repository `packages/adhan_dart` dependency.
- Hadith search and reference data use Dorar and the in-repository `packages/dorar_hadith` dependencies.
- Online reciter and recitation data come from MP3Quran.
- Hisn al-Muslim content comes from the in-repository `packages/hisn_elmoslem` dependency, sourced from HisnElmoslem_App.
- Mushaf rendering uses assets from the King Fahd Complex for the Printing of the Holy Quran.
- No testimonials, customer claims, usage benchmarks, or institutional endorsements are established in the repository and future work must not fabricate them.

## Product Principles

1. **Trust is foundational.** Religious content, attribution, prayer behavior, Arabic handling, and time-sensitive behavior must remain accurate and traceable to real sources.
2. **Desktop is a first-class home.** Tawaq should integrate deeply and naturally with desktop operating systems, with exceptional Linux support.
3. **The software cooperates.** Every workflow should feel fast, lightweight, obvious, and free of needless friction.
4. **Privacy stays ahead of convenience.** Prefer local ownership and offline capability; use network services only where the requested feature requires them.
5. **Quality only moves forward.** UI and UX changes must preserve coherent behavior and prevent regressions while raising the experience over time.

## Accessibility & Inclusion

Tawaq serves Arabic- and English-speaking Muslims through localized right-to-left and left-to-right interfaces. The existing application includes keyboard shortcuts, semantic labels for assistive technologies, scalable interface and Quran text, reduced-motion handling, and platform-aware desktop controls. Future work should preserve and extend those capabilities across supported desktop systems.
