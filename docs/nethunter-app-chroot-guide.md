# NetHunter app + Kali chroot on a custom kernel (without flashing the official NetHunter kernel)

This guide is for anyone running whyred (Redmi Note 5 Pro) on LineageOS 18.1
with a custom kernel, this one or any other, who wants the Kali NetHunter
userland: the app, the Kali chroot, KeX, HID attack tools. Verified on a
real whyred running this kernel, with photos below and in the README
Verified section.

## The one rule that protects your kernel

NEVER flash a NetHunter zip before inspecting it. Some NetHunter zips carry
a kernel and a boot image, flashing them over your custom kernel throws it
away and you are back on the official NetHunter kernel.

Check before you flash anything:

1. Download the zip.
2. Unzip it (`Expand-Archive` on Windows, `unzip` on Linux).
3. If you find `boot.img`, `Image.gz-dtb`, or an `anykernel.sh` with
   `do.modules`, it is a KERNEL zip: do not flash it on top of a custom
   kernel you want to keep.
4. What you want for the userland is NOT a zip at all: it is the NetHunter
   app plus a chroot, both installable from userspace, no flashing.

## Method: NetHunter Store (verified, no flashing)

1. In the phone browser open `store.nethunter.com` and install the NetHunter
   Store app (a Kali maintained F-Droid fork).
2. From the NetHunter Store install the **NetHunter** app.
3. Open the NetHunter app, go to **Kali Chroot Manager** and install the
   **Minimal** chroot first (roughly 300 MB). The full chroot is about 2 GB
   and mostly adds big tools you can install later with `apt` from inside
   the chroot.
4. The app needs root for the chroot step: be rooted with Magisk before
   doing this (on this kernel, see the README Flash section).

The end state looks like this, minimal chroot installed and the manager
reporting `Running!`:

![Kali Chroot Manager with the kali-arm64 chroot running](img/device/09-kali-chroot-manager-running.png)

## What works on top of this kernel

- Kali chroot + terminal: everything userspace, works on any kernel.
- KeX (Kali desktop via the app): userspace, works.
- HID / DuckHunter keystroke injection: needs `CONFIG_USB_CONFIGFS_F_HID=y`,
  this kernel has it and exposes `/dev/hidg0`.
- BadUSB style attacks from the app: same HID gadget path.
- WireGuard: built into this kernel, loads at boot, just add your config.
- Monitor mode + packet injection: NOT possible with the internal WCN3980
  WiFi, on any kernel, ever (firmware limitation). Plug an RTL8812AU class
  adapter via OTG; this kernel ships the signed `88XXau.ko` driver for it
  as a systemless module.

## Sanity checks after setup

- `uname -a` still shows your custom kernel string
  (`4.4.302-Nethunter-whyred-g964fc73178ae` for this kernel since v1.2).
  If it changed, you flashed something that contained a kernel. The
  NetHunter app shows the same string on its System information page:

![NetHunter app system information with the custom kernel string](img/device/08-nethunter-app-system-info.png)

- In the NetHunter app the Kali Chroot Manager reports `Running!` for
  `/data/local/nhsystem/kali-arm64`.
- The chroot terminal (NetHunter Terminal, Kali session) opens with a
  `root@kali` prompt, `uid=0` and Kali Rolling:

![root@kali terminal with id, uname -r and PRETTY_NAME](img/device/10-kali-terminal-root-uname.png)

- `su -c ls /data/adb/modules/ak3-helper/system/lib/modules` still lists
  `88XXau.ko` (zips up to v1.1.1 also listed `wireguard.ko`; since v1.2
  WireGuard is built in and the redundant module is skipped).

## Troubleshooting (from the real verification run)

**The NetHunter Store says "Not installed" right after you tap Install**

This happened during the verification of this exact procedure. logcat
showed the cause: `CONNECTION_FAILED: Unable to resolve host
"store.nethunter.com"`. The Store app is a Kali maintained F-Droid fork
with an old client (2019.3b was running here), so a transient DNS hiccup
on the phone is enough to fail the download silently. Nothing is broken
and nothing needs cleaning: confirm the browser can still open
store.nethunter.com, toggle WiFi or mobile data if in doubt, and tap
Install again. The very next attempt downloaded and installed the NetHunter
app and the NetHunter Terminal app without touching anything else.

**The chroot step fails with a root error**

The Chroot Manager needs root to create `/data/local/nhsystem/kali-arm64`
and bind the mounts. Grant the Magisk superuser prompt to the NetHunter
app, then retry from the Chroot Manager.

## Why this page exists

The official kali.org download page mixes kernel zips and app resources
without a clear warning for custom kernel users, and every custom kernel
user eventually asks the same question: how do I get the NetHunter app
without replacing my kernel. This page is that answer for whyred, and the
logic (inspect the zip, install app + chroot from the store, never flash a
kernel zip) applies to any device with any custom kernel.
