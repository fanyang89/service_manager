# Service Manager

Service Manager runs foreground programs as user-level background services. It
provides a desktop tray application for Linux, macOS, and Windows and a loopback-only
Web interface for headless hosts.

## Headless Mode

Build the Web application, then start the service manager:

```sh
flutter build web --no-wasm-dry-run
dart run bin/service_manager.dart --headless
```

The server listens on `127.0.0.1:47321`. Open `http://127.0.0.1:47321` on the
same host.

Available options:

```text
--port=47321
--web-root=build/web
--support-dir=/custom/config/path
```

For a remote Linux host, forward the loopback port from your local machine:

```sh
ssh -L 47321:127.0.0.1:47321 user@remote-host
```

Then open `http://127.0.0.1:47321` locally. The server does not enable CORS and
requires a same-origin session token for every management request.

The default Linux support directory is
`${XDG_CONFIG_HOME:-$HOME/.config}/service_manager`. It contains the service
configuration and rotated logs.

## Headless Bundle

Create a native CLI bundle with its required dynamic libraries:

```sh
flutter build web --no-wasm-dry-run
dart build cli --target=bin/service_manager.dart
cp -r build/web build/cli/linux_x64/bundle/web
build/cli/linux_x64/bundle/bin/service_manager --headless
```

The Linux executable is written under `build/cli/linux_x64/bundle/bin/`. Keep
the whole `bundle/` directory when copying it. The executable automatically
uses `bundle/web/` unless `--web-root` is specified.

## Development

```sh
flutter analyze
flutter test
flutter build web --no-wasm-dry-run
```

Build the Web UI before the Linux desktop app to include it in the relocatable
desktop bundle.

Linux desktop builds require GTK 3 and an AppIndicator development package. On
Debian-based distributions:

```sh
sudo apt-get install libgtk-3-dev libayatana-appindicator3-dev
flutter build linux
```

On Fedora:

```sh
sudo dnf install libayatana-appindicator-gtk3-devel
flutter build linux
```

GNOME may also require the AppIndicator shell extension to display tray icons.
macOS and Windows native builds must be produced and tested on their respective
platforms.
