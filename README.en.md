# Tawaq

Tawaq is a desktop Islamic app for prayer times, Quran reading and study, Hadith search, and Hisn al-Muslim. It brings those daily tools together in one calm, focused space.

**Tawaq** (تَوَّاق) evokes deep longing and a pull towards something.

> Tawaq is in beta. Details may change before the stable release.

[العربية](README.md) · [Beta downloads](https://github.com/MoathCodes/tawaq-app/releases) · [Report an issue](https://github.com/MoathCodes/tawaq-app/issues)

## What it does

- **Prayer:** Location-aware times with your chosen calculation method, alerts, iqamah offsets, completion history, and analytics.
- **Quran:** The Madinah Mushaf, search, translations, tafsir, notes, and recitations.
- **Hadith:** Search and filter Hadith from Dorar, with details, local favourites, and recent searches.
- **Muslim Fortress:** Adhkar and duas with commentary, source information, search, and focused reading.

## In the app

<p align="center">
  <img src="docs/images/readme/prayer-ar-light.webp" alt="Arabic prayer-times screen in the light theme" width="48%" />
  <img src="docs/images/readme/quran-study-ar-light.webp" alt="Arabic Quran study view in the light theme" width="48%" />
</p>
<p align="center">
  <img src="docs/images/readme/hadith-ar-light.webp" alt="Arabic Hadith search in the light theme" width="48%" />
  <img src="docs/images/readme/recitation-player-ar-dark.webp" alt="Arabic recitation player in the dark theme" width="48%" />
</p>
<p align="center">
  <img src="docs/images/readme/prayer-analytics-en-dark.webp" alt="Prayer analytics in the dark theme" width="48%" />
  <img src="docs/images/readme/fortress-en-dark.webp" alt="Muslim Fortress reading view in the dark theme" width="48%" />
</p>
<p align="center">
  <img src="docs/images/readme/settings-en-dark.webp" alt="Application settings in the dark theme" width="48%" />
</p>

## Offline-first

Tawaq is designed to remain useful without a connection. Prayer times, Quran reading, Muslim Fortress, and saved data work on your device. Hadith search and online recitations connect to their providers only when you use those features.

## Download and install

Beta releases are available for macOS, Windows, and Linux. Download the right package from the [releases page](https://github.com/MoathCodes/tawaq-app/releases).

| Platform | Available package |
| --- | --- |
| macOS | DMG and installer ZIP for Apple Silicon and Intel |
| Windows | EXE installer |
| Linux | DEB, RPM, Arch, and portable x64 ZIP packages |

Beta releases are unsigned, so your operating system may show a warning on first launch. On macOS, move the app to Applications and use the context menu to open it if warned. On Windows, review the SmartScreen warning before continuing with the installer.

For other Linux distributions, extract the ZIP and run `./install.sh`. The installer adds required runtime dependencies only when needed.

### Quick install

On macOS and Linux, install the latest beta with:

```bash
curl -fsSL https://raw.githubusercontent.com/MoathCodes/tawaq-app/acbaf6ec7836a5248d90fb3ba86f1031fbdfab65/website/public/install.sh | bash
```

The bootstrap is pinned to [a published repository commit](https://github.com/MoathCodes/tawaq-app/blob/acbaf6ec7836a5248d90fb3ba86f1031fbdfab65/website/public/install.sh), then verifies the release archive against its published SHA-256 checksum before running it. On macOS, it installs Tawaq in `~/Applications` and removes quarantine from that Tawaq copy only, so you do not need the extra Finder steps. On Linux, it installs in `~/.local/opt/tawaq` and asks for a password only when the bundle's library check proves a required system library is missing.

Prefer an inspectable install? Download the matching ZIP from the releases page, extract it, and run `./install.sh`. The installer supports `--uninstall` and replaces a previous app installation without deleting your data.

## For developers

Install [FVM](https://fvm.app/documentation/getting-started/installation). After cloning the repository, initialise the submodules, install the project Flutter SDK, and generate code:

```bash
git clone https://github.com/MoathCodes/tawaq-app.git
cd tawaq-app
git submodule update --init -- packages/adhan_dart packages/dorar_hadith
fvm install
fvm exec bash tool/codegen.sh
```

For day-to-day work:

```bash
fvm flutter run
fvm flutter analyze
fvm flutter test
```

Read the [contribution guide](CONTRIBUTING.md) and [codebase onboarding guide](docs/codebase-onboarding/README.md) before changing the app.

Read the [distribution decision](docs/adr/0001-user-local-installers.md) for the installer and Flatpak policy.

## Contributing

Fixes, improvements, and documentation work are welcome. Follow the [contribution guide](CONTRIBUTING.md), and open an issue before starting larger changes so we can agree on scope.

## Acknowledgements and sources

Tawaq is built with software and content from many people and organisations. We thank:

- [adhan_dart](https://github.com/prayer-timetable/adhan_dart) for prayer-time calculations.
- [Dorar](https://dorar.net/) and [dorar_hadith](https://github.com/MoathCodes/dorar_hadith) for Hadith search and reference data.
- [MP3Quran](https://www.mp3quran.net/) for online reciter and recitation data.
- [HisnElmoslem_App](https://github.com/muslimpack/HisnElmoslem_App) for the bundled Hisn al-Muslim content.
- [King Fahd Complex for the Printing of the Holy Quran](https://qurancomplex.gov.sa/) for the QCF4 fonts used to render the Mushaf. These fonts are not covered by the MIT license.
- [Athan-MP3](https://github.com/abodehq/Athan-MP3) for bundled adhan recordings.
- IBM Plex Sans Arabic and the Noto families used by the interface, under their included SIL Open Font Licenses.

Each bundled source and media asset remains subject to its own license and terms.

## License

Tawaq-owned code and documentation are available under the [MIT License](LICENSE). Third-party software and assets, including the QCF4 fonts, remain under their own terms.
