# Copyright (C) 2016 Daniel Calviño Sánchez <danxuliu@gmail.com>
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

# Inherit CyanogenMod configuration based on phone tech (GSM or CDMA).
$(call inherit-product, vendor/cm/config/gsm.mk)

# TARGET_SCREEN_HEIGHT and TARGET_SCREEN_WIDTH must be set before inheriting
# from "vendor/cm/config/common.mk", which happens implicitly when inheriting
# from "vendor/cm/config/common_full_phone.mk", as they are used to select the
# right bootanimation.zip.
TARGET_SCREEN_HEIGHT := 960
TARGET_SCREEN_WIDTH := 540

# Inherit common CyanogenMod configuration for phones.
$(call inherit-product, vendor/cm/config/common_full_phone.mk)

# Inherit common Android Open Source Project configuration for phones.
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit Dalvik heap configuration for a standard high density phone.
$(call inherit-product, frameworks/native/build/phone-hdpi-dalvik-heap.mk)

PRODUCT_NAME := cm_fp1
PRODUCT_DEVICE := fp1
PRODUCT_BRAND := CyanogenMod
PRODUCT_MODEL := CyanogenMod on FP1
PRODUCT_MANUFACTURER := Fairphone

# The standard kernel configuration builds a kernel too large that causes the
# recovery image to not fit in the recovery partition. Therefore, no recovery
# image is built along with the rest of CyanogenMod; it has to be built
# explicitly using a recovery product.
TARGET_NO_RECOVERY := true

# When TARGET_NO_RECOVERY is true the "recovery.fstab" file is not copied to the
# recovery directory. However, the "ota_from_target_files" script expects the
# "recovery.fstab" file to be there to get certain information from it.
# Therefore, it has to be explicitly copied.
#
# Also, note that TARGET_RECOVERY_FSTAB can not be used, as it is ignored when
# TARGET_NO_RECOVERY is true.
PRODUCT_COPY_FILES += \
	device/fairphone/fp1/recovery.fstab:recovery/root/etc/recovery.fstab

# Redefining MKBOOTIMG in AndroidBoard.mk is enough to build a recovery image
# using a custom "mkbootimg" command. Unfortunately, that approach does not work
# when using the "otapackage" make target, as the "ota_from_target_files" script
# called from "build/core/Makefile" builds the boot image using the default
# "mkbootimg" command, instead of the one specified in the MKBOOTIMG defined in
# the makefiles. The "ota_from_target_files" script uses the prebuilt "boot.img"
# instead of building it again when the MKBOOTIMG environment variable is set;
# however, when "ota_from_target_files" is called from "build/core/Makefile"
# that variable is set to the value of the BOARD_CUSTOM_BOOTIMG_MK defined in
# the makefiles instead of the value of the MKBOOTIMG defined in the makefiles.
# If BOARD_CUSTOM_BOOTIMG_MK is defined then it is used in other places in the
# build system, so a dummy file with just the rules not defined due to
# BOARD_CUSTOM_BOOTIMG_MK being set is used.
#
# Note, however, that this does not work for the "updatepackage" make target. In
# order to use that target with a custom MKBOOTIMG the build system has to be
# patched.
BOARD_CUSTOM_BOOTIMG_MK := device/fairphone/fp1/DummyBoardCustomBootimg.mk

# Add "charger" command and default images to show charging progress in a
# powered down device.
PRODUCT_PACKAGES += \
	charger \
	charger_res_images

PRODUCT_COPY_FILES += \
	device/fairphone/fp1/rootdir/init.mt6589.rc:root/init.mt6589.rc \
	device/fairphone/fp1/rootdir/fstab.mt6589:root/fstab.mt6589

PRODUCT_COPY_FILES += \
	device/fairphone/fp1/rootdir/etc/vold.fstab:system/etc/vold.fstab

# The BOARD_VOLD_MAX_PARTITIONS parameter defines the maximum number of
# partitions that Vold can handle in a disk, no matter whether they are included
# in vold.fstab or not. By default Vold handles only four partitions, so it has
# to be increased to eight for Vold to handle the internal SDCard partition in
# the Fairphone 1.
BOARD_VOLD_MAX_PARTITIONS := 8

PRODUCT_PACKAGE_OVERLAYS += \
	device/fairphone/fp1/overlay

PRODUCT_PROPERTY_OVERRIDES += \
	ro.sf.lcd_density=240

PRODUCT_PACKAGES += \
	gralloc.fp1

# The OpenGL ES library being used is libagl, which only supports OpenGL ES 1.0.
# The higher 16 bits represent the major number and the lower 16 bits represent
# the minor number.
PRODUCT_PROPERTY_OVERRIDES += \
	ro.opengles.version=65536

# Explicitly declare that a software implementation of OpenGL ES is being used
# to tweak the system accordingly.
# This is not a standard property; the system must be patched to support it.
PRODUCT_PROPERTY_OVERRIDES += \
	ro.softwaregl=true

PRODUCT_PACKAGES += \
	lights.fp1
