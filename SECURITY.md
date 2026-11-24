# Security policy

## Reporting

Found something that looks like a security problem in this kernel or
its build pipeline? Use GitHub's **private vulnerability reporting** on
this repository (Security tab, "Report a vulnerability"), so the report
does not land in a public issue while it is being looked at. If that
does not work for you, the XDA thread and the Telegram channel in the
README reach the same person, but prefer the private channel: those
are public places.

## What is in scope

- The build scripts and CI workflows in this repository
  (`build.sh`, `packaging/`, `.github/workflows/`)
- The defconfig decisions and the patches under `patches/`
- Anything in a released AnyKernel3 zip that this repository produces

The LineageOS kernel tree, AnyKernel3, rtl8812au, WireGuard and
proton-clang are upstream projects: report their bugs to them, and this
repo will pick up the fix and re-pin.

## What is not a finding

- The IndexNow key file and the Search Console meta tag on the landing
  page are public by design of those protocols.
- Kernel config trade-offs that are already declared in the README
  (regulatory domain bypass for monitor mode, paranoid networking off,
  IKCONFIG exposed via /proc) are documented decisions, not leaks.

## Response time

This is a one-maintainer, zero-budget project: expect days, not hours,
and no SLA. Critical, actively exploitable findings jump the queue.
