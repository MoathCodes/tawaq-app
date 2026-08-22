# Install Tawaq on macOS

Unzip this archive and run:

```bash
./install.sh
```

The installer copies Tawaq to `~/Applications` and removes the quarantine flag from that copy only. macOS adds the flag to apps downloaded from the internet. Removing it avoids the extra Finder confirmation for this beta build.

Use `./install.sh --system` to install in `/Applications`. This may request an administrator password. Use `./install.sh --uninstall` to remove the chosen installation.
