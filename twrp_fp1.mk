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

PRODUCT_NAME := twrp_fp1
PRODUCT_DEVICE := fp1
PRODUCT_BRAND := TWRP
PRODUCT_MODEL := Team Win Recovery Project on FP1
PRODUCT_MANUFACTURER := Fairphone

# The standard configuration builds a kernel too large that causes the recovery
# image to not fit in the recovery partition. Therefore, a specific
# configuration that builds a smaller kernel targeted at recovery images is
# needed.
TARGET_KERNEL_CONFIG := fp1recovery_defconfig

# TWRP reads the partition configuration, which uses a TWRP-specific format,
# from "/etc/twrp.fstab", so the TWRP-specific fstab file has to be copied to
# "recovery/root/etc/twrp.fstab".
#
# TWRP does not use Vold, so there is no need to copy the recovery.fstab file to
# "root/fstab.mt6589" or "recovery/root/fstab.mt6589".
PRODUCT_COPY_FILES += \
	device/fairphone/fp1/twrp.fstab:recovery/root/etc/twrp.fstab

# As this is a minimal TWRP product Makefile it does not inherit from other
# common product configurations like "$(SRC_TARGET_DIR)/product/base.mk", so the
# ADB daemon must be explicitly included in the recovery.
PRODUCT_PACKAGES += \
	adbd

# The Fairphone 1 display has a resolution of 540x960, which is one of the
# values associated to PORTRAIT_MDPI in "bootable/recovery/gui/Android.mk" in
# the conversion from the old DEVICE_RESOLUTION flag to the new TW_THEME flag.
TW_THEME := portrait_mdpi

# The Fairphone 1 comes already rooted, so there is no need to install SuperSu.
# Moreover, as far as I know, SuperSu is proprietary software, and I would like
# to keep proprietary software to a minimum, specially when there are Free/Open
# Source Software alternatives.
TW_EXCLUDE_SUPERSU := true

# The default LUN file path used by TWRP is
# "/sys/class/android_usb/android0/f_mass_storage/lun%d/file". However, the LUN
# files in the Fairphone 1 are located in "[...]/lun/file" and
# "[...]/lun1/file"; although the second one matches the default path the first
# one does not, which causes an error when trying to mount the storage and also
# prevents the second one from being used. Therefore, a custom LUN file path
# that matches the path to the first LUN file must be used.
#
# As the code expects the path to contain no regular expression or a regular
# expression with a replaceable digit it is not possible to match both the first
# and second LUN file paths with a single path. Due to this only one storage can
# be mounted at a time (using the first LUN), but this does not limit which
# storages can be mounted; simply changing the current storage before mounting
# it is enough to mount a different one.
TARGET_USE_CUSTOM_LUN_FILE_PATH := /sys/class/android_usb/android0/f_mass_storage/lun/file
