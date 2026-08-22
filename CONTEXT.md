# Tawaq

Tawaq is a desktop Islamic companion. This glossary names the distribution choices that shape how people obtain and install the app.

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
