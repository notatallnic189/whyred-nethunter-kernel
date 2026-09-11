# NetHunter app + Kali chroot on a custom kernel (without flashing the official NetHunter kernel)

This guide is for anyone running whyred (Redmi Note 5 Pro) on LineageOS 18.1
with a custom kernel, this one or any other, who wants the Kali NetHunter
userland: the app, the Kali chroot, KeX, HID attack tools. Verified on a
real whyred running this kernel (see the README Verified section).

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
  (`4.4.302-Nethunter-whyred-...` for this kernel). If it changed, you
  flashed something that contained a kernel.
- In the NetHunter app the chroot status is "installed" and the chroot
  terminal opens with a Kali prompt.
- `su -c ls /data/adb/modules/ak3-helper/system/lib/modules` still lists
  `88XXau.ko` and `wireguard.ko`.

## Why this page exists

The official kali.org download page mixes kernel zips and app resources
without a clear warning for custom kernel users, and every custom kernel
user eventually asks the same question: how do I get the NetHunter app
without replacing my kernel. This page is that answer for whyred, and the
logic (inspect the zip, install app + chroot from the store, never flash a
kernel zip) applies to any device with any custom kernel.
