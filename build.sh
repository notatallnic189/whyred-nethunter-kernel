#!/usr/bin/env bash
# whyred NetHunter kernel, full CI build (Path B)
# Base: LineageOS android_kernel_xiaomi_sdm660 @ lineage-18.1
# Adds: HID gadget, functionfs, FW_LOADER_USER_HELPER, no ANDROID_PARANOID_NETWORK,
#       aircrack-ng RTL8812AU external-adapter module, AnyKernel3 packaging.
set -euo pipefail

KERNEL_REPO="https://github.com/LineageOS/android_kernel_xiaomi_sdm660.git"
KERNEL_BRANCH="lineage-18.1"
PROTON_REPO="https://github.com/kdrag0n/proton-clang.git"
ARMTC_REPO="https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git"
RTL_REPO="https://github.com/aircrack-ng/rtl8812au.git"
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
echo "[*] cloning rtl8812au + AnyKernel3"
git clone --depth=1 "$RTL_REPO" rtl8812au
git clone --depth=1 "$AK3_REPO" AnyKernel3

echo "[*] applying patches"
cd kernel-src
cp ../patches/configs/${DEFCONFIG} arch/arm64/configs/${DEFCONFIG}
git apply ../patches/kernel/kernel-vdso32-toolchain-fixes.patch
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

echo "[*] packaging AnyKernel3 zip"
cp kernel-src/out/arch/arm64/boot/Image.gz-dtb AnyKernel3/Image.gz-dtb
mkdir -p AnyKernel3/modules/system/lib/modules
cp rtl8812au/88XXau.ko AnyKernel3/modules/system/lib/modules/88XXau.ko
cp packaging/anykernel.sh AnyKernel3/anykernel.sh
rm -f AnyKernel3/placeholder
cd AnyKernel3
zip -r9 "../${OUT_ZIP}" . -x .git/\* .github/\* README.md \*.zip .DS_\* \*.img.gz placeholder
cd ..

echo "[*] artifact: ${OUT_ZIP}"
sha256sum "${OUT_ZIP}" | tee "${OUT_ZIP}.sha256"
