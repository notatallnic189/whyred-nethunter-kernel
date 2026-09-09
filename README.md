# whyred NetHunter Kernel

![whyred NetHunter Kernel](docs/banner.png)

[![Build](https://github.com/notatallnic189/whyred-nethunter-kernel/actions/workflows/build-kernel.yml/badge.svg)](https://github.com/notatallnic189/whyred-nethunter-kernel/actions/workflows/build-kernel.yml)
[![Release](https://img.shields.io/github/v/release/notatallnic189/whyred-nethunter-kernel)](https://github.com/notatallnic189/whyred-nethunter-kernel/releases)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
![Device](https://img.shields.io/badge/device-Redmi%20Note%205%20Pro%20%28whyred%29-red)
[![Telegram](https://img.shields.io/badge/Telegram-t.me%2Fwhyrednethunter-26A5E4?logo=telegram)](https://t.me/whyrednethunter)
[![XDA](https://img.shields.io/badge/XDA-support%20thread-orange?logo=xdadevelopers)](https://xdaforums.com/t/kernel-whyred-nethunter-kernel-for-los-18-1-hid-gadget-rtl8812au-injection-ci-built.4800231/)

Custom kernel for the **Xiaomi Redmi Note 5 Pro (whyred, SDM636)** that turns a
LineageOS 18.1-class ROM into a Kali NetHunter capable platform. Built by
GitHub Actions, shipped as a flashable AnyKernel3 zip, zero paid tools.

**Latest release: [v1.1.0](https://github.com/notatallnic189/whyred-nethunter-kernel/releases/tag/v1.1.0), now with a signed WireGuard module in the zip**

**Community:** [XDA support thread](https://xdaforums.com/t/kernel-whyred-nethunter-kernel-for-los-18-1-hid-gadget-rtl8812au-injection-ci-built.4800231/) | [Telegram channel t.me/whyrednethunter](https://t.me/whyrednethunter) (release announcements, flash help) | [landing page](https://notatallnic189.github.io/whyred-nethunter-kernel/)

Base: `LineageOS/android_kernel_xiaomi_sdm660` @ `lineage-18.1` (Linux 4.4.302)

Actively maintained as of September 2026. Project landing page: <https://notatallnic189.github.io/whyred-nethunter-kernel/>

## What's in the kernel (vs stock LOS defconfig)

| Option | Why NetHunter needs it |
|---|---|
| `CONFIG_USB_CONFIGFS_F_HID=y` | HID gadget for DuckHunter / keystroke injection via OTG |
| `CONFIG_USB_CONFIGFS_F_FS=y` | functionfs for NetHunter USB gadget plumbing |
| `CONFIG_FW_LOADER_USER_HELPER=y` | firmware loading for external WiFi adapters |
| `# CONFIG_ANDROID_PARANOID_NETWORK` not set | chroot/proot tools can bind sockets without AID_INET |
| `CONFIG_MODULES=y` + `CONFIG_MODULE_UNLOAD=y` | out-of-tree module support |
| `CONFIG_LOCALVERSION="-Nethunter-whyred"` | identifiable via `uname -a` |

## External WiFi adapter: rtl8812au monitor mode + injection

`88XXau.ko` (aircrack-ng rtl8812au v5.6.4.2, signed with the kernel build key,
vermagic locked to this kernel) is bundled in the AnyKernel3 zip and installed
systemlessly via an ak3-helper Magisk module. Supports RTL8812AU/8821AU/8814AU
class adapters: monitor mode and packet injection via OTG.

## WireGuard VPN built in

`wireguard.ko` (wireguard-linux-compat) is compiled with the same proton-clang
toolchain against this kernel tree, signed with the kernel build key and
shipped in the zip next to `88XXau.ko`. Since the kernel enforces
`CONFIG_MODULE_SIG_FORCE`, a signed in-zip module is the clean way to get
WireGuard on 4.4 without touching the ROM. Bring your own config, run
`wg-quick up` from the NetHunter userland, done.

## Why this instead of the 2020 Team-420 kernel

Team-420 proved NetHunter on whyred was possible, full respect. This project
continues the idea with a modern, reproducible pipeline:

| | Team-420 (2020) | this kernel |
|---|---|---|
| Builds | one off manual releases | every push on GitHub Actions, zips as artifacts |
| Source | frozen | patches and config in the open, rebuildable anywhere |
| Modules | unsigned, permissive expectations | signed with the kernel build key, `MODULE_SIG_FORCE` stays on |
| VPN | not available | WireGuard module built in, signed, shipped in the zip |
| LOS base | old trees | current `lineage-18.1` head, rebaseable |
| Rollback | manual | AnyKernel3, just restore `boot` from your nandroid |

## Screenshots

Listed upstream in the official Kali NetHunter kernels page
(nethunter.kali.org/kernels.html):

![whyred row on the official Kali NetHunter kernels page](docs/img/kali-whyred-row.png)

Every zip is built on GitHub Actions and attached to the release with its
sha256 file:

| [release v1.1.0](https://github.com/notatallnic189/whyred-nethunter-kernel/releases/tag/v1.1.0) | [CI runs](https://github.com/notatallnic189/whyred-nethunter-kernel/actions) |
|---|---|
| ![release v1.1.0 assets](docs/img/release-v110.png) | ![green CI runs](docs/img/ci-actions.png) |

<!-- Device-side shots slot in here once captured from a real whyred:
| NetHunter app | wg show | airodump-ng |
|---|---|---|
| ![NetHunter app](docs/img/nethunter-app.png) | ![wg show](docs/img/wg-show.png) | ![airodump-ng](docs/img/airodump-ng.png) |
-->

## Flash it (LineageOS 18.1)

1. Boot TWRP, take a full nandroid backup (boot + system + data).
2. Flash the zip. It writes the kernel into `boot` and installs the module
   helper through Magisk (systemless).
3. **Reboot recovery and reflash Magisk** (any kernel flash can displace root).
4. Boot and verify:
   - `uname -a` → `4.4.302-Nethunter-whyred-...`
   - `ls /config/usb_gadget` present (HID gadget available)
   - `insmod /system/lib/modules/88XXau.ko` (or via NetHunter) then plug the
     adapter through OTG and check `airmon-ng` / `ip link`
   - `insmod /system/lib/modules/wireguard.ko` then check
     `ip link add dev wg0 type wireguard` (or just `wg-quick up` from NetHunter)

Then install the NetHunter userland with the official Generic ARM64 installer
from [kali.org/get-kali](https://www.kali.org/get-kali/#kali-mobile) and pair
it with this kernel.

## Rollback

Restore the `boot` partition from your TWRP nandroid (or fastboot flash the
stock/LOS boot.img you backed up). The ak3-helper module removes itself when
the kernel changes.

## Build it yourself

GitHub Actions builds every push: grab the zip from the Actions artifacts or
from the Releases page. Prefer local? Run `./build.sh` on any x86_64 Linux box
with git, zip and the usual build tools installed.

## FAQ

**Does the internal WiFi support monitor mode or injection?**
No. The WCN3980 cannot do either on any ROM or kernel, it is a firmware and
driver limitation. Wireless attacks need an external RTL8812AU class adapter
over OTG.

**Does it work on MIUI or Android 13/14 ROMs?**
It targets LOS 18.1-class ROMs with the 4.4 kernel. 4.19 based A13/A14 ROMs
need a different kernel tree, do NOT flash this on those.

**Is root required?**
Yes, Magisk. Reflash Magisk right after any kernel flash.

**DuckHunter supported?**
Yes. The HID gadget exposes `/dev/hidg0` for keystroke injection.

**NetHunter app?**
Use the official Generic ARM64 installer from kali.org. No 2020 era ROM zips
needed.

## Known limitations (whyred hardware)

- Internal WCN3980 WiFi cannot do monitor mode or injection (driver/firmware
  limitation), external adapter required for wireless attacks.
- Kernel base is the LOS 18.1 (Android 11) era; do NOT flash this on 4.19-based
  ROMs (A13+/dynamic-partition builds).

## Changelog

**v1.1.0 (2026-09-09)**
- New: signed WireGuard module (`wireguard.ko`, wireguard-linux-compat) bundled
  in the AnyKernel3 zip and installed systemlessly next to `88XXau.ko`.

**v1.0.0 (2026-09-01)**
- Initial release: NetHunter defconfig (HID gadget, functionfs, user-helper
  firmware loading, no paranoid networking), signed rtl8812au module,
  AnyKernel3 packaging, CI builds on every push.

## Responsible use

For learning and lab work on equipment you own or are authorized to test. Do
not use it against systems you do not have permission to touch.

## Credits

- LineageOS and the sdm660 kernel maintainers
- theradcolor and Team-420, who proved NetHunter on whyred was possible
- osm0sis for AnyKernel3
- aircrack-ng for the rtl8812au driver
- the Kali NetHunter team

## License

Repo tooling: MIT (see LICENSE). Kernel sources, AnyKernel3 and the rtl8812au
driver keep their own licenses (GPLv2 family).

---

If this kernel rescued a whyred from your drawer, a star helps other owners
find it.
