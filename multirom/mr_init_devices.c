/*
 * Copyright (C) 2017 Daniel Calviño Sánchez <danxuliu@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdlib.h>

/**
 * The MultiROM bootloader is the first program to be run in the system, so it
 * must take care of initializing the kernel devices. However, only those
 * devices strictly needed by the bootloader should be initialized to minimize
 * the possibility of colliding with the initialization done by the actual
 * operating system.
 *
 * The MultiROM bootloader does not use ueventd or udev but its own system
 * (although derived from ueventd); mr_init_devices specifies the paths to the
 * uevent files of the devices to be initialized. A trailing '*' inits that
 * directory and all its subdirectories, but not symlinks; that is,
 * "/sys/class/input*" does not initialize any device, as its subdirectories are
 * all symlinks, but "/sys/devices/virtual/input*" does, as its subdirectories
 * are actual directories.
 */
const char* mr_init_devices[] = {
    // Graphics
    "/sys/class/graphics/fb0", // /dev/graphics/fb0

    // Input
    "/sys/class/input/event0", // /dev/input/event0 (power and volume buttons)
    "/sys/class/input/event3", // /dev/input/event3 (touchscreen)

    // Internal memory
    "/sys/class/block/mmcblk0p5", // /dev/block/mmcblk0p5 (system partition)
    "/sys/class/block/mmcblk0p6", // /dev/block/mmcblk0p6 (cache partition)
    "/sys/class/block/mmcblk0p7", // /dev/block/mmcblk0p7 (data partition)

    // External SD card
    "/sys/class/block/mmcblk1p1", // /dev/block/mmcblk1p1

    // ADB
    "/sys/class/tty/ptmx", // /dev/ptmx
    "/sys/class/misc/android_adb", // /dev/android_adb

    // USB OTG
    // Events for USB devices are generated when the device is plugged in, so
    // there is nothing to initialize when the bootloader starts.

    NULL
};
