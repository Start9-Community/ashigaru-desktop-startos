# AGENTS.md

This is a StartOS service-package repository — it builds a `.s9pk` for StartOS. The packaging guide is at <https://docs.start9.com/packaging>; start at its recipe index.

Keep `README.md` (technical reference for an AI support or administering agent) and `instructions.md` (end-user docs) in sync with your changes.

## This repo

- **Keep `runAsInit: true`.** The base image is s6-overlay, which must be PID 1; without it nothing in the desktop comes up.
- **Keep `root/defaults/autostart` copied on every launch** (`startwm.sh` does it). Selkies only seeds it when absent, so an upgraded volume would otherwise keep an obsolete startup script.
- **Keep `--dir` on the launch command.** Java takes its default home from the passwd entry, not `$HOME`; without `--dir`, wallets could land outside the backed-up volume.
- **Don't loosen the Selkies hardening env** (`DISABLE_SUDO`, `DISABLE_TERMINALS`, `SELKIES_COMMAND_ENABLED=false`, the sidebar flags): it keeps the webtop from being a shell on the box. File transfers stay on for wallet exports.
- **Don't add a maximise step.** Ashigaru's main window is fixed at 1100 × 800 (`stage.setResizable(false)` upstream), so window managers ignore maximise requests.
- **Never ship the desktop without a password.** `main.ts` throws when `store.json` has none; it is a hot wallet on the LAN and Tor.
