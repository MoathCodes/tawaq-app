# Install Tawaq on Linux

Unzip this archive and run:

```bash
./install.sh
```

The installer puts Tawaq in a user-local location, creates an application-menu entry, and only asks for `sudo` if the downloaded bundle has a missing system library. It supports `apt`, `dnf`, `pacman`, and `zypper`.

Run `./install.sh --uninstall` to remove the app and launcher. Use `./install.sh --skip-dependencies` only when you already know the runtime libraries are installed.
