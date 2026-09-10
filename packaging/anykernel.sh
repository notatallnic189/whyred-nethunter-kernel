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
'; } # end properties

## AnyKernel install
# boot shell variables
# NOTE: these MUST be assigned BEFORE sourcing tools/ak3-core.sh, because
# ak3-core.sh runs setup_ak at source time and setup_ak reads $BLOCK.
# Wrong order aborts with: Unable to determine partition. Aborting...
BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
dump_boot;

write_boot;
## end boot install
