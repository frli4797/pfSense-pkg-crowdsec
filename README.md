# pfSense-pkg-crowdsec

This package integrates CrowdSec in pfSense.

It is not installed from the official repositories, at least not yet, but you are free to test from the Releases page.

Please refer to the [detailed documentation](https://docs.crowdsec.net/docs/getting_started/install_crowdsec_pfsense/) to install or update it from a release archive.

## Building for FreeBSD 16 / pfSense 25.11

If you need a package that already includes the latest fixes from this fork (for example commit `a77ea2c5` to restore compatibility with the pfSense 25.11 / FreeBSD 16 preview), follow the step-by-step guide in [`docs/build-install-freebsd16.md`](docs/build-install-freebsd16.md).

The document explains how to build the port locally, bundle it with the required `crowdsec` and `crowdsec-firewall-bouncer` packages, and install the resulting tarball with `install-crowdsec.sh --from <tarfile>`.

### CI-built artifacts

If you prefer automation, enable the [`FreeBSD Package Matrix`](.github/workflows/build-freebsd16.yml) workflow in your fork. It boots the official FreeBSD 15.0-RELEASE VM image as well as the latest 16.0-CURRENT snapshot, runs the same port build/tarball steps, and publishes `freebsd-15-amd64.tar` plus `freebsd-16-amd64.tar` as downloadable artifacts. When you cut a GitHub Release, the workflow automatically attaches those tarballs alongside the rebuilt `pfSense-pkg-crowdsec-*.pkg` files to the release page.

### Installing with a custom pfSense package

`install-crowdsec.sh` now accepts `--pkg-override-repo <owner/repo>` (and optionally `--pkg-override-release <tag>`, `--pkg-override-url <direct .pkg>`, or `--pkg-override-sha256 <checksum>`) so you can download `pfSense-pkg-crowdsec` from this fork while still fetching the other packages from the upstream release bundle and verifying the override against a published SHA-256.

### Downloading CI logs locally

Run `scripts/fetch-gh-logs.sh [run-id]` to pull the latest (or specified) GitHub Actions logs via the `gh` CLI. Logs are saved under `debug-logs/run-<id>/` and are ignored by git so you can review failures locally without polluting commits.

It provides a basic UI with settings to configure the Security Engine and the Firewall Remediation Component (bouncer).

Three types of configuration are supported:

- Small: remediation only. Use this to protect a set of existing servers already running CrowdSec. The remediation component
  feeds the Packet Filter with the blocklists received by the main CrowdSec instance (*).

- Medium: like Small but can also detect attacks by parsing logs in the pfSense machine. Attack data is sent to the CrowdSec
  instance for analysis and possibly sharing.

- Large: deploy a fully autonomous CrowdSec Security Engine on the pfSense machine and allow other servers to connect to it.
  Requires a persistent /var directory (no RAM disk) and a slightly larger pfSense machine, depending on the amount of data
  to be processed.

(*) If you are already using a Blocklist Mirror, this replaces it while being faster and not requiring pfBlockerNG.
