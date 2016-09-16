/*
 * lights.c is based on device/lge/mako/liblight/lights.c from CyanogenMod,
 * commit 67bbb0a98e (branch cm-13.0).
 *
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


#define LOG_NDEBUG 0
#define LOG_TAG "lights"

#include <cutils/log.h>
#include <cutils/properties.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>

#include <sys/ioctl.h>
#include <sys/types.h>

#include <hardware/lights.h>

/******************************************************************************/

static pthread_once_t g_init = PTHREAD_ONCE_INIT;
static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;

static struct light_state_t g_notification;
static struct light_state_t g_battery;
static struct light_state_t g_attention;

char const*const RED_LED_BRIGHTNESS_FILE
        = "/sys/class/leds/red/brightness";

char const*const RED_LED_TRIGGER_FILE
        = "/sys/class/leds/red/trigger";

char const*const RED_LED_DELAY_ON_FILE
        = "/sys/class/leds/red/delay_on";

char const*const RED_LED_DELAY_OFF_FILE
        = "/sys/class/leds/red/delay_off";

char const*const GREEN_LED_BRIGHTNESS_FILE
        = "/sys/class/leds/green/brightness";

char const*const GREEN_LED_TRIGGER_FILE
        = "/sys/class/leds/green/trigger";

char const*const GREEN_LED_DELAY_ON_FILE
        = "/sys/class/leds/green/delay_on";

char const*const GREEN_LED_DELAY_OFF_FILE
        = "/sys/class/leds/green/delay_off";

char const*const BLUE_LED_BRIGHTNESS_FILE
        = "/sys/class/leds/blue/brightness";

char const*const BLUE_LED_TRIGGER_FILE
        = "/sys/class/leds/blue/trigger";

char const*const BLUE_LED_DELAY_ON_FILE
        = "/sys/class/leds/blue/delay_on";

char const*const BLUE_LED_DELAY_OFF_FILE
        = "/sys/class/leds/blue/delay_off";

char const*const LCD_FILE
        = "/sys/class/leds/lcd-backlight/brightness";

/**
 * device methods
 */

void init_globals(void)
{
    // init the mutex
    pthread_mutex_init(&g_lock, NULL);
}

static int
write_int(char const* path, int value)
{
    int fd;
    static int already_warned = 0;

    fd = open(path, O_RDWR);
    if (fd >= 0) {
        int bufSize = 20;
        char buffer[bufSize];
        int bytes = snprintf(buffer, bufSize, "%d\n", value);
        int amt = write(fd, buffer, bytes);
        close(fd);
        return amt == -1 ? -errno : 0;
    } else {
        if (already_warned == 0) {
            ALOGE("write_int failed to open %s\n", path);
            already_warned = 1;
        }
        return -errno;
    }
}

static int
write_string(char const* path, const char* string)
{
    int fd;
    static int already_warned = 0;

    fd = open(path, O_RDWR);
    if (fd >= 0) {
        int amt = write(fd, string, strlen(string));
        close(fd);
        return amt == -1 ? -errno : 0;
    } else {
        if (already_warned == 0) {
            ALOGE("write_string failed to open %s\n", path);
            already_warned = 1;
        }
        return -errno;
    }
}

static int
is_lit(struct light_state_t const* state)
{
    return state->color & 0x00ffffff;
}

static int
rgb_to_brightness(struct light_state_t const* state)
{
    int color = state->color & 0x00ffffff;
    return ((77 * ((color >> 16) & 0x00ff))
            + (150*((color >> 8) & 0x00ff))
            + (29 * (color & 0x00ff))) >> 8;
}

static int
set_light_backlight(struct light_device_t* dev,
        struct light_state_t const* state)
{
    int err = 0;
    int brightness = rgb_to_brightness(state);

    pthread_mutex_lock(&g_lock);
    err = write_int(LCD_FILE, brightness);
    pthread_mutex_unlock(&g_lock);

    return err;
}

static int
set_notification_led_locked(struct light_device_t* dev,
        struct light_state_t const* state)
{
    int red, green, blue;
    int onMS, offMS;

    switch (state->flashMode) {
        case LIGHT_FLASH_TIMED:
            onMS = state->flashOnMS;
            offMS = state->flashOffMS;
            break;
        case LIGHT_FLASH_NONE:
        default:
            onMS = 0;
            offMS = 0;
            break;
    }

    red = (state->color >> 16) & 0xFF;
    green = (state->color >> 8) & 0xFF;
    blue = state->color & 0xFF;

    if (onMS > 0 && offMS > 0 && is_lit(state)) {
        // The kernel does not seem to provide a system to blink several LEDs in
        // synchronization. In order to try to minimize the phase difference
        // between several blinking LEDs to get a combined color each stage of
        // the blink setup is performed for all the LEDs together, instead of
        // performing all the stages together for each LED, as the blinking
        // starts when the "delay_off" attribute is set.
        //
        // Unfortunately, even with this approach, the result is far from
        // correct...

        if (red != 0) write_string(RED_LED_TRIGGER_FILE, "timer");
        if (green != 0) write_string(GREEN_LED_TRIGGER_FILE, "timer");
        if (blue != 0) write_string(BLUE_LED_TRIGGER_FILE, "timer");

        if (red != 0) write_int(RED_LED_DELAY_ON_FILE, onMS);
        if (green != 0) write_int(GREEN_LED_DELAY_ON_FILE, onMS);
        if (blue != 0) write_int(BLUE_LED_DELAY_ON_FILE, onMS);

        if (red != 0) write_int(RED_LED_DELAY_OFF_FILE, offMS);
        if (green != 0) write_int(GREEN_LED_DELAY_OFF_FILE, offMS);
        if (blue != 0) write_int(BLUE_LED_DELAY_OFF_FILE, offMS);
    } else {
        write_string(RED_LED_TRIGGER_FILE, "none");
        write_int(RED_LED_BRIGHTNESS_FILE, red);

        write_string(GREEN_LED_TRIGGER_FILE, "none");
        write_int(GREEN_LED_BRIGHTNESS_FILE, green);

        write_string(BLUE_LED_TRIGGER_FILE, "none");
        write_int(BLUE_LED_BRIGHTNESS_FILE, blue);
    }

    ALOGV("%s: red %d green %d blue %d onMS %d offMS %d",
            __func__, red, green, blue, onMS, offMS);

    return 0;
}

static void
update_notification_led_locked(struct light_device_t* dev)
{
    if (is_lit(&g_attention)) {
        set_notification_led_locked(dev, &g_attention);
    } else if (is_lit(&g_notification)) {
        set_notification_led_locked(dev, &g_notification);
    } else {
        set_notification_led_locked(dev, &g_battery);
    }
}

static int
set_light_battery(struct light_device_t* dev,
        struct light_state_t const* state)
{
    pthread_mutex_lock(&g_lock);
    g_battery = *state;
    update_notification_led_locked(dev);
    pthread_mutex_unlock(&g_lock);
    return 0;
}

static int
set_light_notifications(struct light_device_t* dev,
        struct light_state_t const* state)
{
    pthread_mutex_lock(&g_lock);
    g_notification = *state;
    update_notification_led_locked(dev);
    pthread_mutex_unlock(&g_lock);
    return 0;
}

static int
set_light_attention(struct light_device_t* dev,
        struct light_state_t const* state)
{
    pthread_mutex_lock(&g_lock);
    g_attention = *state;
    // PowerManagerService::setAttentionLightInternal turns off the attention
    // light by setting flashOnMS = flashOffMS = 0
    if (g_attention.flashOnMS == 0 && g_attention.flashOffMS == 0) {
        g_attention.color = 0;
    }
    update_notification_led_locked(dev);
    pthread_mutex_unlock(&g_lock);
    return 0;
}


/** Close the lights device */
static int
close_lights(struct light_device_t *dev)
{
    if (dev) {
        free(dev);
    }
    return 0;
}

/**
 * module methods
 */

/** Open a new instance of a lights device using name */
static int open_lights(const struct hw_module_t* module, char const* name,
        struct hw_device_t** device)
{
    int (*set_light)(struct light_device_t* dev,
            struct light_state_t const* state);

    if (0 == strcmp(LIGHT_ID_BACKLIGHT, name)) {
        set_light = set_light_backlight;
    } else if (0 == strcmp(LIGHT_ID_NOTIFICATIONS, name)) {
        set_light = set_light_notifications;
    } else if (0 == strcmp(LIGHT_ID_BATTERY, name)) {
        set_light = set_light_battery;
    } else if (0 == strcmp(LIGHT_ID_ATTENTION, name)) {
        set_light = set_light_attention;
    } else {
        return -EINVAL;
    }

    pthread_once(&g_init, init_globals);

    struct light_device_t *dev = malloc(sizeof(struct light_device_t));
    memset(dev, 0, sizeof(*dev));

    dev->common.tag = HARDWARE_DEVICE_TAG;
    dev->common.version = 0;
    dev->common.module = (struct hw_module_t*)module;
    dev->common.close = (int (*)(struct hw_device_t*))close_lights;
    dev->set_light = set_light;

    *device = (struct hw_device_t*)dev;
    return 0;
}

static struct hw_module_methods_t lights_module_methods = {
    .open =  open_lights,
};

/*
 * The lights Module
 */
struct hw_module_t HAL_MODULE_INFO_SYM = {
    .tag = HARDWARE_MODULE_TAG,
    .version_major = 1,
    .version_minor = 0,
    .id = LIGHTS_HARDWARE_MODULE_ID,
    .name = "mako lights module",
    .author = "Google, Inc., AOKP, CyanogenMod",
    .methods = &lights_module_methods,
};
