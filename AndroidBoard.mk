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

# The kernel and the ramdisk of boot and recovery images for the Fairphone 1
# must include special Mediatek headers. As the "mkbootimg" command used by the
# build system can be customized through the MKBOOTIMG variable, the default
# "mkbootimg" command used by the build system is wrapped by a script that
# copies the kernel and ramdisk to temporary files with the needed Mediatek
# headers and passes those files with the headers to the "mkbootimg" command
# used by the build system.
WRAPPED_MKBOOTIMG := $(MKBOOTIMG)

BOARD_MKBOOTIMG_ARGS := --wrapped_mkbootimg $(WRAPPED_MKBOOTIMG)

MKBOOTIMG := device/fairphone/fp1/mkbootimg_mtk.py

# Make the wrapper depend on the wrapped "mkbootimg" to ensure that the wrapped
# "mkbootimg" is built when needed.
$(MKBOOTIMG): $(WRAPPED_MKBOOTIMG)



# assert-max-image-size is based on assert-max-file-size from AOSP, defined in
# build/core/definitions.mk, commit c065da23.
#
# Copyright (C) 2008 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# assert-max-image-size, defined in build/core/definitions.mk, is used by the
# build system after each image is built to ensure that it will fit its
# partition.
#
# However, it is designed for raw flash devices, and for managed flash devices
# the results are not reliable. As not only the image but also the partition
# size are rounded up based on BOARD_NAND_PAGE_SIZE and BOARD_NAND_SPARE_SIZE
# the check could consider an image too large for the real partition size to fit
# inside the rounded partition size. Therefore, flashing that image could cause
# the beginning of the next partition to the flashed one to be overwritten.
#
# A dirty workaround by setting BOARD_FLASH_BLOCK_SIZE and BOARD_NAND_PAGE_SIZE
# to 1 and BOARD_NAND_SPARE_SIZE to 0 would not work either; the sizes of the
# image and the partition would not be modified, but in this case
# assert-max-image-size could wrongly report that a tightly fitting image is too
# large, as it reserves 1% of the partition size. Although that may be needed to
# account for bad blocks in raw flash devices in managed flash devices it is
# not, as the physical device is just exposed as a block device that takes care
# internally of bad block management.
#
# Therefore, assert-max-image-size is redefined to just check whether the image
# size is smaller than the partition size.
define assert-max-image-size
$(if $(2), \
  size=$$(for i in $(1); do $(call get-file-size,$$i); echo +; done; echo 0); \
  total=$$(( $$( echo "$$size" ) )); \
  printname=$$(echo -n "$(1)" | tr " " +); \
  echo "$$printname maxsize=$(2) total=$$total"; \
  if [ "$$total" -gt "$(2)" ]; then \
    echo "error: $$printname too large ($$total > $(2))"; \
    false; \
  elif [ "$$total" -gt $$(($(2) - 32768)) ]; then \
    echo "WARNING: $$printname approaching size limit ($$total now; limit $(2))"; \
  fi \
 , \
  true \
 )
endef
