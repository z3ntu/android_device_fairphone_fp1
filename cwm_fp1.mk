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

PRODUCT_NAME := cwm_fp1
PRODUCT_DEVICE := fp1
PRODUCT_BRAND := ClockWorkMod
PRODUCT_MODEL := ClockWorkMod on FP1
PRODUCT_MANUFACTURER := Fairphone

# The standard configuration builds a kernel too large that causes the recovery
# image to not fit in the recovery partition. Therefore, a specific
# configuration that builds a smaller kernel targeted at recovery images is
# needed.
TARGET_KERNEL_CONFIG := fp1recovery_defconfig

# It is not really necessary, as the "Back" button works as expected. However,
# this just shows another item in the menus that go back when activated, which
# is anyway consistent with the rest of the UI in the recovery.
BOARD_HAS_NO_SELECT_BUTTON := true

# As this is a minimal CWM product Makefile it does not inherit from other
# common product configurations like "$(SRC_TARGET_DIR)/product/base.mk", so the
# ADB daemon must be explicitly included in the recovery.
PRODUCT_PACKAGES += \
	adbd
