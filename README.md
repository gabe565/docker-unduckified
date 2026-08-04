# Unduckified Container Image

<!--renovate repo=taciturnaxolotl/unduckified -->
[![Version](https://img.shields.io/badge/Version-v0.4.0-informational?style=flat)](https://github.com/gabe565/docker-unduckified/pkgs/container/unduckified)
[![Build](https://github.com/gabe565/docker-unduckified/actions/workflows/build.yml/badge.svg)](https://github.com/gabe565/docker-unduckified/actions/workflows/build.yml)

This repo builds Docker images for [taciturnaxolotl/unduckified](https://github.com/taciturnaxolotl/unduckified), a fast, local-first redirection engine for `!bang` searches, so it can be self-hosted instead of using [s.dunkirk.sh](https://s.dunkirk.sh). Upstream ships no build artifacts, so the site is compiled from source with [Bun](https://bun.com) and served by nginx.

The Unduckified version is automatically updated by Renovate bot, so new Unduckified releases will be available within a few hours.

## Images

- [ghcr.io/gabe565/unduckified](https://github.com/gabe565/docker-unduckified/pkgs/container/unduckified)

The image is built on [`oven/bun`](https://hub.docker.com/r/oven/bun) with nginx installed from Alpine's repositories, and runs everything as UID `1000`, listening on port `8080`. Two processes are supervised by [s6-overlay](https://github.com/just-containers/s6-overlay): nginx, and a Bun process serving [search suggestions](#search-suggestions).

To run with a read-only root filesystem, s6-overlay needs an executable `/run`:

```
docker run --read-only --tmpfs /run:exec,uid=1000,gid=0,mode=0755 --tmpfs /tmp ...
```

## Deployment

### Docker

See the included [`compose.yaml`](compose.yaml).

## Usage

Add the instance as a custom search engine in your browser:

```
https://unduckified.example.com/?q=%s
```

Browsers that support OpenSearch can discover it instead. The descriptor is rewritten on the fly to point at whichever host served it, so it never sends searches to the public instance. `X-Forwarded-Proto` is honored when the container sits behind a reverse proxy.

**Serve it over HTTPS.** Unduckified resolves bangs in a service worker, and browsers only register those on secure origins. Over plain HTTP the app still works, but every search falls back to loading the page first, which is the slow path it exists to avoid.

## Search suggestions

Upstream runs its address-bar suggestions as a Cloudflare Pages Function, because browsers issue those requests outside any service worker, and they must be answered by a server. That function is written against web standards and needs no Cloudflare bindings, so this image runs it unmodified on Bun, bound to loopback, with nginx proxying `/suggest` to it. Output is byte-identical to the hosted instance.

See [Search Suggestions](https://github.com/taciturnaxolotl/unduckified#search-suggestions)
