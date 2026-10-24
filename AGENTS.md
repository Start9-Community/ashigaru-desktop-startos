# AGENTS.md

This is a StartOS service-package repository — it builds a `.s9pk` for StartOS. The packaging guide is at <https://docs.start9.com/packaging>; start at its recipe index.

Keep `README.md` (technical reference for an AI support or administering agent) and `instructions.md` (end-user docs) in sync with your changes.

## This repo

- **Keep `runAsInit: true`.** The base image is s6-overlay, which must be PID 1; without it nothing in the desktop comes up.
- **Keep `root/defaults/autostart` copied on every launch** (`startwm.sh` does it). Selkies only seeds it when absent, so an upgraded volume would otherwise keep an obsolete startup script.
- **Keep `root/defaults/autostart` POSIX `sh`.** `openbox-autostart` runs it as `sh $AUTOSTART` (dash on Debian) whatever its shebang says, and a single bashism (`<<<`, `[[ ]]`, arrays, `local`) makes dash reject the whole file before Ashigaru launches. Check it with `dash -n` and `shellcheck -s sh`, and test it by running it with `sh`.
- **Keep `--dir` on the launch command.** Java takes its default home from the passwd entry, not `$HOME`; without `--dir`, wallets could land outside the backed-up volume.
- **Don't loosen the Selkies hardening env** (`DISABLE_OPEN_TOOLS`, `DISABLE_SUDO`, `DISABLE_TERMINALS`, `SELKIES_COMMAND_ENABLED=false`, the sidebar flags): it keeps the webtop from being a shell on the box. File transfers stay on for wallet exports. Links don't need `xdg-open`: JavaFX opens them through GIO, which runs `ashigaru-open-link` via `/etc/xdg/mimeapps.list`. Don't name that script `xdg-open`, or `DISABLE_OPEN_TOOLS` will `chmod 0000` it.
- **Size the main window with the autostart's fit loop, not Openbox maximise.** JavaFX pins the main window's size hints while any modal dialog is open, which blocks or undoes maximising. The Dockerfile removes the base image's catch-all maximise rule so dialogs keep their own size.
- **Keep `fonts-noto-core` and `xcompmgr`.** The first is the only source of the copy and lock glyphs. Without the second, JavaFX popups get a white margin.
- **Keep `.github/workflows/` as Start9's standard thin callers.** They match `hello-world-startos` except for the base branch, `main`; build changes belong in the Makefile, not the workflows. **Temporary exception:** `build.yml` is a copy of upstream's build job pinned to `ubuntu-24.04`, because upstream's `setup-build-env` fails on Ubuntu 26.04 (`qemu-user-static`). Restore the thin caller (quoted at the top of the file) once upstream builds again.
- **Never ship the desktop without a password.** `main.ts` throws when `store.json` has none; it is a hot wallet on the LAN and Tor.
