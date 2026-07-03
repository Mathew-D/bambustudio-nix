# bambustudio-nix

Nix flake that packages BambuStudio as an AppImage wrapper for Linux.

## What this provides

- Fast build and install by reusing the upstream AppImage
- Desktop entry and icon installation
- Runtime environment fixes for:
	- TLS login support
	- CA bundle detection
	- WebKit OAuth compatibility on Linux
	- GDK pixbuf loader discovery

## Requirements

- Nix with flakes enabled
- Linux x86_64

## Usage

Build the package:

```bash
nix build .
```

Run BambuStudio directly:

```bash
nix run .
```

Run the named package explicitly:

```bash
nix run .#bambustudio
```

## Notes

- This flake wraps the upstream binary AppImage, so builds are much faster than compiling BambuStudio from source.
- Some FFmpeg swscaler warnings can appear in logs during video/camera operations. These are typically non-fatal.
