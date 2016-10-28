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

# This Android.mk automatically patches the full tree as needed before building
# to fix bugs or add features that can not be included without modifying the
# original source code (for example, to add proper system support for software
# OpenGL ES).
#
# It is obviously one of the ugliest hacks in the history of ugly hacks and
# should be used only as a last resort.
#
# The patches are applied only when certain conditions are met; when they are
# not the patches are reversed. The basic condition is that the target device of
# the build is a Fairphone 1; as this Android.mk is processed for every build,
# not only for Fairphone 1 builds, this ensures that the tree will be cleaned
# from Fairphone 1 patches if it is used to build another device.
#
# Note, however, that although it is probably not possible to build different
# devices simultaneously in the same output directory (due to the "host" and
# "target/common" subdirectories), this system makes impossible to build
# different devices simultaneously even from the same source directory.
#
# Also, when patching files belonging to the build system, the build must be
# stopped and then launched again. Otherwise, the changes applied to the build
# system may not be taken into account. On the other hand, although build files
# may have been processed already when they are modified, the files are modified
# before the build itself starts, so patching source files does not require the
# build to be restarted.

# In order to apply the patches before any file is built two virtual filenames
# are declared, one to patch and another to revert the patches. The recipes that
# actually patch or revert the patches are assigned to the targets of those
# virtual files, and finally the files are included (using "-include", so the
# build does not fail despite that the files do not exist), which triggers the
# execution of the recipes.
# http://stackoverflow.com/questions/10726321/how-to-ensure-a-target-is-run-before-all-the-other-build-rules-in-a-makefile/10727593#10727593
#
# In order to abort the build when the build system is patched a dummy file is
# created in the $PRODUCT_OUT directory to signal that. After the recipes for
# the targets that patch or revert the patches are executed the recipes for
# a helper target are executed. The recipes for that helper target checks if the
# dummy file exists and, in that case, removes it and stops the build, notifying
# the user. As far as I know, it is not possible to perform the check in the
# main targets themselves, as the Makefile functions would be evaluated before
# the recipe was executed.

.PHONY: patch-source-tree-for-fp1 reverse-patch-source-tree-for-fp1 abort-if-build-system-was-patched abort-if-build-system-was-reverse-patched

ifneq ($(filter fp1,$(TARGET_DEVICE)),)
    -include patch-source-tree-for-fp1
    -include abort-if-build-system-was-patched
else
    -include reverse-patch-source-tree-for-fp1
    -include abort-if-build-system-was-reverse-patched
endif

ABORT_IF_BUILD_SYSTEM_WAS_MODIFIED=$(PRODUCT_OUT)/abort-if-build-system-was-modified

patch-source-tree-for-fp1:
	$(call patch-repository,frameworks/base,device/fairphone/fp1/patch/add-support-for-softwaregl.patch)
	$(call patch-repository,packages/apps/Gallery2,device/fairphone/fp1/patch/force-gles1-in-gallery-when-using-softwaregl.patch)

reverse-patch-source-tree-for-fp1:
	$(call reverse-patch-repository,frameworks/base,device/fairphone/fp1/patch/add-support-for-softwaregl.patch)
	$(call reverse-patch-repository,packages/apps/Gallery2,device/fairphone/fp1/patch/force-gles1-in-gallery-when-using-softwaregl.patch)

abort-if-build-system-was-patched: | patch-source-tree-for-fp1
	$(if $(wildcard $(ABORT_IF_BUILD_SYSTEM_WAS_MODIFIED)), \
	    $(shell rm -f $(ABORT_IF_BUILD_SYSTEM_WAS_MODIFIED)) \
	    $(error The build system was patched. Launch again the build))

abort-if-build-system-was-reverse-patched: | reverse-patch-source-tree-for-fp1
	$(if $(wildcard $(ABORT_IF_BUILD_SYSTEM_WAS_MODIFIED)), \
	    $(shell rm -f $(ABORT_IF_BUILD_SYSTEM_WAS_MODIFIED)) \
	    $(error The build system was reverse patched. Launch again the build))

patch-repository = \
    @if patch --strip=1 --directory="$1" --force --fuzz=0 --dry-run < "$2" > /dev/null; then \
        echo "Patch $1 repository for FP1 ($2)"; \
        patch --strip=1 --directory="$1" --force --fuzz=0 < "$2"; \
        if [ -n "$3" ]; then \
            touch "$3"; \
        fi \
    elif patch --strip=1 --directory="$1" --force --fuzz=0 --reverse --dry-run < "$2" > /dev/null; then \
        echo "No need to patch $1 repository for FP1 ($2)"; \
    else \
        echo "Error: $2 does not match $1 repository"; \
    fi

reverse-patch-repository = \
    @if patch --strip=1 --directory="$1" --force --fuzz=0 --reverse --dry-run < "$2" > /dev/null; then \
        echo "Reverse patch $1 repository for FP1 ($2)"; \
        patch --strip=1 --directory="$1" --force --fuzz=0 --reverse < "$2"; \
        if [ -n "$3" ]; then \
            touch "$3"; \
        fi \
    elif patch --strip=1 --directory="$1" --force --fuzz=0 --dry-run < "$2" > /dev/null; then \
        echo "No need to reverse patch $1 repository for FP1 ($2)"; \
    else \
        echo "Error: $2 does not match $1 repository"; \
    fi
