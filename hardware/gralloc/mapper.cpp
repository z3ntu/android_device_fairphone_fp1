/*
 * Copyright (C) 2008 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <limits.h>
#include <errno.h>
#include <pthread.h>
#include <unistd.h>
#include <string.h>

#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <cutils/log.h>
#include <cutils/atomic.h>
#include <cutils/hashmap.h>

#include <hardware/hardware.h>
#include <hardware/gralloc.h>

#include "gralloc_priv.h"


/* desktop Linux needs a little help with gettid() */
#if defined(ARCH_X86) && !defined(HAVE_ANDROID_OS)
#define __KERNEL__
# include <linux/unistd.h>
pid_t gettid() { return syscall(__NR_gettid);}
#undef __KERNEL__
#endif

/*****************************************************************************/

static pthread_mutex_t sMapLock = PTHREAD_MUTEX_INITIALIZER;

/*****************************************************************************/

struct HashmapEntry {
    int key;
    void* mappedAddress;
    int referenceCount;
};

static Hashmap* referenceCountedMappedBuffers;

static int gralloc_map_locked(gralloc_module_t const* module,
        buffer_handle_t handle,
        void** vaddr)
{
    private_handle_t* hnd = (private_handle_t*)handle;
    if (!(hnd->flags & private_handle_t::PRIV_FLAGS_FRAMEBUFFER)) {
        if (!referenceCountedMappedBuffers) {
            referenceCountedMappedBuffers = hashmapCreate(1, &hashmapIntHash, &hashmapIntEquals);
        }

        HashmapEntry* referenceCountedMappedBuffer = (HashmapEntry*) hashmapGet(referenceCountedMappedBuffers, &hnd->fd);
        if (referenceCountedMappedBuffer) {
            hnd->base = intptr_t(referenceCountedMappedBuffer->mappedAddress) + hnd->offset;

            referenceCountedMappedBuffer->referenceCount++;

            return 0;
        }

        size_t size = hnd->size;
        void* mappedAddress = mmap(0, size,
                PROT_READ|PROT_WRITE, MAP_SHARED, hnd->fd, 0);
        if (mappedAddress == MAP_FAILED) {
            ALOGE("Could not mmap %s", strerror(errno));
            return -errno;
        }
        hnd->base = intptr_t(mappedAddress) + hnd->offset;
        //ALOGD("gralloc_map() succeeded fd=%d, off=%d, size=%d, vaddr=%p",
        //        hnd->fd, hnd->offset, hnd->size, mappedAddress);

        HashmapEntry* hashmapEntry = (HashmapEntry*) malloc(sizeof(HashmapEntry));
        hashmapEntry->key = hnd->fd;
        hashmapEntry->mappedAddress = mappedAddress;
        hashmapEntry->referenceCount = 1;

        hashmapPut(referenceCountedMappedBuffers, &hashmapEntry->key, hashmapEntry);
    }
    *vaddr = (void*)hnd->base;
    return 0;
}

static int gralloc_map(gralloc_module_t const* module,
        buffer_handle_t handle,
        void** vaddr)
{
    pthread_mutex_lock(&sMapLock);
    int err = gralloc_map_locked(module, handle, vaddr);
    pthread_mutex_unlock(&sMapLock);
    return err;
}

static int gralloc_unmap_locked(gralloc_module_t const* module,
        buffer_handle_t handle)
{
    private_handle_t* hnd = (private_handle_t*)handle;
    if (!(hnd->flags & private_handle_t::PRIV_FLAGS_FRAMEBUFFER)) {
        if (!referenceCountedMappedBuffers) {
            ALOGE("Unmapping buffer when referenceCountedMappedBuffers was not yet initialized!: %d", hnd->fd);

            referenceCountedMappedBuffers = hashmapCreate(1, &hashmapIntHash, &hashmapIntEquals);
        }

        HashmapEntry* referenceCountedMappedBuffer = (HashmapEntry*) hashmapGet(referenceCountedMappedBuffers, &hnd->fd);
        if (referenceCountedMappedBuffer) {
            referenceCountedMappedBuffer->referenceCount--;

            if (referenceCountedMappedBuffer->referenceCount > 0) {
                hnd->base = 0;

                return 0;
            }
        } else {
            ALOGE("Unmapping buffer not registered!: %d", hnd->fd);
        }

        void* base = (void*)hnd->base;
        size_t size = hnd->size;
        //ALOGD("unmapping from %p, size=%d", base, size);
        if (munmap(base, size) < 0) {
            ALOGE("Could not unmap %s", strerror(errno));
        }

        hashmapRemove(referenceCountedMappedBuffers, &hnd->fd);
        free(referenceCountedMappedBuffer);
    }
    hnd->base = 0;
    return 0;
}

static int gralloc_unmap(gralloc_module_t const* module,
        buffer_handle_t handle)
{
    pthread_mutex_lock(&sMapLock);
    int err = gralloc_unmap_locked(module, handle);
    pthread_mutex_unlock(&sMapLock);
    return err;
}

/*****************************************************************************/

int gralloc_register_buffer(gralloc_module_t const* module,
        buffer_handle_t handle)
{
    if (private_handle_t::validate(handle) < 0)
        return -EINVAL;

    void *vaddr;
    return gralloc_map(module, handle, &vaddr);
}

int gralloc_unregister_buffer(gralloc_module_t const* module,
        buffer_handle_t handle)
{
    if (private_handle_t::validate(handle) < 0)
        return -EINVAL;

    private_handle_t* hnd = (private_handle_t*)handle;
    if (hnd->base)
        gralloc_unmap(module, handle);

    return 0;
}

int mapBuffer(gralloc_module_t const* module,
        private_handle_t* hnd)
{
    void* vaddr;
    return gralloc_map(module, hnd, &vaddr);
}

int terminateBuffer(gralloc_module_t const* module,
        private_handle_t* hnd)
{
    if (hnd->base) {
        // this buffer was mapped, unmap it now
        gralloc_unmap(module, hnd);
    }

    return 0;
}

int gralloc_lock(gralloc_module_t const* module,
        buffer_handle_t handle, int usage,
        int l, int t, int w, int h,
        void** vaddr)
{
    // this is called when a buffer is being locked for software
    // access. in thin implementation we have nothing to do since
    // not synchronization with the h/w is needed.
    // typically this is used to wait for the h/w to finish with
    // this buffer if relevant. the data cache may need to be
    // flushed or invalidated depending on the usage bits and the
    // hardware.

    if (private_handle_t::validate(handle) < 0)
        return -EINVAL;

    private_handle_t* hnd = (private_handle_t*)handle;
    *vaddr = (void*)hnd->base;
    return 0;
}

int gralloc_unlock(gralloc_module_t const* module,
        buffer_handle_t handle)
{
    // we're done with a software buffer. nothing to do in this
    // implementation. typically this is used to flush the data cache.

    if (private_handle_t::validate(handle) < 0)
        return -EINVAL;
    return 0;
}
