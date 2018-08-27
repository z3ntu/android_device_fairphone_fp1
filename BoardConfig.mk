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

TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_BOARD_PLATFORM := mt6589
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a7
TARGET_CPU_SMP := true

TARGET_BOOTLOADER_BOARD_NAME := fp1

TARGET_NO_BOOTLOADER := true

TARGET_OTA_ASSERT_DEVICE := FP1,fp1

# The bootloader of the Fairphone 1 seems to use hardcoded values for
# kernel base, cmdline and pagesize in the boot and recovery images, as it is
# possible to boot images with random values in those fields. However, even if
# any value for the pagesize in the header works, the real pagesize of the image
# must be 2048. Therefore, there is no need to set BOARD_KERNEL_BASE nor
# BOARD_KERNEL_CMDLINE, but setting BOARD_KERNEL_PAGESIZE is a must (the value
# is the default one used by mkbootimg, so technically it could also be omitted,
# but just in case the default is changed in the future).
BOARD_KERNEL_PAGESIZE := 2048

# The standard kernel tree is not right at the root of the kernel repository of
# the device; as it has a MediaTek kernel layout, the standard kernel tree is
# inside the "kernel/" directory of the kernel repository.
TARGET_KERNEL_SOURCE := kernel/fairphone/fp1/kernel/

# Recovery products may have set a more specific kernel configuration; as
# BoardConfig.mk is processed after the <product>.mk the kernel configuration
# has to be set only if it was not set yet.
TARGET_KERNEL_CONFIG ?= fp1_defconfig

TARGET_USERIMAGES_USE_EXT4 := true

BOARD_BOOTIMAGE_PARTITION_SIZE := 6291456
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_PARTITION_SIZE := 132120576
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 6291456
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 681574400
BOARD_USERDATAIMAGE_PARTITION_SIZE := 1073741824
