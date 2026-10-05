# Slipway installer

```sh
curl -fsSL https://raw.githubusercontent.com/Fruffel/slipway-installer/main/install.sh | sudo sh
```

Enter a Gitea token with `read:repository` access when prompted. It is saved
in `/root/.slipway-release-header` (root-only) and reused on later runs.

Binaries stay private. Requires private release v0.1.1 or newer.
