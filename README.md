<p align="center">
  <img src="icon.png" alt="Ashigaru Logo" width="21%">
</p>

# Ashigaru Desktop on StartOS

> Everything not listed in this document should behave the same as upstream
> Ashigaru Desktop. If a feature, setting, or behavior is not mentioned here,
> the upstream documentation is accurate and fully applicable — see the
> Documentation section of `instructions.md` for links.

[Ashigaru Desktop](https://github.com/linkinparkrulz/ashigaru-desktop) is a Bitcoin wallet and Whirlpool coinjoin client, forked from Sparrow and maintained independently as a companion to Ashigaru Terminal and Ashigaru Mobile. It is a JavaFX **desktop** application, so this package runs it inside a browser-accessible Linux desktop rather than serving a web app.

- **Upstream repo:** <https://github.com/linkinparkrulz/ashigaru-desktop>
- **Wrapper repo:** <https://github.com/Start9-Community/ashigaru-desktop-startos>

---

## Table of Contents

- [Image and Container Runtime](#image-and-container-runtime)
- [Volume and Data Layout](#volume-and-data-layout)
- [File Models](#file-models)
- [Dependencies](#dependencies)
- [Network Access and Interfaces](#network-access-and-interfaces)
- [Installation and First-Run Flow](#installation-and-first-run-flow)
- [Actions](#actions)
- [Tasks](#tasks)
- [Health Checks](#health-checks)
- [Backups and Restore](#backups-and-restore)
- [Limitations and Differences](#limitations-and-differences)
- [Quick Reference for AI Consumers](#quick-reference-for-ai-consumers)

---

## Image and Container Runtime

One image, built here in three stages:

1. A Debian builder downloads the upstream x86_64 AppImage, the only Linux build upstream publishes, and verifies it. It checks the hash of `SHA256SUMS` against a value pinned in the Dockerfile and against `MESSAGE.txt`, then the AppImage against `SHA256SUMS`. Only then does it run the AppImage's `--appimage-extract` and move the jpackage image inside it to `/opt/Ashigaru`.
2. A digest-pinned LinuxServer Selkies webtop supplies the desktop. Its catch-all Openbox rule that maximises every window is removed (see [Window sizing](#window-sizing)).
3. A `FROM scratch` flatten collapses the result into a single layer.

| Property      | Value                                                             |
| ------------- | ----------------------------------------------------------------- |
| Image         | Built from this repo's `Dockerfile`                               |
| Architectures | x86_64 only                                                       |
| Entrypoint    | The base image's `/init`, via `sdk.useEntrypoint()` + `runAsInit` |
| Memory        | Ashigaru's JVM heap is capped at 1 GiB by the upstream launcher   |
| StartOS       | At least the manifest's `osVersion`, which start-sdk sets         |

| Subcontainer   | Purpose                          |
| -------------- | -------------------------------- |
| `ashigaru-sub` | The desktop daemon — attach here |

The stack is `browser → Selkies (port 3000) → Openbox → Ashigaru`. `root/defaults/startwm.sh` copies the package-owned autostart hook over the persisted Openbox one on every launch. That hook, run by `openbox-autostart` with `sh` (dash) and so kept POSIX, seeds Ashigaru's config, starts `xcompmgr` and the window-fit loop, and launches Ashigaru in a loop, so quitting the app relaunches it.

### Window sizing

Selkies resizes the X display to the browser. Ashigaru's main window is resizable, but Openbox maximising does not stick to it: while a modal dialog is open, JavaFX pins the main window's size hints to its unmaximised size, so the first-run tour blocks the maximise and every later dialog undoes it. Instead, the autostart hook checks every two seconds and resizes the main window to the screen minus its frame, skipping while a dialog pins it. It finds the main window by its `Ashigaru Desktop <version>` title and a minimum-size hint above 1×1, because the splash screen shares the title but sets no minimum size. Dialogs keep their own size.

### Fonts

Ashigaru draws its UI in its own bundled typefaces and falls back to system fonts for symbols. DejaVu Sans covers all of them except the copy (`⎘` U+2398) and lock (`🔒` U+1F512) glyphs, which come from Noto Sans Symbols and Symbols2 in `fonts-noto-core`. The colour emoji font is removed: JavaFX cannot draw it, and fontconfig would otherwise choose it for the lock.

### Popups

JavaFX dropdowns and autocomplete lists are transparent windows with a drop shadow. Without a compositor, the transparent margin paints solid white, so the autostart hook runs `xcompmgr -n`.

### Links

JavaFX opens links (block explorer, exposure check) through GIO, which runs the default `x-scheme-handler/http(s)` handler. `/etc/xdg/mimeapps.list` points both at `ashigaru-link.desktop`, which runs `/usr/local/bin/ashigaru-open-link`. There is no browser in the container, and Selkies cannot open a page in the viewer's browser. The script therefore copies the link to the X clipboard, which Selkies' seamless clipboard carries to the browser, and shows it in a `yad` dialog. It refuses anything that isn't `http(s)://`. `xdg-open` itself stays disabled by `DISABLE_OPEN_TOOLS`.

### Stream quality

Selkies streams H.264 by default at CRF 25 with 4:2:0 chroma, which blurs Ashigaru's small coloured text. The package sets `SELKIES_VIDEO_FULLCOLOR=true` (4:4:4) and `SELKIES_VIDEO_CRF=18,5-50` (starts at 18, adjustable from the Selkies sidebar). Paint-over for static screens stays on at its defaults.

**The desktop is locked down.** Passwordless sudo, terminals, the remote command channel, external open helpers and the applications sidebar are disabled through the base image's environment. File upload and download stay on for wallet exports and BIP-329 labels.

**Older StartOS fails at install, not with a version error.** The SDK sends an HTTP binding's `addSsl.alpn` as a plain list (`['http/1.1']`). StartOS releases older than the manifest's `osVersion` expect the earlier `'reflect'` / `{ specified: [...] }` form, and don't enforce `osVersion` on a sideload. On those, install fails in `persistent_container::init` with `Invalid params: Deserialization Error: invalid type: sequence, expected string or map@bind`. The fix is to update StartOS.

## Volume and Data Layout

Everything the package keeps lives on one volume, mounted as the desktop user's home.

| Volume | Mount Point | Purpose                                        |
| ------ | ----------- | ---------------------------------------------- |
| `main` | `/config`   | Webtop home, Ashigaru's data dir, `store.json` |

| Path                 | Holds                                                  |
| -------------------- | ------------------------------------------------------ |
| `store.json`         | Package state: the desktop password                    |
| `.ashigaru/`         | Ashigaru's home (`--dir`): wallets, config, Tor, logs  |
| `.ashigaru/config`   | Ashigaru's mainnet config; `updateCheckConsent` seeded |
| `.ashigaru/wallets/` | Wallet files                                           |

## File Models

| File               | Format | Modelled                | Written by                                 |
| ------------------ | ------ | ----------------------- | ------------------------------------------ |
| `store.json`       | JSON   | Yes — `FileHelper.json` | Init and Set Desktop Password              |
| `.ashigaru/config` | JSON   | No                      | Ashigaru; the autostart hook seeds one key |

`store.json` holds only `PASSWORD`, passed to Selkies as the desktop credential. The username is fixed as `ashigaru`. It is read through `.const()`, so rotating it re-runs `main`.

The autostart hook sets `updateCheckConsent` to `false` in Ashigaru's config when the key is absent. The in-app updater cannot replace the image, so updates come through StartOS instead. A user who explicitly turns the check on keeps that choice.

## Dependencies

None. Ashigaru connects to the Bitcoin network itself, through public Electrum servers, Dojo Bay, or a server the user enters in **Settings → Server**, all over its own built-in Tor.

## Network Access and Interfaces

The package exposes one interface, and what it serves is a remote desktop rather than a web application.

| Interface        | Id   | Type | Port | Description                                       |
| ---------------- | ---- | ---- | ---- | ------------------------------------------------- |
| Ashigaru Desktop | `ui` | ui   | 3000 | The Ashigaru application, streamed to the browser |

Bound on the `ui-multi` MultiHost over HTTP and not masked. Selkies itself password-protects it with the credential in `store.json`. That login is what stands between anyone who can reach the address and the wallet.

Ashigaru's outbound connections, including Whirlpool and Tor, are made by Ashigaru and are unaffected by how this interface is reached.

## Installation and First-Run Flow

Install seeds an empty `store.json`, so init raises a `critical` task to set the desktop password. There is no default credential. `main` throws if no password is stored, so the desktop cannot start without one.

## Actions

One action, for the desktop login. Ashigaru's own settings live in its UI.

### Set Desktop Password

Run it to set the first password, or to replace a lost or exposed one.

- **What it changes:** `PASSWORD` in `store.json`.
- **Cost:** the write re-runs `main`, so the desktop and Ashigaru restart. Ashigaru does not reopen wallets on launch, so an active mix stops until the user opens the wallet again.
- **Repeat safety:** safe to run again; each run makes a new password and the old one stops working.
- **Outputs:** the username (`ashigaru`) and the new password.

## Tasks

One task, raised so the desktop is never reachable without a password.

| Task                      | Severity   | Raised when                    | Cleared when              |
| ------------------------- | ---------- | ------------------------------ | ------------------------- |
| Set your desktop password | `critical` | `store.json` holds no password | Set Desktop Password runs |

Init checks on every container start, so the task returns only if `store.json` loses its password. A restore brings the password back with the backup and raises nothing.

## Health Checks

One check, on the desktop stream.

| Check     | Displayed as       | Method                 |
| --------- | ------------------ | ---------------------- |
| `primary` | "Ashigaru Desktop" | Port 3000 is listening |

The check reports whether Selkies is serving, not whether Ashigaru has finished starting or is connected. A green check with a briefly empty desktop is normal while the JVM starts. A failing check means Selkies is not listening: the desktop stack failed to start, so the service log is the place to look.

## Backups and Restore

`sdk.Backups.ofVolumes('main')` copies the whole volume: Ashigaru's wallets, config, Tor state and `store.json`. **The backup contains the wallet.** A restore brings back a working instance with the same desktop password.

## Limitations and Differences

1. **x86_64 only.** Upstream publishes a Linux build for x86_64 only.
2. **A desktop application in a browser.** Latency, clipboard and window behavior are Selkies', not Ashigaru's. Links cannot open in the viewer's browser directly; they are copied and shown instead.
3. **The in-app updater is off by default.** Turning it on downloads releases but cannot install them into the image.
4. **Mixing stops on every restart.** Ashigaru does not reopen wallets when it launches, so after a server reboot, a service update or a password change, mixing resumes only once the user opens the wallet again.
5. **No StartOS dependency wiring yet.** Using a node on the same server means typing its Electrum address into Ashigaru by hand.

---

## Quick Reference for AI Consumers

```yaml
package_id: ashigaru-desktop
image: built from ./Dockerfile # debian fetch+verify stage + linuxserver selkies webtop, flattened
architectures:
  - x86_64
subcontainers:
  - ashigaru-sub
volumes:
  main: /config
file_models:
  - store.json
startos_managed_env_vars:
  - CUSTOM_USER
  - PASSWORD
  - PUID
  - PGID
  - TZ
  - TITLE
  - S6_CMD_WAIT_FOR_SERVICES_MAXTIME
  - S6_VERBOSITY
  - NO_DECOR
  - DISABLE_OPEN_TOOLS
  - DISABLE_SUDO
  - DISABLE_TERMINALS
  - SELKIES_COMMAND_ENABLED
  - SELKIES_UI_SIDEBAR_SHOW_APPS
  - SELKIES_UI_SIDEBAR_SHOW_FILES
  - SELKIES_FILE_TRANSFERS
  - SELKIES_VIDEO_FULLCOLOR
  - SELKIES_VIDEO_CRF
dependencies: none
interfaces:
  ui: { type: ui, port: 3000 }
actions:
  - set-password
tasks:
  - { action: set-password, severity: critical }
health_checks:
  - primary # displayed "Ashigaru Desktop"
```
