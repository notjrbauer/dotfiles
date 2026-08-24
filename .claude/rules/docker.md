---
paths:
  - "**/Dockerfile*"
  - "**/*.dockerfile"
  - "**/docker-compose*.y*ml"
  - "**/compose.y*ml"
---

# Docker, BuildKit, and OCI

Minimal, secure, reproducible images with provenance — opinions backed by the spec. BuildKit is the default builder; use `docker buildx build`. Verify any version-specific claim against the primary source before citing it — pins rot.

## Base images and supply chain
- Prefer purpose-built minimal images. `scratch` for static binaries (Go/Rust with CGO off); **distroless** (`gcr.io/distroless/*`, nonroot variants) for interpreted/dynamic runtimes; **Chainguard/Wolfi** (`cgr.dev/chainguard/*`, `wolfi-base`) for continuously-rebuilt, near-zero-CVE, SBOM-signed images with `apk` available in the build stage; `-slim` (bookworm-slim) is the pragmatic glibc fallback when you need a shell to debug. Avoid Alpine/musl for anything with glibc-sensitive deps (DNS, NSS, CGO).
- `syft` (SBOM, the deliverable) → `grype` (scan the SBOM); or `trivy image` for scan+SBOM in one shot. Sign & attest with **cosign** (keyless via Sigstore/OIDC) — `cosign sign`, `cosign attest` with SLSA/in-toto provenance, `cosign verify` at admission. Store SBOM/signatures as OCI referrer artifacts. buildx can emit provenance + SBOM inline: `--provenance=mode=max --sbom=true`.
- Podman (daemonless, rootless-first, cgroups v2-only) when the engineer wants no daemon or K8s-native `podman generate kube`.

## Distinguishing expertise
- **Idiomatic multi-stage Dockerfiles**: fat builder stage → thin runtime stage that copies only the artifact. `# syntax=docker/dockerfile:1` on line one to pin the frontend and unlock BuildKit features.
- **Layer ordering & cache efficiency**: order instructions least→most volatile. Copy dependency manifests (`go.mod`/`package.json`/`requirements.txt`) and resolve deps BEFORE copying source, so code edits don't bust the dep layer. One logical change per layer; combine related `RUN`s to avoid orphaned intermediate layers.
- **BuildKit features**: `RUN --mount=type=cache,target=/root/.cache/go-build` for compiler/pkg caches (never committed to the image); `RUN --mount=type=secret,id=npmrc` for build-time secrets that leave no layer trace; `RUN --mount=type=bind` for ephemeral source; heredocs (`RUN <<EOT ... EOT`) for readable multi-line scripts.
- **Build args vs secrets**: `ARG`/`--build-arg` are visible in image history and `docker history` — NEVER for tokens/keys. Secrets go through `--mount=type=secret` or `--secret`. `ENV` bakes into every layer and leaks.
- **Minimal images**: scratch/distroless/wolfi; strip binaries, `CGO_ENABLED=0` static Go, `-ldflags="-s -w"`, `--no-install-recommends`, purge caches in the same layer.
- **Non-root & rootless**: `USER nonroot` (or a numeric UID like `10001` so K8s `runAsNonRoot` can verify it), `COPY --chown`, read-only rootfs friendliness. Rootless Docker/Podman, user namespaces (`--userns-remap`), drop all capabilities and add back only what's needed (`--cap-drop=ALL --cap-add=NET_BIND_SERVICE`), keep the default seccomp profile (or tighten it), `--security-opt=no-new-privileges`.
- **OCI spec fluency**: manifests, config, layer digests, media types, indexes for multi-arch, annotations, referrers API for attestations; runtime-spec config.json, mounts, namespaces, cgroups, hooks — know where the image spec ends and the runtime spec begins.
- **Reproducible builds**: pin base images by **digest** (`@sha256:...`) not tag, pin apt/apk versions, set `SOURCE_DATE_EPOCH` and buildx `--output type=image,rewrite-timestamp=true` for stable timestamps.
- **Multi-arch**: `docker buildx build --platform linux/amd64,linux/arm64` producing an OCI index; cross-compile in the builder stage rather than QEMU-emulating the whole build when the toolchain allows.
- **Healthchecks & PID 1**: `HEALTHCHECK` for liveness signals; a real init (`tini`, `--init`, or `dumb-init`) or a binary that reaps children and forwards SIGTERM — otherwise `docker stop` hangs 10s then SIGKILLs. Exec-form `ENTRYPOINT ["/app"]` (not shell-form) so signals reach the process.
- **Container↔orchestration boundary**: one concern per container, config via env/mounts, logs to stdout/stderr, graceful SIGTERM handling, readiness vs liveness — build the image so K8s/Compose/Nomad can own lifecycle.

## Anti-patterns you refuse to ship
- Fat single-stage images shipping compilers, headers, and build caches into production.
- `latest` (or any floating tag) as a base — pin by digest.
- Secrets in `ARG`/`ENV`/`COPY`ed files — they persist in layer history forever.
- Running as root (the implicit default) when the workload doesn't need it.
- `apt-get install` without `--no-install-recommends` and without `rm -rf /var/lib/apt/lists/*` in the SAME layer.
- `ADD` for local files or remote URLs when `COPY` (or an explicit `curl` with checksum) is correct — `ADD`'s auto-extract and URL fetch are footguns.
- One-process-many-things (supervisord juggling app+cron+nginx) instead of separate containers.
- Cache-busting layer order (copying all source before installing deps).

## Verify, don't assume
`docker buildx build` the image, then confirm with `docker image inspect` / `docker history` that the final size, `User`, and layer count match intent; `docker run --rm <img> id` to prove non-root; scan with `trivy image` or `syft ... | grype`. Report final size, base digest, effective UID, and any residual CVEs. Prefer editing an existing Dockerfile over rewriting; keep `.dockerignore` tight. Name the trade-off (size vs debuggability, musl vs glibc, QEMU vs cross-compile), and if a question hides an anti-pattern, name it.

## Hand off
Security sign-off before publish/deploy → `code-reviewer`. Service decomposition and the config/secrets contract → the `backend-design` skill.
