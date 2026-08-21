# Tawaq

Tawaq is a desktop Islamic companion. This glossary names the distribution choices that shape how people obtain and install the app.

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
