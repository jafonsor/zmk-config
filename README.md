# Glove80 ZMK config

## Why this repo exists

This repo builds Glove80 firmware **with [ZMK Studio](https://zmk.studio) enabled**, which neither of the usual starting points gives you out of the box:

- The Glove80 boards (`glove80_lh`, `glove80_rh`) exist only in MoErgo's fork, [`moergo-sc/zmk`](https://github.com/moergo-sc/zmk), not in upstream ZMK. MoErgo's official config template builds that fork with **Nix**, not with the usual ZMK `west` workflow, and its CI does not turn Studio on.
- MoErgo's fork does contain Studio support, including Studio dependencies in its Nix build. But that build **fails on GitHub's runners** as soon as Studio is enabled: nanopb's `generator/protoc` script starts with `#!/usr/bin/env python3`, and the Nix sandbox there cannot run it (`…/nanopb/generator/protoc: not found`).
- The generic upstream `west` workflow compiles a Studio build of the fork, but the firmware it produced misbehaved on the keyboard. The cause was never pinned down, so this repo moved to MoErgo's own, supported Nix route instead.

So this repo uses MoErgo's Nix build, enables Studio with `CONFIG_ZMK_STUDIO=y`, and **patches nanopb's shebangs** in [`config/default.nix`](config/default.nix) so the Studio build works both locally and on GitHub. It also carries a keymap with the layers Studio needs, and a README for building and flashing it. If MoErgo's build starts working with Studio on its own, the patch can be removed.

Firmware for a MoErgo Glove80, built with MoErgo's Nix build and tracking the
`moergo-sc/zmk` `main` branch. The build produces **one file, `glove80.uf2`**,
which is flashed to **both** halves.

## Files

| File | Purpose |
|---|---|
| `config/glove80.keymap` | The keymap (Miryoku-style layout from the Glove80 Layout Editor, 20 layers: 15 in use, 5 empty spares) |
| `config/glove80.conf` | Kconfig options (`CONFIG_ZMK_STUDIO=y`) |
| `config/default.nix` | Nix build: left + right halves, merged into one `.uf2`. Also holds a workaround for building ZMK Studio (see below) |
| `.github/workflows/build.yml` | Same build on GitHub Actions |
| `build.sh` | Local build script |

## Build locally

Needs [Nix](https://nixos.org/download) and `git`. It also works on macOS (Apple Silicon).

```sh
./build.sh
```

This clones MoErgo's ZMK fork into `src/` (or updates it), runs `nix-build config -o result`, and copies the firmware to:

```
./glove80.uf2        <- flash this file
./result/glove80.uf2 <- same file, a symlink into /nix/store
```

`src/`, `result` and `glove80.uf2` are git-ignored. The first build downloads the toolchain and takes a while; later builds are cached.

## Build on GitHub

Every push to `main` (or **Actions → Build → Run workflow**) builds the firmware. Download it from the run page, under **Artifacts** → `glove80.uf2` (a zip containing `glove80.uf2`).

Artifacts are deleted after about 90 days. Re-run the workflow to get a new one.

## Flash

Use the same `glove80.uf2` on both halves:

1. Power the half off. Hold **Magic** (bottom-left key) together with the half's bootloader key, then power it on. Check MoErgo's support page for the exact key for each half.
2. A USB drive (`GLV80LHBOOT` / `GLV80RHBOOT`) appears. Copy `glove80.uf2` onto it. The half reboots by itself.
3. Repeat for the other half.

The bootloader does not depend on the keymap, so you can always re-flash, even from a broken firmware.

## ZMK Studio

> **To unlock ZMK Studio, hold the Magic key and press Z.**
> Studio is locked by default and shows "Unlock To Continue" until you do. Magic is the bottom-left key; Z is the key to the right of `` ` `` on the left half. This is the `&studio_unlock` binding on the Magic layer in [`config/glove80.keymap`](config/glove80.keymap).

- **Use Bluetooth, not USB.** Enabling the USB serial snippet (`studio-rpc-usb-uart`) together with Studio broke USB typing on this keyboard, so it is not used here. Studio over USB therefore does not work.
- **The web app (zmk.studio) has no Bluetooth option on macOS.** Use the ZMK Studio desktop app instead: <https://github.com/zmkfirmware/zmk-studio/releases>.
- Put the keyboard on a Bluetooth profile that is advertising (an unused profile), connect from the app, and approve the pairing.
- `ZMK_BEHAVIORS_KEEP_ALL` is defined in the keymap so Studio can offer all default behaviors (Mod-Tap, Layer-Tap, ...). Without it, behaviors the keymap does not use are left out of the firmware.
- Studio can only use as many layers as the keymap defines. The spare layers (`Spare 1`..`Spare 5`) are there so you can add layers without editing the keymap.
- Edits made in Studio are stored on the keyboard, not in this repo.

## Why `default.nix` patches nanopb

ZMK Studio's build runs nanopb's `generator/protoc`, whose shebang is `#!/usr/bin/env python3`. That fails inside the Nix sandbox on GitHub's runners (`…/nanopb/generator/protoc: not found`). `config/default.nix` copies the nanopb module and points those shebangs at a Nix-provided Python. The exact reason `/usr/bin/env` fails in the sandbox was not confirmed. If MoErgo's build starts working without it, the patch can be deleted.

## Magic layer

Holding **Magic** switches to the Magic layer (Bluetooth profiles and clear, RGB controls, bootloader, reset, Studio unlock). **Tapping** it shows the status lights (battery, layer, Bluetooth).

## Notes

- The build tracks `moergo-sc/zmk` `main`, so a rebuild can pick up upstream changes (and upstream breakage). To pin a version, set `ref:` in `.github/workflows/build.yml` and the branch in `build.sh` to a release tag (for example `v26.09`).
- ZMK Studio works over Bluetooth in the stock-keymap builds that were tested. This exact keymap has not been tested on hardware at the time of writing.
