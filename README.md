# rpi-imager-no-root

Run the **Raspberry Pi Imager** GUI without root / Administrator privileges
so it can be launched normally from your desktop's applications menu.

## What was done

Since the 2.0.x line, upstream rpi-imager **refuses to start at all** unless
the process is running as root on Linux or as Administrator on Windows
([upstream issue #1351](https://github.com/raspberrypi/rpi-imager/issues/1351)).

rpi-imager checks this up front via `PlatformQuirks::hasElevatedPrivileges()`.
If it returns `false`, the CLI prints `ERROR: Not running as root.` and quits
before any window appears.

That is a problem for desktop users: **launchers / application menus never
elevate a process.** So clicking "Raspberry Pi Imager" in your apps menu did
nothing (or errored silently), and the only workaround was to start it from a
terminal with `sudo`.

This project applies a **one-function patch** (two on Windows) that makes
`hasElevatedPrivileges()` always report `true`, so the app skips the startup
gate and opens normally as your own user.

| Platform | File patched | Change | Status |
|----------|--------------|--------|--------|
| Linux | `src/linux/platformquirks_linux.cpp` | `hasElevatedPrivileges()` → `return true` (was `::geteuid() == 0`) | **Tested** — this is the fix running on the author's Arch Linux setup |
| Windows | `src/windows/platformquirks_windows.cpp` | `hasElevatedPrivileges()` → `return true` (was a full token/SID admin check) | **Experimental** — patch is correct against the source, not yet validated on a Windows build |
| macOS | *(none)* | macOS's `hasElevatedPrivileges()` already returns `true` by design | Not needed |

**Yes — the same idea is cross-platform.** macOS needs no change at all
(it already has a sensible permissions model and returns `true`). On Windows
the identical gate exists and the included patch applies the same fix; it is
labeled experimental because it has not been built/tested on Windows in this
project yet.

## Why this is (mostly) safe

This patch only bypasses the application's **startup** check. It does not
disable the operating system's permission model:

- The rpi-imager **UI** does not need root — it needs it only for raw block
  writes to physical disks.
- On **Linux**, real writes are still guarded by the OS through
  `udisks2`/polkit. Install `udisks2` and you can launch from the menu and
  write images as a normal user. Without `udisks2`, the GUI opens but a drive
  write will fail — the same limitation the upstream AUR package documents.
- On **Windows**, writes that genuinely require Administrator may still be
  blocked by the OS token; the app just won't be aware of it.

## Content

```
├── PKGBUILD                # Arch Linux package definition (AUR-style)
├── .SRCINFO                # metadata for package managers / AUR
├── build.sh                # generic build: clone upstream, apply patch, cmake
├── patches/
│   ├── 0001-linux-allow-running-without-root.patch
│   └── 0002-windows-allow-running-without-admin.patch
└── LICENSE                 # Apache-2.0 (same as upstream)
```

Every patch is a plain, reviewable diff against a specific upstream commit.

## Build & install

### Arch Linux (makepkg)

```sh
makepkg -si        # builds and installs from PKGBUILD
```

Requires the usual base-devel + Qt6 tooling. `rpi-imager-no-root` provides
`rpi-imager` and conflicts with the official package, so upgrades won't
silently overwrite it.

### Any platform (build.sh)

```sh
./build.sh          # Linux patch (tested)
./build.sh --windows # Windows patch (experimental)

# environment overrides:
#   UPSTREAM_URL=https://github.com/raspberrypi/rpi-imager.git
#   REF=main
```

You need the rpi-imager build dependencies for your platform (Qt6, curl,
gnutls, libarchive, xz, cmake, a C++17 toolchain).

### Apply the patch manually

Clone upstream, then:

```sh
git apply patches/0001-linux-allow-running-without-root.patch
# or the Windows patch
```

## How it was made

The Linux patch started as a one-line `sed` in the author's personal AUR
package (`rpi-imager-git-non-root`), which has been running cleanly since
September 2025. This repository turns that single-line tweak into a proper,
versioned, documented patch set with a reproducible build path.

## Credits

- Raspberry Pi Ltd for [rpi-imager](https://github.com/raspberrypi/rpi-imager).
- The `rpi-imager-git` AUR package, which this PKGBUILD is based on.

## License

Apache-2.0, matching the upstream project. See [LICENSE](LICENSE).