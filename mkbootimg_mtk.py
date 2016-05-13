#!/usr/bin/env python
# coding=utf-8
#
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

from __future__ import print_function

import os
import shutil
import struct
import subprocess
import sys

if sys.hexversion < 0x02060000:
  print("Python 2.6 or newer is required", file = sys.stderr)
  sys.exit(1)

# Returns the index of the last item in the list that is equal to the given one.
def lastIndex(sourceList, item):
    return len(sourceList) - list(reversed(sourceList)).index(item) - 1

# Helper exception to signal an error with a command line argument.
class ArgumentException(ValueError):
    pass

# Returns the value of the last appearance of the given argument in the given
# argv list.
#
# It is assumed that the value of the argument is the next element to the
# argument in the argv list.
#
# If the argument is not found, ArgumentException is raised.
def getMandatoryArgumentLastValue(argv, argument):
    try:
        return argv[lastIndex(argv, argument) + 1]
    except ValueError:
        raise ArgumentException(argument + " argument not given")

# Returns a MTK header of the given type as a string.
#
# The type can be kernel, ramdisk or ramdisk-recovery. A ValueError is raised
# otherwise.
#
# The size of the file that the header will be added to is also needed.
def generateMtkHeader(headerType, fileSize):
    if headerType == "kernel":
        headerTypeId = "KERNEL"
    elif headerType == "ramdisk-boot":
        headerTypeId = "ROOTFS"
    elif headerType == "ramdisk-recovery":
        headerTypeId = "RECOVERY"
    else:
        raise ValueError("Header type '" + headerType + "' is not supported")

    header = struct.pack("<4s", "\x88\x16\x88\x58")
    header += struct.pack("<I", fileSize)
    header += struct.pack("<32s", headerTypeId)
    header += struct.pack("<472s", "\xFF" * 472)

    return header

# Writes a file to generatedFilePath that contains the appropriate MTK header
# followed by the headerless file.
def writeFileWithHeader(headerType, headerlessFilePath, generatedFilePath):
    with open(generatedFilePath, 'wb') as generatedFile:
        generatedFile.write(generateMtkHeader(headerType, os.path.getsize(headerlessFilePath)))

        with open(headerlessFilePath, 'rb') as headerlessFile:
            shutil.copyfileobj(headerlessFile, generatedFile, 1024)

# Wraps a call to mkbootimg, replacing the given kernel and ramdisk with copies
# prepended with the appropriate MTK header.
#
# The files with the headers are temporary files; they will be removed when the
# script finishes. They are created in the same directory as the original ones
# and have the same name plus ".mtk". If the ramdisk is meant to be used in a
# recovery image it must contain "recovery" somewhere in its name (in the file
# name itself, not in its path).
#
# The wrapped mkbootimg to be executed must be passed as the value of the
# "--wrapped_mkbootimg" argument.
#
# The "--wrapped_mkbootimg" will be removed from the arguments passed to
# mkbootimg itself. "--kernel" and "--ramdisk" arguments will be modified to
# pass the files with the headers instead of the original ones. The rest of the
# arguments will be passed as is to the wrapped mkbootimg.
def main(argv):

    # mkbootimg only handles the last appearance of the "--kernel" and
    # "--ramdisk" arguments.
    kernelPath = getMandatoryArgumentLastValue(argv, "--kernel")
    ramdiskPath = getMandatoryArgumentLastValue(argv, "--ramdisk")
    mkbootimgPath = getMandatoryArgumentLastValue(argv, "--wrapped_mkbootimg")

    # The ramdisk header differentiates between a boot image and a recovery
    # image. It is assumed that ramdisks for recovery images contain the string
    # "recovery" in its name (as done by the standard "build/core/Makefile").
    isRecoveryRamdisk = False
    if (ramdiskPath.split("/")[-1].find("recovery") > -1):
        isRecoveryRamdisk = True

    kernelWithHeaderPath = kernelPath + ".mtk"
    ramdiskWithHeaderPath = ramdiskPath + ".mtk"

    # Remove all "--wrapped_mkbootimg xxx" arguments (and the first element,
    # which is the name of this script) from the arguments to pass to the
    # wrapped mkbootimg.
    mkbootimgArguments = [item for index, item in enumerate(argv) if (index > 0 and item != "--wrapped_mkbootimg" and argv[index - 1] != "--wrapped_mkbootimg")]

    # Replace original kernel and ramdisk arguments with the new ones.
    mkbootimgArguments[lastIndex(mkbootimgArguments, "--kernel") + 1] = kernelWithHeaderPath
    mkbootimgArguments[lastIndex(mkbootimgArguments, "--ramdisk") + 1] = ramdiskWithHeaderPath

    # Add mkbootimg as the first argument.
    mkbootimgArguments.insert(0, mkbootimgPath)

    try:
        # Generate temporary files with MTK headers for kernel and ramdisk.
        # Original files are not modified.
        writeFileWithHeader("kernel", kernelPath, kernelWithHeaderPath)
        writeFileWithHeader("ramdisk-recovery" if isRecoveryRamdisk else "ramdisk-boot", ramdiskPath, ramdiskWithHeaderPath)

        # Call wrapped mkbootimg.
        try:
            # Use sys.stdout.write instead of print, as the stdout/stderr of
            # mkbootimg already contains a new line.
            sys.stdout.write(subprocess.check_output(mkbootimgArguments, stderr = subprocess.STDOUT))
        except OSError as exception:
            raise OSError(exception.errno, exception.strerror, mkbootimgArguments[0])
    finally:
        os.remove(kernelWithHeaderPath)
        os.remove(ramdiskWithHeaderPath)

if __name__ == '__main__':
    try:
        main(sys.argv)
    except ArgumentException as exception:
        print(exception, file = sys.stderr)
        sys.exit(2)
    except OSError as exception:
        print(exception.filename + ": " + exception.strerror, file = sys.stderr)
        sys.exit(3)
    except subprocess.CalledProcessError as exception:
        # Use sys.stderr.write instead of print, as the stdout/stderr of
        # mkbootimg already contains a new line.
        sys.stderr.write(" ".join(exception.cmd) + ": " + exception.output)
        sys.exit(3)
