# AGENTS.md

This is a StartOS service-package repository — it builds a `.s9pk` for StartOS.

Develop it inside a StartOS packaging workspace created by `start-cli s9pk init-workspace`,
which provides the packaging guide and agent context one level up. If you're reading this in a
bare clone with no workspace, the full guide is at <https://docs.start9.com/packaging>.

## This repo

- **Keep `runAsInit: true`.** The base image is s6-overlay, which must be PID 1; without it nothing in the desktop comes up.
- **Keep `root/defaults/autostart` copied on every launch** (`startwm.sh` does it). Selkies only seeds it when absent, so an upgraded volume would otherwise keep an obsolete startup script.
- **Keep `root/defaults/autostart` POSIX `sh`.** `openbox-autostart` runs it as `sh $AUTOSTART` (dash on Debian) whatever its shebang says, and a single bashism makes dash reject the whole file before Ashigaru launches. Check it with `dash -n` and `shellcheck -s sh`.
- **Keep `--dir` on the launch command.** Java takes its default home from the passwd entry, not `$HOME`; without `--dir`, wallets could land outside the backed-up volume.
- **Don't loosen the Selkies hardening env** (`DISABLE_OPEN_TOOLS`, `DISABLE_SUDO`, `DISABLE_TERMINALS`, `SELKIES_COMMAND_ENABLED=false`, the sidebar flags): it keeps the webtop from being a shell on the box. Don't name the link handler `xdg-open`, or `DISABLE_OPEN_TOOLS` will `chmod 0000` it.
- **Size the main window with the autostart's fit loop, not Openbox maximise.** JavaFX pins the main window's size hints while a modal dialog is open, which undoes maximising.
- **Keep `fonts-noto-core` and `xcompmgr` in the image.** The first is the only source of the copy and lock glyphs; without the second, JavaFX popups get a white margin.
