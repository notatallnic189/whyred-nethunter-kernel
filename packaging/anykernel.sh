# AnyKernel3 Ramdisk Mod Script
# whyred (Redmi Note 5 Pro) NetHunter Kernel - LOS 18.1 sdm660 base
# Patched for Kali NetHunter: HID gadget, functionfs, user-helper fw loading,
# no ANDROID_PARANOID_NETWORK, RTL8812AU external-adapter module

properties() { '
kernel.string=whyred-NetHunter 4.4.302 (LOS 18.1 + NH configs + 88XXau)
do.devicecheck=1
do.modules=1
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=whyred
supported.versions=
supported.patchlevels=
'; }

## AnyKernel methods (DO NOT CHANGE)
. tools/ak3-core.sh;

## AnyKernel defaults
BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

## Install
dump_boot;

write_boot;
# end install
