# Updating the upstream version

This package wraps the Ashigaru Desktop Linux release from `linkinparkrulz/ashigaru-desktop`. It installs the upstream `Ashigaru-<version>-x86_64.AppImage` (Linux releases ship only as an AppImage from 1.5.0) into a LinuxServer Selkies webtop image. The AppImage is checked against the release's `SHA256SUMS`, which is pinned by its own hash, then unpacked with `--appimage-extract`.

## Determining the upstream version

- **Ashigaru Desktop** (`linkinparkrulz/ashigaru-desktop`, https://github.com/linkinparkrulz/ashigaru-desktop):

  ```
  gh release view -R linkinparkrulz/ashigaru-desktop --json tagName -q .tagName
  ```

  Pinned as `ASHIGARU_VERSION` in `Dockerfile` (the tag is `v<version>`; the pin omits the `v`).

## Automated bump

The **Upstream watch** workflow (`.github/workflows/upstream-watch.yml`) runs daily and on demand. When the latest published upstream release is newer than `ASHIGARU_VERSION`, `.github/scripts/upstream_bump.py` verifies the chain below before writing anything, then opens a pull request from `upstream/v<version>`. It never merges, tags or publishes.

- `RELEASE-BIP47-SIGNATURE.txt` carries `MESSAGE.txt` exactly and recovers to `1K8CDoBYWBuaeAhejLAk5hiACAgbbPnDCJ`.
- `MESSAGE.txt` names the upstream repository and the release's version and tag.
- `SHA256(SHA256SUMS)` matches the downloaded `SHA256SUMS`, which lists the AppImage.

The pull request sets `ASHIGARU_VERSION`, `ASHIGARU_SUMS_SHA256` and the version in `startos/versions/current.ts`. Its release notes are a placeholder: rewrite them from the upstream notes quoted in the pull request before merging. It refuses to bump while `current.ts` carries a migration. A pull request opened with the default token doesn't start **Build**: save a fine-grained token for this repository (Contents and Pull requests: read and write) as the `UPSTREAM_BOT_TOKEN` secret, or run Build on the branch by hand.

## Applying the bump

- **Ashigaru Desktop**:
  1. Download the new release's `SHA256SUMS`, `MESSAGE.txt` and `RELEASE-BIP47-SIGNATURE.txt`.
  2. Verify the signature as the upstream README describes (**Tools → Verifier** in Ashigaru, or paymentcode.io/lab with the release signing payment code). The recovered signer must be `1K8CDoBYWBuaeAhejLAk5hiACAgbbPnDCJ`.
  3. Run `sha256sum SHA256SUMS` and confirm it matches the `SHA256(SHA256SUMS):` line in `MESSAGE.txt`.
  4. Set `ARG ASHIGARU_VERSION` and `ARG ASHIGARU_SUMS_SHA256` in `Dockerfile` to the new version and that hash.

  The build re-checks the hash against `MESSAGE.txt` and the AppImage against `SHA256SUMS`, so a skipped step fails the build rather than shipping an unverified binary. The build downloads from the public release URL, so it fails while the upstream release is still a draft.

- **Selkies base image**: `Dockerfile` pins `ghcr.io/linuxserver/baseimage-selkies:debiantrixie` by release tag and digest, the same pin Start9's Bisq package uses. Verify the current tag with:

  ```
  docker buildx imagetools inspect ghcr.io/linuxserver/baseimage-selkies:debiantrixie
  ```

  When updating the base, pick the newest stable Debian Trixie release (skip `dev` tags) and replace both the tag and digest in the `FROM` line. Keep the flattened image's `ENV` block in sync with the base image's runtime environment, keeping `START_DOCKER=false`.
