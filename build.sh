#!/usr/bin/env bash
# whyred NetHunter kernel, full CI build (Path B)
# Base: LineageOS android_kernel_xiaomi_sdm660 @ lineage-18.1
# Adds: HID gadget, functionfs, FW_LOADER_USER_HELPER, no ANDROID_PARANOID_NETWORK,
#       aircrack-ng RTL8812AU external-adapter module, signed WireGuard VPN module,
#       AnyKernel3 packaging.
set -euo pipefail

KERNEL_REPO="https://github.com/LineageOS/android_kernel_xiaomi_sdm660.git"
KERNEL_BRANCH="lineage-18.1"
PROTON_REPO="https://github.com/kdrag0n/proton-clang.git"
ARMTC_REPO="https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git"
RTL_REPO="https://github.com/aircrack-ng/rtl8812au.git"
WG_REPO="https://github.com/WireGuard/wireguard-linux-compat.git"
AK3_REPO="https://github.com/osm0sis/AnyKernel3.git"
DEFCONFIG="whyred-nethunter_defconfig"
REL="$(date +%Y%m%d)"
OUT_ZIP="whyred-nethunter-kernel-${REL}.zip"

JOBS="$(nproc)"
PROTON="${GITHUB_WORKSPACE:-$PWD}/proton-clang"
ARMTC="${GITHUB_WORKSPACE:-$PWD}/toolchain-arm"

echo "[*] cloning kernel source"
git clone --depth=1 --single-branch --branch "$KERNEL_BRANCH" "$KERNEL_REPO" kernel-src
echo "[*] cloning toolchains"
git clone --depth=1 "$PROTON_REPO" proton-clang
git clone --depth=1 "$ARMTC_REPO" toolchain-arm
echo "[*] cloning rtl8812au + wireguard + AnyKernel3"
git clone --depth=1 "$RTL_REPO" rtl8812au
git clone --depth=1 "$WG_REPO" wireguard-linux-compat
git clone --depth=1 "$AK3_REPO" AnyKernel3

echo "[*] applying patches"
cd kernel-src
cp ../patches/configs/${DEFCONFIG} arch/arm64/configs/${DEFCONFIG}
git apply ../patches/kernel/kernel-vdso32-toolchain-fixes.patch
# Commit the overlay so scripts/setlocalversion reports a clean tree
# (an uncommitted overlay makes every build string end in -dirty).
# Fixed author/committer dates keep the overlay commit hash stable
# across CI runs for the same source state.
git config user.name "nethunter-ci"
git config user.email "nethunter-ci@users.noreply.github.com"
git add -A
GIT_COMMITTER_DATE="2026-01-01T00:00:00+0000" \
GIT_AUTHOR_DATE="2026-01-01T00:00:00+0000" \
  git commit -qm "NetHunter build overlay: NetHunter defconfig + kernel patches"
cd ../rtl8812au
git apply ../patches/driver/rtl8812au-nethunter-whyred.patch
cd ..

echo "[*] defconfig"
make -C kernel-src O=out ARCH=arm64 CC="$PROTON/bin/clang" \
  CROSS_COMPILE="$PROTON/bin/aarch64-linux-gnu-" \
  CROSS_COMPILE_ARM32="$ARMTC/bin/arm-linux-androideabi-" \
  ${DEFCONFIG}

echo "[*] building kernel Image.gz-dtb"
make -C kernel-src O=out -j"${JOBS}" ARCH=arm64 CC="$PROTON/bin/clang" \
  CROSS_COMPILE="$PROTON/bin/aarch64-linux-gnu-" \
  CROSS_COMPILE_ARM32="$ARMTC/bin/arm-linux-androideabi-" \
  KBUILD_BUILD_USER=nethunter KBUILD_BUILD_HOST=whyred \
  Image.gz-dtb

echo "[*] building rtl8812au module"
make -C rtl8812au -j"${JOBS}" ARCH=arm64 CC="$PROTON/bin/clang" \
  CROSS_COMPILE="$PROTON/bin/aarch64-linux-gnu-" \
  CROSS_COMPILE_ARM32="$ARMTC/bin/arm-linux-androideabi-" \
  KSRC="$(pwd)/kernel-src/out" \
  KCFLAGS="-Wno-error=unknown-warning-option"

echo "[*] signing rtl8812au module"
# MODULE_SIG_ALL only signs during modules_install, which we never run,
# and CONFIG_MODULE_SIG_FORCE=y rejects unsigned modules on device.
if [ ! -x kernel-src/out/scripts/sign-file ]; then
  make -C kernel-src O=out ARCH=arm64 scripts
fi
kernel-src/out/scripts/sign-file sha512 \
  kernel-src/out/certs/signing_key.pem \
  kernel-src/out/certs/signing_key.x509 \
  rtl8812au/88XXau.ko
tail -c 4096 rtl8812au/88XXau.ko | grep -aq "Module signature appended" \
  || { echo "ERROR: module signature missing"; exit 1; }

# WireGuard: the NetHunter defconfig sets CONFIG_WIREGUARD=y (built-in,
# verified loading at boot on a real device). Building and shipping the
# out-of-tree module on top of that is dead weight in the zip, so only
# build it for trees that actually lack the built-in option.
WG_BUILTIN=0
grep -q '^CONFIG_WIREGUARD=y' kernel-src/out/.config && WG_BUILTIN=1
WGKO=""
if [ "$WG_BUILTIN" == 1 ]; then
  echo "[*] CONFIG_WIREGUARD=y: WireGuard is built-in, skipping out-of-tree module"
else
  echo "[*] building WireGuard module (wireguard-linux-compat)"
  make -C kernel-src O=out -j"${JOBS}" ARCH=arm64 CC="$PROTON/bin/clang" \
    CROSS_COMPILE="$PROTON/bin/aarch64-linux-gnu-" \
    CROSS_COMPILE_ARM32="$ARMTC/bin/arm-linux-androideabi-" \
    M="$(pwd)/wireguard-linux-compat/src" \
    KCFLAGS="-Wno-error=unknown-warning-option -Wno-gnu-variable-sized-type-not-at-end" \
    modules

  WGKO="$(find wireguard-linux-compat/src -name wireguard.ko -print -quit)"
  [ -n "$WGKO" ] || WGKO="$(find kernel-src/out -name wireguard.ko -print -quit)"
  if [ -z "$WGKO" ]; then echo "ERROR: wireguard.ko not produced"; exit 1; fi

  echo "[*] signing WireGuard module"
  # Same story as 88XXau: sign manually, CONFIG_MODULE_SIG_FORCE stays on.
  kernel-src/out/scripts/sign-file sha512 \
    kernel-src/out/certs/signing_key.pem \
    kernel-src/out/certs/signing_key.x509 \
    "${WGKO}"
  tail -c 4096 "${WGKO}" | grep -aq "Module signature appended" \
    || { echo "ERROR: module signature missing"; exit 1; }
fi

echo "[*] packaging AnyKernel3 zip"
cp kernel-src/out/arch/arm64/boot/Image.gz-dtb AnyKernel3/Image.gz-dtb
mkdir -p AnyKernel3/modules/system/lib/modules
cp rtl8812au/88XXau.ko AnyKernel3/modules/system/lib/modules/88XXau.ko
if [ "$WG_BUILTIN" != 1 ]; then
  cp "${WGKO}" AnyKernel3/modules/system/lib/modules/wireguard.ko
fi
cp packaging/anykernel.sh AnyKernel3/anykernel.sh
rm -f AnyKernel3/placeholder
cd AnyKernel3
zip -r9 "../${OUT_ZIP}" . -x .git/\* .github/\* README.md \*.zip .DS_\* \*.img.gz placeholder
cd ..

echo "[*] artifact: ${OUT_ZIP}"
sha256sum "${OUT_ZIP}" | tee "${OUT_ZIP}.sha256"
