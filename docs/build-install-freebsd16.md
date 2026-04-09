# Building and Installing pfSense-pkg-crowdsec for FreeBSD 16 / pfSense 25.11

This guide describes how to build and install the CrowdSec pfSense package so that it already contains commit `a77ea2c5` ("fix: no working build for 25.11/FreeBSD:16:amd64") from this fork. Follow the steps on a FreeBSD 16 host (for example a pfSense 25.11 development VM) with root access.

## 1. Prepare the builder

```sh
pkg install -y git ca_root_nss pkgconf poudriere-devel
mkdir -p /usr/ports/security
```

*Any FreeBSD 16 environment with the default ports tree layout works; poudriere is optional but pulls in the tools that `make package` expects.*

## 2. Clone this fork and check the required commit

```sh
cd /usr/local/src
git clone https://github.com/crowdsecurity/pfSense-pkg-crowdsec.git crowdsec-pfsense
cd crowdsec-pfsense
git checkout a77ea2c5b223eb621bae29c310a4ff014c19b85f
```

The latest commit adds a guard around `parse_config()` so the package works on FreeBSD 16.

## 3. Stage the port into the local tree

```sh
rsync -a security/pfSense-pkg-crowdsec/ /usr/ports/security/pfSense-pkg-crowdsec/
```

If `/usr/ports` is elsewhere in your build jail, adjust the destination accordingly.

## 4. Build the package for amd64/FreeBSD 16

```sh
cd /usr/ports/security/pfSense-pkg-crowdsec
make clean package
```

The resulting package is placed under `/usr/ports/packages/All/pfSense-pkg-crowdsec-0.1.6.pkg`. Confirm that `pkg info -F` on the artifact lists the `a77ea2c5` commit hash in `+COMPACT_MANIFEST`.

## 5. Assemble a release-style tarball

`install-crowdsec.sh` expects a tarball that contains these files:

- `crowdsec-*.pkg`
- `crowdsec-firewall-bouncer-*.pkg`
- `pfSense-pkg-crowdsec-*.pkg` (the one you just built)

Fetch the dependency packages already published by Netgate/CrowdSec for FreeBSD 16 and build the tarball:

```sh
WORKDIR=/tmp/crowdsec-release
mkdir -p "$WORKDIR"
pkg fetch -d -o "$WORKDIR" crowdsec crowdsec-firewall-bouncer
cd "$WORKDIR/All"
TARBALL=/tmp/freebsd-16-amd64.tar
cp /usr/ports/packages/All/pfSense-pkg-crowdsec-*.pkg .
tar -czf "$TARBALL" crowdsec-*.pkg crowdsec-firewall-bouncer-*.pkg pfSense-pkg-crowdsec-*.pkg
```

The tarball layout now matches the official releases, but it embeds the rebuilt pfSense package from this fork.

## 6. Install on the target firewall

1. Copy the tarball to the pfSense appliance:

    ```sh
    scp /tmp/freebsd-16-amd64.tar root@<firewall>:/root/
    ```

2. On the firewall, run the bundled installer script in this repo (use the `--from` option to skip the GitHub download):

    ```sh
    pfSense# pkg install -y git
    pfSense# git clone https://github.com/crowdsecurity/pfSense-pkg-crowdsec.git /root/pfSense-pkg-crowdsec
    pfSense# cd /root/pfSense-pkg-crowdsec
    pfSense# sh install-crowdsec.sh --from /root/freebsd-16-amd64.tar
    ```

3. Accept the prompts. The script stops the previous services, installs the three packages in dependency order, and restarts CrowdSec only after the pfSense plugin configures aliases.

## 7. Verification

```sh
pkg info pfSense-pkg-crowdsec | grep Version
grep parse_config /usr/local/pkg/crowdsec.inc
service crowdsec status
```

You should see version `0.1.6` (or higher) and the guarded `parse_config()` logic from commit `a77ea2c5`. CrowdSec should be running, and the UI (Services ➝ CrowdSec) will show the updated build.
