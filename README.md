# Unduckified Container Image

<!--renovate repo=taciturnaxolotl/unduckified -->
[![Version](https://img.shields.io/badge/Version-v0.4.0-informational?style=flat)](https://github.com/gabe565/docker-unduckified/pkgs/container/unduckified)
[![Build](https://github.com/gabe565/docker-unduckified/actions/workflows/build.yml/badge.svg)](https://github.com/gabe565/docker-unduckified/actions/workflows/build.yml)

This repo builds Docker images for [taciturnaxolotl/unduckified](https://github.com/taciturnaxolotl/unduckified), a fast, local-first redirection engine for `!bang` searches, so it can be self-hosted instead of using [s.dunkirk.sh](https://s.dunkirk.sh). Upstream ships no build artifacts, so the site is compiled from source with [Bun](https://bun.com) and served by nginx.

The Unduckified version is automatically updated by Renovate bot, so new Unduckified releases will be available within a few hours.

## Images

- [ghcr.io/gabe565/unduckified](https://github.com/gabe565/docker-unduckified/pkgs/container/unduckified)

The image is based on [`nginxinc/nginx-unprivileged`](https://hub.docker.com/r/nginxinc/nginx-unprivileged). Nginx runs as UID `101` and listens on port `8080`. Nothing is written outside `/tmp`, so it also runs with a read-only root filesystem.

## Deployment

### Docker

See the included [`docker-compose.yml`](docker-compose.yml).

## Usage

Add the instance as a custom search engine in your browser:

```
https://unduckified.example.com/?q=%s
```

Browsers that support OpenSearch can discover it instead. The descriptor is rewritten on the fly to point at whichever host served it, so it never sends searches to the public instance. `X-Forwarded-Proto` is honored when the container sits behind a reverse proxy.

**Serve it over HTTPS.** Unduckified resolves bangs in a service worker, and browsers only register those on secure origins. Over plain HTTP the app still works, but every search falls back to loading the page first, which is the slow path it exists to avoid.

## Differences from the hosted instance

Address-bar search suggestions are a Cloudflare Pages Function upstream, which nginx cannot run, so `/suggest` returns 404 here and the address bar offers no completions. Redirects are unaffected: they resolve on device and never touch that endpoint.
