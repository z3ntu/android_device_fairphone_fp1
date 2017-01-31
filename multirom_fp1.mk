# Copyright (C) 2017 Daniel Calviño Sánchez <danxuliu@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Inherit TWRP configuration for Fairphone 1, as this multirom_fp1 product is
# intended to be used for everything related to MultiROM, including TWRP with
# the MultiROM extension.
$(call inherit-product, device/fairphone/fp1/twrp_fp1.mk)

PRODUCT_NAME := multirom_fp1
PRODUCT_DEVICE := fp1
PRODUCT_BRAND := MultiROM
PRODUCT_MODEL := MultiROM on FP1
PRODUCT_MANUFACTURER := Fairphone



# Common options.

# Enable both the MultiROM extension for TWRP and MultiROM itself.
TARGET_RECOVERY_IS_MULTIROM := true

# It is not possible to include the utils needed by the MultiROM extension of
# TWRP in the recovery image, as the resulting image is too large for the
# recovery partition of the Fairphone 1. Therefore, those utils must be included
# in the MultiROM directory and loaded by the recovery from there when needed.
# This also prevents the multirom and trampoline executables from being copied
# to the recovery image, as they are not needed there and only take up space.
MR_STORE_UTILS_IN_DATA := true

# The Fairphone 1 is a MediaTek device, so the boot images of the ROMs must
# include MediaTek-specific headers for the kernel and the ramdisk.
MR_USE_MEDIATEK_EXTRA_HEADERS := true

# The file used to control the brightness of the display. It is not really
# needed for TWRP, as one of its default values is the same as the one set here,
# but it is a must for MultiROM.
TW_BRIGHTNESS_PATH := /sys/class/leds/lcd-backlight/brightness



# TWRP-MultiROM options.

# By default, TWRP provides an option in its GUI to partition an SD card. This
# requires the "sgdisk" executable to be included in the ramdisk but,
# unfortunately, in that case the resulting boot image is too large for the
# recovery partition of the Fairphone 1. Being able to partition an SD card is
# not needed for the normal use of TWRP or MultiROM, so that feature is just
# disabled in order to reduce the size of the boot image.
BOARD_HAS_NO_REAL_SDCARD := true

# When the MultiROM extension of TWRP is used the TWRP theme is selected based
# on the older DEVICE_RESOLUTION (an explicit resolution) instead of the newer
# TW_THEME (a generalized orientation and density).
DEVICE_RESOLUTION := 1080x1920

# As this one for MultiROM, and the one for TWRP that it inherits from, are
# minimal product Makefiles they do not inherit from other common product
# configurations like "$(SRC_TARGET_DIR)/product/embedded.mk", so the SELinux
# file_contexts package must be explicitly included in the recovery. SELinux is
# not enabled, so even without a file_contexts file most features would work;
# however, installing ROMs on image files would not, as when the file_contexts
# file is passed to make_ext4fs it expects to find there the security context
# for the mount points of the images, but if not generated during the build the
# file_contexts file would contain just the MultiROM directory entries added at
# boot by the recovery itself.
PRODUCT_PACKAGES += \
	file_contexts



# MultiROM options.

# The default boot image of the main operating system (the official Android
# version from Fairphone) must be tweaked by hand before installing MultiROM, as
# it uses a MediaTek-specific way to mount the partitions instead of the
# standard "mount_all". As the boot image has to be modified a fstab compatible
# with MultiROM can be included too in the image during that modification, so
# there is no need to enable MR_USE_MROM_FSTAB.
#
# In this situation, the MultiROM-specific fstab is only used to find the boot
# device when passed as a parameter to "extract_boot_dev.sh". As it uses the
# same syntax as the TWRP-specific fstab that one can be used safely.
MR_FSTAB := device/fairphone/fp1/twrp.fstab

# The memory position where the kernel to reboot to will be loaded is just an
# arbitrary position that fulfills the conditions stated in MultiROM
# documentation, that is, to be in the first 256 MiB of system RAM and to not be
# rewritten during the reboot.
MR_KEXEC_MEM_MIN := 0x85000000

# The .c file with the uevent paths needed to initialize MultiROM.
MR_INIT_DEVICES := device/fairphone/fp1/multirom/mr_init_devices.c

# There is no common 24/32-bit pixel format to MultiROM and the framebuffer
# kernel driver, so the 16-bit RGB 565 pixel format is used instead.
MR_PIXEL_FORMAT := "RGB_565"

# The generalized density is not really needed, as it is used only to set the
# DPI multiplier, but the DPI multiplier for the hdpi density (1.0) is not the
# right one for the Fairphone 1 and it must be explicitly set. Anyway, the
# generalized density is included for completness and the prevent the build
# system from complaining that it was not set.
MR_DPI := hdpi

# The MultiROM portrait GUI seems to be based on a length of 1200 pixels, as the
# bottom part of the color buttons in the "Misc" tab is at "1160 * DPI_MUL"
# (which can be calculated from the values in "multirom_ui_portrait.c"); as the
# Fairphone 1 display in portrait mode has a length of 960 pixels the DPI
# multiplier must be set to 0.8.
MR_DPI_MUL := 0.8

# Increase the default DPI for fonts (96) to a better looking value.
MR_DPI_FONT := 144

# Although the user can change the brightness used by MultiROM from the MultiROM
# extension for TWRP, set the default brightness higher than the one used by
# MultiROM if none is set, as that one is too low (40).
MR_DEFAULT_BRIGHTNESS := 100

# The Fairphone 1 is a "type A" device regarding the multi-touch protocol from
# the kernel.
MR_INPUT_TYPE := type_a
