<p align="center">
  <img src="icon.png" alt="Ashigaru Logo" width="21%">
</p>

# Ashigaru Desktop on StartOS

> Everything not listed in this document should behave the same as upstream
> Ashigaru Desktop. If a feature, setting, or behavior is not mentioned here,
> the upstream documentation is accurate and fully applicable — see the
> Documentation section of `instructions.md` for links.

[Ashigaru Desktop](https://github.com/linkinparkrulz/ashigaru-desktop) is a Bitcoin wallet and Whirlpool coinjoin client, forked from Sparrow. It is a JavaFX **desktop** application, so this package runs it inside a browser-accessible Linux desktop rather than serving a web app.

- **Upstream repo:** <https://github.com/linkinparkrulz/ashigaru-desktop>
- **Wrapper repo:** <https://github.com/linkinparkrulz/ashigaru-desktop-startos>

---

## Building

- **Locally:** `npm ci && make` with Docker and `start-cli` installed. Produces `ashigaru-desktop_x86_64.s9pk`.
- **CI:** the **Build** workflow runs on pull requests into `main` and on demand from the Actions tab. It uploads the `.s9pk` as a workflow artifact, kept for 14 days, and is signed with a throwaway key.
- **Releases:** pushing a tag `v<version>` (e.g. `v1.5.0_0` for `1.5.0:0`) runs the **Release** workflow. It builds the package signed with the `DEV_KEY` secret and attaches the `.s9pk` and its SHA256 to a GitHub Release.

Both workflows are Start9's standard thin callers of the reusable workflows in `Start9Labs/start-technologies`. No Start9 registry or S3 is configured, so publishing stops at the GitHub Release.

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
| StartOS       | 0.4.0.2 or later (`osVersion` set by start-sdk 3.x)               |

| Subcontainer   | Purpose                          |
| -------------- | -------------------------------- |
| `ashigaru-sub` | The desktop daemon — attach here |

The stack is `browser → Selkies (port 3000) → Openbox → Ashigaru`. `root/defaults/startwm.sh` copies the package-owned autostart hook over the persisted Openbox one on every launch. That hook, run by `openbox-autostart` with `sh` (dash) and so kept POSIX, seeds Ashigaru's config, starts `xcompmgr` and the window-fit loop, and launches Ashigaru in a loop, so quitting the app relaunches it.

### Window sizing

Selkies resizes the X display to the browser. Ashigaru's main window is resizable from 1.5.0, but Openbox maximising does not stick to it: while a modal dialog is open, JavaFX pins the main window's size hints to its unmaximised size, so the first-run tour blocks the maximise and every later dialog undoes it. Instead, the autostart hook checks every two seconds and resizes the main window to the screen minus its frame, skipping while a dialog pins it. It finds the main window by its `Ashigaru Desktop <version>` title and a minimum-size hint above 1×1, because the splash screen shares the title but sets no minimum size. Dialogs keep their own size.

### Fonts

Ashigaru draws its UI in its own bundled typefaces and falls back to system fonts for symbols. DejaVu Sans covers all of them except the copy (`⎘` U+2398) and lock (`🔒` U+1F512) glyphs, which come from Noto Sans Symbols and Symbols2 in `fonts-noto-core`. The colour emoji font is removed: JavaFX cannot draw it, and fontconfig would otherwise choose it for the lock.

### Popups

JavaFX dropdowns and autocomplete lists are transparent windows with a drop shadow. Without a compositor, the transparent margin paints solid white, so the autostart hook runs `xcompmgr -n`.

### Links

JavaFX opens links (block explorer, exposure check) through GIO, which runs the default `x-scheme-handler/http(s)` handler. `/etc/xdg/mimeapps.list` points both at `ashigaru-link.desktop`, which runs `/usr/local/bin/ashigaru-open-link`. There is no browser in the container, and Selkies cannot open a page in the viewer's browser. The script therefore copies the link to the X clipboard, which Selkies' seamless clipboard carries to the browser, and shows it in a `yad` dialog. It refuses anything that isn't `http(s)://`. `xdg-open` itself stays disabled by `DISABLE_OPEN_TOOLS`.

### Stream quality

Selkies streams H.264 by default at CRF 25 with 4:2:0 chroma, which blurs Ashigaru's small coloured text. The package sets `SELKIES_VIDEO_FULLCOLOR=true` (4:4:4) and `SELKIES_VIDEO_CRF=18,5-50` (starts at 18, adjustable from the Selkies sidebar). Paint-over for static screens stays on at its defaults.

**The desktop is locked down.** Passwordless sudo, terminals, the remote command channel, external open helpers and the applications sidebar are disabled through the base image's environment. File upload and download stay on for wallet exports and BIP-329 labels.

**Older StartOS fails at install, not with a version error.** start-sdk 3.x sends an HTTP binding's `addSsl.alpn` as a plain list (`['http/1.1']`). StartOS accepts that only from 0.4.0.2; 0.4.0 and 0.4.0.1 expect the older `'reflect'` / `{ specified: [...] }` form. A sideload on those releases doesn't enforce the manifest's `osVersion`, so it fails in `persistent_container::init` with `Invalid params: Deserialization Error: invalid type: sequence, expected string or map@bind`. The fix is to update StartOS.

## Volume and Data Layout

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

| Interface        | Id   | Type | Port | Description                                       |
| ---------------- | ---- | ---- | ---- | ------------------------------------------------- |
| Ashigaru Desktop | `ui` | ui   | 3000 | The Ashigaru application, streamed to the browser |

Bound on the `ui-multi` MultiHost over HTTP and not masked. Selkies itself password-protects it with the credential in `store.json`. That login is what stands between anyone who can reach the address and the wallet.

Ashigaru's outbound connections, including Whirlpool and Tor, are made by Ashigaru and are unaffected by how this interface is reached.

## Installation and First-Run Flow

Install seeds an empty `store.json` and raises a `critical` task to set the desktop password. There is no default credential. `main` throws if no password is stored, so the desktop cannot start without one.

## Actions

### Set Desktop Password

Generates a new random password for the desktop login and shows it with the username. Available at any status. When a password already exists, it asks for confirmation first.

- **What it changes:** `PASSWORD` in `store.json`.
- **Cost:** the write re-runs `main`, so the desktop and Ashigaru restart. An active mix is interrupted and resumes when Ashigaru reopens the wallet.
- **Outputs:** the username (`ashigaru`) and the new password.

## Tasks

| Task                      | Severity   | Raised when | Cleared when              |
| ------------------------- | ---------- | ----------- | ------------------------- |
| Set your desktop password | `critical` | At install  | Set Desktop Password runs |

Raised on install only, so a restore does not re-prompt for a password that came back with the backup.

## Health Checks

| Check     | Displayed as       | Method                 |
| --------- | ------------------ | ---------------------- |
| `primary` | "Ashigaru Desktop" | Port 3000 is listening |

The check reports whether Selkies is serving, not whether Ashigaru has finished starting or is connected. A green check with a briefly empty desktop is normal while the JVM starts.

## Backups and Restore

`sdk.Backups.ofVolumes('main')` copies the whole volume: Ashigaru's wallets, config, Tor state and `store.json`. **The backup contains the wallet.** A restore brings back a working instance with the same desktop password.

## Limitations and Differences

1. **x86_64 only.** Upstream publishes a Linux build for x86_64 only.
2. **A desktop application in a browser.** Latency, clipboard and window behavior are Selkies', not Ashigaru's. Links cannot open in the viewer's browser directly; they are copied and shown instead.
3. **The in-app updater is off by default.** Turning it on downloads releases but cannot install them into the image.
4. **No StartOS dependency wiring yet.** Using a node on the same server means typing its Electrum address into Ashigaru by hand.

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
min_startos: 0.4.0.2
dependencies: []
interfaces:
  ui: { type: ui, port: 3000 }
actions:
  - set-password
tasks:
  - { action: set-password, severity: critical }
health_checks:
  - primary # displayed "Ashigaru Desktop"
```
