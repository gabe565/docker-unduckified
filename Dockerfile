FROM --platform=$BUILDPLATFORM oven/bun:1-alpine AS src
WORKDIR /app

ARG UNDUCKIFIED_REPO=taciturnaxolotl/unduckified
ARG UNDUCKIFIED_REF=v0.4.0

RUN <<EOT
  set -eux

  wget -O- "https://github.com/$UNDUCKIFIED_REPO/archive/$UNDUCKIFIED_REF.tar.gz" | tar -xz --strip-components=1

  bun install --frozen-lockfile
  bun run build

  # The build brotli-compresses dist/bangs.bin in place because Cloudflare Pages
  # serves it with a fixed Content-Encoding: br (see upstream public/_headers).
  # Keep that body, and restore a plain one beside it, so nginx can pick one per
  # request based on Accept-Encoding.
  mv dist/bangs.bin dist/bangs.bin.br
  apk add --no-cache brotli
  brotli --decompress --output=dist/bangs.bin dist/bangs.bin.br

  # Remove Cloudflare Pages config
  rm dist/_headers dist/_routes.json
EOT

COPY suggest-server.ts ./
RUN bun build --target=bun --minify --outfile=suggest.js suggest-server.ts


FROM --platform=$BUILDPLATFORM alpine:3 AS s6
ARG TARGETARCH
# renovate: datasource=github-releases depName=just-containers/s6-overlay
ARG S6_OVERLAY_VERSION=3.2.3.2

RUN <<EOT
  set -eux

  case "$TARGETARCH" in
    amd64) s6_arch=x86_64 ;;
    arm64) s6_arch=aarch64 ;;
    *) echo "no s6-overlay mapping for TARGETARCH=$TARGETARCH" >&2; exit 1 ;;
  esac

  apk add --no-cache xz

  mkdir -p /s6
  cd /tmp
  base="https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION"
  for tarball in "s6-overlay-noarch" "s6-overlay-$s6_arch"; do
    wget -q "$base/$tarball.tar.xz" "$base/$tarball.tar.xz.sha256"
    sha256sum -c "$tarball.tar.xz.sha256"
    xz -dc "$tarball.tar.xz" | tar -x -C /s6
  done
EOT


FROM oven/bun:1-alpine
WORKDIR /app

RUN apk add --no-cache nginx
RUN chown bun:root /run
RUN chmod 0755 /run

COPY --from=s6 /s6/ /
COPY s6/ /etc/s6-overlay/
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=src /app/suggest.js ./suggest.js
COPY --from=src /app/dist ./html

USER 1000

ENTRYPOINT ["/init"]
