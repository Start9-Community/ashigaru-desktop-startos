# Updating the upstream version

This package wraps the Ashigaru Desktop Linux release from `linkinparkrulz/ashigaru-desktop`. It installs the upstream `Ashigaru-<version>-x86_64.tar.gz` into a LinuxServer Selkies webtop image. The tarball is checked against the release's `SHA256SUMS`, which is pinned by its own hash.

## Determining the upstream version

- **Ashigaru Desktop** (`linkinparkrulz/ashigaru-desktop`, https://github.com/linkinparkrulz/ashigaru-desktop):

  ```
  gh release view -R linkinparkrulz/ashigaru-desktop --json tagName -q .tagName
  ```

  Pinned as `ASHIGARU_VERSION` in `Dockerfile` (the tag is `v<version>`; the pin omits the `v`).

## Applying the bump

- **Ashigaru Desktop**:
  1. Download the new release's `SHA256SUMS`, `MESSAGE.txt` and `RELEASE-BIP47-SIGNATURE.txt`.
  2. Verify the signature as the upstream README describes (**Tools → Verifier** in Ashigaru, or paymentcode.io/lab with the release signing payment code). The recovered signer must be `1K8CDoBYWBuaeAhejLAk5hiACAgbbPnDCJ`.
  3. Run `sha256sum SHA256SUMS` and confirm it matches the `SHA256(SHA256SUMS):` line in `MESSAGE.txt`.
  4. Set `ARG ASHIGARU_VERSION` and `ARG ASHIGARU_SUMS_SHA256` in `Dockerfile` to the new version and that hash.
  5. Add a `startos/versions/` entry for `<version>:0`.

  The build re-checks the hash against `MESSAGE.txt` and the tarball against `SHA256SUMS`, so a skipped step fails the build rather than shipping an unverified binary.

- **Selkies base image**: `Dockerfile` pins `ghcr.io/linuxserver/baseimage-selkies:debiantrixie` by release tag and digest, the same pin Start9's Bisq package uses. Verify the current tag with:

  ```
  docker buildx imagetools inspect ghcr.io/linuxserver/baseimage-selkies:debiantrixie
  ```

  When updating the base, pick the newest stable Debian Trixie release (skip `dev` tags) and replace both the tag and digest in the `FROM` line. Keep the flattened image's `ENV` block in sync with the base image's runtime environment, keeping `START_DOCKER=false`. Increment the StartOS downstream revision while keeping the Ashigaru version unchanged.
