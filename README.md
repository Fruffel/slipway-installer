# Slipway installer

Public launcher for privately distributed Slipway releases. Only this launcher
and README live here; binaries and application source remain in private Gitea.

On a fresh, dedicated Linux server:

```sh
curl -fsSL https://raw.githubusercontent.com/Fruffel/slipway-installer/main/install.sh | sudo sh
```

The launcher asks once for a Gitea personal access token with `read:repository`
access to `jeroen/slipway`. Input is hidden. The token is saved after a successful
private installer download to `/root/.slipway-release-header`, owned by root with
permissions `0600`. Later runs reuse it. Remove that file to change the saved
credential; revoke old tokens in Gitea Settings → Applications.

The latest private release must be v0.1.1 or newer. The launcher reports an error
if only an older release is available; it does not save the token in that case.

Private binary archives are verified against the checksums embedded in their
version-pinned installer. Existing host ownership and isolation checks still
apply. Ubuntu 24.04+, Debian 12+ and Arch Linux on amd64/arm64 are supported by
the installer. The target needs systemd, root access, curl, tar, sha256sum,
mktemp, stat and stty; the first token prompt needs a terminal.

Use `sh -s --` to forward existing installer options:

```sh
curl -fsSL https://raw.githubusercontent.com/Fruffel/slipway-installer/main/install.sh | sudo sh -s -- --wizard
```

Rerunning reuses the saved token for later release downloads and resumes the
existing installer configuration. It does not choose a new controller image.
The setup wizard still requires an immutable, externally pullable controller
image. The API and operator console remain private and use SSH forwarding.

To review before execution, download `install.sh`, inspect it, then run
`sudo sh install.sh`. `sh install.sh --help` makes no host changes.

Maintained from `scripts/get-slipway.sh` in the private Slipway repository.
