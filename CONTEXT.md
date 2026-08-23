# Tawaq

Tawaq is a desktop Islamic companion. This glossary names the product concepts that shape how people use, obtain, and install the app.

## Quran recitation

**Recitation session**:
The active or restorable Quran playback selection, including its reciter, moshaf, Surah or ayah range, position, repetition state, timing, sleep state, and any prayer-alert interruption. It survives closing the playback controls and moving through the app; stopping retains enough state to replay.
_Avoid_: player state, audio session

**Recitation initialization**:
The period in which Tawaq restores the saved reciter, riwayah, Surah, and recitation range and resolves the Quran reference data needed to present them. It ends before audio preparation begins and never starts playback by itself.
_Avoid_: playback loading, audio loading

**Audio preparation**:
The period after a playable recitation selection is ready while Tawaq obtains and opens its audio and timing data.
_Avoid_: recitation initialization

**Quran reference data**:
The canonical Surah and ayah information used to resolve localized Surah names, ayah counts, and valid recitation-range bounds.
_Avoid_: playback metadata, audio metadata

**Download selection**:
The temporary set of saved recitation files a person has explicitly selected for one management action. It is not persisted, and closing the manager, rescanning its files, or refreshing reciter data clears it. Successful deletion removes only the affected files from it while failed files remain selected for retry.
_Avoid_: playback selection, recitation selection
**Restored recitation selection**:
A saved reciter, riwayah, Surah, and range loaded during recitation initialization. Tawaq may restore it silently before the person has played or changed it, but playback always requires a separate action.
_Avoid_: automatic playback, default recitation

## Content sharing

**Share card**:
A PNG image of selected religious content and user-selected supporting details. It grows with its content up to a comfortable maximum height.
_Avoid_: social post, visual template

**Share set**:
An ordered group of share cards created only when the selected content cannot remain readable within one card. Cards use explicit section headings and retain enough context to remain understandable when shared together.
_Avoid_: document, carousel

**Share bundle**:
The draggable desktop representation of one share card or an entire share set. It lets a person transfer the generated PNG files together to another application.
_Avoid_: WhatsApp share, share button

**Share interaction model**:
The desktop flow in which a person opens a shared dialog layout, chooses which available details to include, checks the resulting preview, then saves or copies the share card. Each feature owns its card content and share state.
_Avoid_: card designer, native share sheet

**Share option**:
An available content detail that a person may include in or omit from a share card. Appearance controls are not share options.
_Avoid_: customization setting, display preference

## Distribution

**One-line installer**:
A Tawaq command that installs the appropriate release for the current operating system.
_Avoid_: curl command, bootstrap script

**Packaged installer**:
An installer included with a Tawaq release archive for people who prefer a downloaded file.
_Avoid_: manual installer

**User-local installation**:
A Tawaq application copy owned by the current user, without administrator access.
_Avoid_: system installation

**Portable Linux installation**:
A user-local Tawaq installation from the Linux x64 archive, independent of the distribution's native package format.
_Avoid_: Linux package

**Flatpak distribution**:
The planned official Linux distribution route. The portable Linux installation remains a fallback.
_Avoid_: native package
