# Stage 1: fetch and verify the Ashigaru Linux release
FROM debian:trixie-slim AS ashigaru-fetch

ARG ASHIGARU_VERSION=1.4.5
# SHA256 of the release's SHA256SUMS file, as attested in its MESSAGE.txt and
# covered by RELEASE-BIP47-SIGNATURE.txt. Pinning it here means a re-uploaded
# SHA256SUMS or tarball fails the build instead of being trusted.
ARG ASHIGARU_SUMS_SHA256=dcdc1db1d31253149ebba15f214c8db7c6551e45f411b07df963264292ef5245

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/ashigaru
RUN base="https://github.com/linkinparkrulz/ashigaru-desktop/releases/download/v${ASHIGARU_VERSION}" && \
    tarball="Ashigaru-${ASHIGARU_VERSION}-x86_64.tar.gz" && \
    curl -fsSLO "${base}/SHA256SUMS" && \
    curl -fsSLO "${base}/MESSAGE.txt" && \
    curl -fsSLO "${base}/${tarball}" && \
    echo "${ASHIGARU_SUMS_SHA256}  SHA256SUMS" | sha256sum -c - && \
    grep -qx "SHA256(SHA256SUMS): ${ASHIGARU_SUMS_SHA256}" MESSAGE.txt && \
    grep " ${tarball}\$" SHA256SUMS | sha256sum -c - && \
    mkdir -p /opt && \
    tar -xzf "${tarball}" -C /opt && \
    test -x /opt/Ashigaru/bin/Ashigaru

# Stage 2: Selkies webtop with bloat removed
FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie-3900c0f0-ls140@sha256:c3f25149cf58957fcc4259904b02cf88b1e51fc8df2f9946bc64650701e527e7 AS buildstage

# GTK3 and X11 libraries for JavaFX, jq to seed Ashigaru's config
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
      jq && \
    # Remove large unused packages from base image
    DEBIAN_FRONTEND=noninteractive \
    apt-get remove --purge --autoremove -y \
      containerd.io \
      docker-ce \
      docker-ce-cli \
      docker-buildx-plugin \
      docker-compose-plugin \
      fonts-noto-color-emoji \
      fonts-noto-core \
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
