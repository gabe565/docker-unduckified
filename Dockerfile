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

FROM nginxinc/nginx-unprivileged:stable-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=src /app/dist /usr/share/nginx/html
