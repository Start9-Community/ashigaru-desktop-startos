# syntax=docker/dockerfile:1
# Stage 1: fetch and verify the Ashigaru Linux release
FROM debian:trixie-slim AS ashigaru-fetch

ARG ASHIGARU_VERSION=1.5.1
# SHA256 of the release's SHA256SUMS file, as attested in its MESSAGE.txt and
# covered by RELEASE-BIP47-SIGNATURE.txt. Pinning it here means a re-uploaded
# SHA256SUMS or AppImage fails the build instead of being trusted.
ARG ASHIGARU_SUMS_SHA256=d29150ece65bf878a0e4ae5b08d66342d5ea16c76b672b165000f79e2e13f225
# Notification address of linkinparkrulz's release-signing BIP47 payment code
# PM8TJM51x2mDd85CzEgVc2y7vdyB3eBj93JVjVtCt6PZtmfzhFzYPMXYBXh28zthWhVKGjVQZPT1MKxGxEtfenLYEkuc5GhoWtMzQCF8c8mrckYFM7r1
ARG ASHIGARU_SIGNER=1K8CDoBYWBuaeAhejLAk5hiACAgbbPnDCJ

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl python3-ecdsa && \
    rm -rf /var/lib/apt/lists/*

# Checks a Bitcoin signed-message block against MESSAGE.txt and requires its
# recovered signer to be the pinned P2PKH address.
COPY <<'VERIFY' /usr/local/bin/verify-signed-message
import base64, hashlib, sys
from ecdsa import SECP256k1, VerifyingKey
from ecdsa.util import sigdecode_string

address, block_path, message_path = sys.argv[1:4]
head, sep, rest = open(block_path).read().partition(
    '\n-----BEGIN BITCOIN SIGNATURE-----\n')
begin = '-----BEGIN BITCOIN SIGNED MESSAGE-----\n'
if not sep or not head.startswith(begin):
    sys.exit('malformed signature block')
message = head[len(begin):]
fields = [l for l in rest.split('\n') if l and not l.startswith('Version:')]
if fields[0] != f'Address: {address}' or fields[-1] != '-----END BITCOIN SIGNATURE-----':
    sys.exit(f'signature block names {fields[0]!r}, expected {address}')
if open(message_path).read() != message + '\n':
    sys.exit('signed message differs from MESSAGE.txt')
sig = base64.b64decode(fields[1], validate=True)
if len(sig) != 65 or not 27 <= sig[0] <= 34:
    sys.exit('unsupported signature encoding')

def sha256d(b):
    return hashlib.sha256(hashlib.sha256(b).digest()).digest()

def p2pkh(pubkey):
    payload = b'\0' + hashlib.new('ripemd160', hashlib.sha256(pubkey).digest()).digest()
    n = int.from_bytes(payload + sha256d(payload)[:4], 'big')
    alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
    out = ''
    while n:
        n, r = divmod(n, 58)
        out = alphabet[r] + out
    return '1' + out

magic, msg = b'Bitcoin Signed Message:\n', message.encode()
if len(msg) >= 0xfd:
    sys.exit('message too long')
digest = sha256d(bytes([len(magic)]) + magic + bytes([len(msg)]) + msg)
encoding = 'compressed' if sig[0] >= 31 else 'uncompressed'
for key in VerifyingKey.from_public_key_recovery_with_digest(
        sig[1:], digest, SECP256k1, sigdecode=sigdecode_string):
    if p2pkh(key.to_string(encoding)) == address:
        key.verify_digest(sig[1:], digest, sigdecode=sigdecode_string)
        print(f'Good signature from {address}')
        sys.exit(0)
sys.exit(f'signature does not recover to {address}')
VERIFY

WORKDIR /tmp/ashigaru
# Linux releases ship only as an AppImage. Its runtime unpacks itself without
# FUSE, and runs only once the signature and checksums have passed. usr/ holds the jpackage
# image, so the launcher lands at /opt/Ashigaru/bin/Ashigaru.
RUN base="https://github.com/linkinparkrulz/ashigaru-desktop/releases/download/v${ASHIGARU_VERSION}" && \
    appimage="Ashigaru-${ASHIGARU_VERSION}-x86_64.AppImage" && \
    curl -fsSLO "${base}/SHA256SUMS" && \
    curl -fsSLO "${base}/MESSAGE.txt" && \
    curl -fsSLO "${base}/RELEASE-BIP47-SIGNATURE.txt" && \
    curl -fsSLO "${base}/${appimage}" && \
    python3 -I /usr/local/bin/verify-signed-message "${ASHIGARU_SIGNER}" RELEASE-BIP47-SIGNATURE.txt MESSAGE.txt && \
    grep -qx "Tag: v${ASHIGARU_VERSION}" MESSAGE.txt && \
    echo "${ASHIGARU_SUMS_SHA256}  SHA256SUMS" | sha256sum -c - && \
    grep -qx "SHA256(SHA256SUMS): ${ASHIGARU_SUMS_SHA256}" MESSAGE.txt && \
    grep " ${appimage}\$" SHA256SUMS | sha256sum -c - && \
    chmod +x "${appimage}" && \
    "./${appimage}" --appimage-extract > /dev/null && \
    mkdir -p /opt && \
    mv squashfs-root/usr /opt/Ashigaru && \
    test -x /opt/Ashigaru/bin/Ashigaru

# Stage 2: Selkies webtop with bloat removed
FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie-3900c0f0-ls140@sha256:c3f25149cf58957fcc4259904b02cf88b1e51fc8df2f9946bc64650701e527e7 AS buildstage

# GTK3 and X11 libraries for JavaFX, jq to seed Ashigaru's config, xcompmgr
# so JavaFX popups are not drawn with a white margin, wmctrl to fit the main
# window to the screen, and yad for the dialog that hands links to the browser.
# fonts-noto-core stays: Noto Sans Symbols/Symbols2 are the only fonts here
# with the copy (U+2398) and lock (U+1F512) glyphs Ashigaru's buttons use.
# The colour emoji font goes, since JavaFX cannot draw it and fontconfig would
# otherwise pick it for the lock.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
      libgtk-3-0 \
      libgdk-pixbuf-2.0-0 \
      libpango-1.0-0 \
      libcairo2 \
      libatk1.0-0 \
      libatk-bridge2.0-0 \
      libx11-6 \
      libxext6 \
      libxi6 \
      libxtst6 \
      libxrender1 \
      libgl1 \
      libglib2.0-0 \
      libfreetype6 \
      libfontconfig1 \
      libasound2 \
      fonts-dejavu-core \
      x11-xserver-utils \
      xcvt \
      jq \
      xcompmgr \
      wmctrl \
      yad && \
    # Remove large unused packages from base image
    DEBIAN_FRONTEND=noninteractive \
    apt-get remove --purge --autoremove -y \
      containerd.io \
      docker-ce \
      docker-ce-cli \
      docker-buildx-plugin \
      docker-compose-plugin \
      fonts-noto-color-emoji \
      perl \
      locales-all && \
    # Remove unused locales and regenerate default
    rm -rf $(ls -d /usr/share/locale/* | grep -vw /usr/share/locale/en) && \
    localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    # Cleanup
    apt-get autoclean && \
    rm -rf /config/.cache /var/lib/apt/lists/* /var/tmp/* /tmp/*

COPY --from=ashigaru-fetch /opt/Ashigaru /opt/Ashigaru

# Branding
RUN echo "Ashigaru for StartOS is loading ..." > \
      /etc/s6-overlay/s6-rc.d/init-adduser/branding && \
    sed -i '/^run_branding() {$/,/^}$/c\run_branding() { :; }' /docker-mods

# The base image maximises every window, which blows Ashigaru's dialogs up to
# full screen while the main window, pinned by JavaFX while a dialog is open,
# stays small. Drop that rule; the autostart hook fits the main window instead.
# The init script keeps rc.xml.bak from the first start and restores from it,
# so this edit has to be in the image.
RUN grep -q '<application class="\*"><maximized>yes</maximized></application>' /etc/xdg/openbox/rc.xml && \
    sed -i 's|<application class="\*"><maximized>yes</maximized></application>|<application class="*"></application>|' \
      /etc/xdg/openbox/rc.xml && \
    ! grep -q '<maximized>yes</maximized>' /etc/xdg/openbox/rc.xml

# Stage 3: Flatten into a single layer from scratch
FROM scratch

COPY --from=buildstage / .

# Re-set environment variables lost by FROM scratch
ENV \
  HOME="/config" \
  LANGUAGE="en_US.UTF-8" \
  LANG="en_US.UTF-8" \
  TERM="xterm" \
  S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
  S6_VERBOSITY=1 \
  S6_STAGE2_HOOK=/docker-mods \
  VIRTUAL_ENV=/lsiopy \
  PATH="/lsiopy/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
  DISPLAY=:1 \
  PERL5LIB=/usr/local/bin \
  START_DOCKER=false \
  PULSE_RUNTIME_PATH=/defaults \
  SELKIES_INTERPOSER=/usr/lib/selkies_input_interposer.so \
  SELKIES_WEBCAM_INTERPOSER=/usr/lib/selkies_v4l2_interposer.so \
  NVIDIA_DRIVER_CAPABILITIES=all \
  DISABLE_DRI3=false \
  SELKIES_ENCODER="h264enc,h265enc,vp8enc,vp9enc,av1enc,jpeg" \
  SELKIES_ENABLE_BASIC_AUTH=false \
  SELKIES_VIDEO_STREAMING_MODE=false \
  SELKIES_ALLOWED_ORIGINS="*" \
  SELKIES_RATE_CONTROL_MODE="crf,cbr" \
  SHELL=/bin/bash \
  __GL_SYNC_TO_VBLANK=0 \
  TITLE=Selkies

# Add local files
COPY --chmod=755 root/ /

EXPOSE 3000
VOLUME /config

ENTRYPOINT ["/init"]
