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

# TARGET_SCREEN_HEIGHT and TARGET_SCREEN_WIDTH must be set before inheriting
# from "vendor/cm/config/common.mk", which happens implicitly when inheriting
# from "vendor/cm/config/common_full_phone.mk", as they are used to select the
# right bootanimation.zip.
TARGET_SCREEN_HEIGHT := 960
TARGET_SCREEN_WIDTH := 540

# Inherit common CyanogenMod configuration for phones.
$(call inherit-product, vendor/cm/config/common_full_phone.mk)

# Inherit common Android Open Source Project configuration for phones.
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)

# Inherit Dalvik heap configuration for a standard high density phone.
$(call inherit-product, frameworks/native/build/phone-hdpi-dalvik-heap.mk)

# Inherit Fairphone 1 proprietary features configuration. If it does not exist
# it is just ignored.
$(call inherit-product-if-exists, vendor/fairphone/fp1/cm-vendor.mk)

PRODUCT_NAME := lineage_fp1
PRODUCT_DEVICE := fp1
PRODUCT_BRAND := LineageOS
PRODUCT_MODEL := LineageOS on FP1
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

# The fstab version is used by the release tools in "build/tools/releasetools"
# to know how to parse the "recovery.fstab" file.
#
# The value set here does not usually take effect, though, as the Android.mk of
# the recovery typically sets it too. As the Android.mk of the recovery is
# automatically processed after this Makefile along with the rest of Android.mk
# files in the source tree the value set in that file overrides the value set
# here. It is set here, though, just in case it is not set by the recovery.
RECOVERY_FSTAB_VERSION := 2

# Redefining MKBOOTIMG in AndroidBoard.mk is enough to build a recovery image
# using a custom "mkbootimg" command. Unfortunately, that approach does not work
# when using the "otapackage" make target, as the "ota_from_target_files" script
# called from "build/core/Makefile" builds the boot image using the default
# "mkbootimg" command, instead of the one specified in the MKBOOTIMG defined in
# the makefiles. The "ota_from_target_files" script uses the prebuilt "boot.img"
# instead of building it again when the file is provided in the input target
# files zip; when "ota_from_target_files" is called from "build/core/Makefile"
# that happens only if BOARD_CUSTOM_BOOTIMG_MK is defined. If
# BOARD_CUSTOM_BOOTIMG_MK is defined then it is used in other places in the
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
	device/fairphone/fp1/rootdir/init.mt6589.usb.rc:root/init.mt6589.usb.rc \
	device/fairphone/fp1/rootdir/ueventd.mt6589.rc:root/ueventd.mt6589.rc \
	device/fairphone/fp1/rootdir/fstab.mt6589:root/fstab.mt6589

# In CyanogenMod, Vold supports a custom LUN file path besides the default one
# ("/sys/class/android_usb/android%d/f_mass_storage/lun/file"). This custom
# path, which like the default one is a pattern with a replaceable digit, is
# necessary to be able to share both the internal and the external SD card; the
# default LUN pattern matches a LUN file when the LUN number 0 is used, and the
# custom LUN pattern matches a LUN file when the LUN number 1 is used.
TARGET_USE_CUSTOM_LUN_FILE_PATH := /sys/class/android_usb/android0/f_mass_storage/lun%d/file

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

PRODUCT_PACKAGES += \
	com.android.future.usb.accessory

# The file frameworks/native/data/etc/handheld_core_hardware.xml defines the
# minimum set of features that an Android-compatible device has to provide.
# Unfortunately, this FOSS device tree does not provide all the needed features,
# so instead of adding that file the specific files for each of the supported
# features are added (and, of course, also files for other extra features not
# included in handheld_core_hardware.xml, if any).
#
# Note that although it is not possible to automatically change between portrait
# and landscape based on the orientation of the device (due to a lack of a
# sensors module), both screen types are indeed supported if requested
# explicitly by the application.
PRODUCT_COPY_FILES += \
	device/fairphone/fp1/permissions/android.hardware.screen.landscape.xml:system/etc/permissions/android.hardware.screen.landscape.xml \
	device/fairphone/fp1/permissions/android.hardware.screen.portrait.xml:system/etc/permissions/android.hardware.screen.portrait.xml \
	device/fairphone/fp1/permissions/android.software.app_widgets.xml:system/etc/permissions/android.software.app_widgets.xml \
	device/fairphone/fp1/permissions/android.software.device_admin.xml:system/etc/permissions/android.software.device_admin.xml \
	device/fairphone/fp1/permissions/android.software.home_screen.xml:system/etc/permissions/android.software.home_screen.xml \
	device/fairphone/fp1/permissions/android.software.input_methods.xml:system/etc/permissions/android.software.input_methods.xml \
	frameworks/native/data/etc/android.hardware.touchscreen.multitouch.distinct.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.distinct.xml \
	frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
	frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml

# Default Stagefright configuration files for built-in software codecs.
PRODUCT_COPY_FILES += \
	device/fairphone/fp1/config/media_codecs.xml:system/etc/media_codecs.xml \
	device/generic/goldfish/camera/media_profiles.xml:system/etc/media_profiles.xml
