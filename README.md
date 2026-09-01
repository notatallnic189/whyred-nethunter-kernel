# whyred NetHunter Kernel (Path B)

Custom kernel for the **Xiaomi Redmi Note 5 Pro (whyred, SDM636)** that turns a
LineageOS 18.1-class ROM into a Kali NetHunter-capable platform.

Base: `LineageOS/android_kernel_xiaomi_sdm660` @ `lineage-18.1` (Linux 4.4.302)

## What's in the kernel (vs stock LOS defconfig)

| Option | Why NetHunter needs it |
|---|---|
| `CONFIG_USB_CONFIGFS_F_HID=y` | HID gadget for DuckHunter / keystroke injection via OTG |
| `CONFIG_USB_CONFIGFS_F_FS=y` | functionfs for NetHunter USB gadget plumbing |
| `CONFIG_FW_LOADER_USER_HELPER=y` | firmware loading for external WiFi adapters |
| `# CONFIG_ANDROID_PARANOID_NETWORK` not set | chroot/proot tools can bind sockets without AID_INET |
| `CONFIG_MODULES=y` + `CONFIG_MODULE_UNLOAD=y` | out-of-tree module support |
| `CONFIG_LOCALVERSION="-Nethunter-whyred"` | identifiable via `uname -a` |

## External adapter module

`88XXau.ko` (aircrack-ng rtl8812au v5.6.4.2, vermagic-locked to this kernel)
is bundled in the AnyKernel3 zip and installed systemlessly via an ak3-helper
Magisk module. Supports RTL8812AU/8821AU/8814AU class adapters: monitor mode
and packet injection via OTG.

## Build fixes carried in patches/

1. `vdso32` routed through the ARM32 gcc 4.9 toolchain (proton-clang's bundled
   assembler is not ARM32; `-EL` rejection).
2. `cc32-option` used for `-Qunused-arguments` probe (flag is clang-only; ARM32
   gcc rejects it).
3. Latent Makefile syntax bugs in `vdso32/Makefile` (space-indented recipes)
   fixed to TABs, exposed only when `CONFIG_VDSO32` parses the file.
4. `compiler-gcc.h` GCC>=5.1 gate exempted for the ARM32 vDSO build via
   `__ARM32_VDSO_GCC__` (the gate guards an ARM64 codegen bug, not vDSO).
5. `vdso_prepare` guarded for external-module builds (`prepare0` does not exist
   in module context).
6. Driver: compat symbols gated behind `CONFIG_KERNEL_HAS_NEW_BANDS` because
   this kernel backports the 4.7+ cfg80211 band API and the 4.10+
   10-argument `cfg80211_connect_bss` while keeping a 4.4 version string.

## Build it yourself

Push this repo to GitHub: the included workflow builds everything on the free
tier (public repo = unlimited minutes) and uploads the flashable zip as an
artifact. Or run `./build.sh` on any x86_64 Linux box.

## Flash

1. Boot TWRP, take a full nandroid backup (boot + system + data).
2. Flash the zip. It writes the kernel into `boot` and installs the module
   helper through Magisk (systemless).
3. **Reboot recovery and reflash Magisk** (any kernel flash can displace root).
4. Boot and verify:
   - `uname -a` → `4.4.302-Nethunter-whyred-...`
   - `ls /config/usb_gadget` present (HID gadget available)
   - `insmod /system/lib/modules/88XXau.ko` (or via NetHunter) then plug the
     adapter through OTG and check `airmon-ng` / `ip link`

## Rollback

Restore the `boot` partition from your TWRP nandroid (or fastboot flash the
stock/LOS boot.img you backed up). The ak3-helper module removes itself when
the kernel changes.

## Known limitations (whyred hardware)

- Internal WCN3980 WiFi cannot do monitor mode or injection (driver/firmware
  limitation), external adapter required for wireless attacks.
- Kernel base is the LOS 18.1 (Android 11) era; do NOT flash this on 4.19-based
  ROMs (A13+/dynamic-partition builds).
- Team-420/2020-era NetHunter ROM zips are not needed: pair this kernel with
  the official NetHunter Generic ARM64 installer from kali.org.
