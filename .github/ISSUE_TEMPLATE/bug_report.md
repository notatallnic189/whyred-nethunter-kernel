---
name: Bug report
about: Bootloop, module won't load, feature not working
labels: bug
---

**Device state**

- ROM (name and build date):
- Kernel (`uname -a` output):
- Magisk version:
- TWRP version:

**What happened?**

A clear description of the failure. Bootloop? Module rejected? NetHunter app
error? Say what you expected vs what you got.

**Steps to reproduce**

1. Flash the zip (which release?):
2. ...

**Logs**

`dmesg`, `/proc/last_kmsg` or the recovery log. Use code fences. A module load
failure without the `dmesg` line is unanswerable.

**Before you file**

- Did you reflash Magisk after the kernel? (Most "lost root" reports)
- Are you on a 4.4 based LOS 18.1-class ROM? (4.19 ROMs are not supported)
- vermagic mismatch in `dmesg` means you flashed the kernel on another base.
