#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <emscripten.h>
#include <libraw/libraw.h>

EMSCRIPTEN_KEEPALIVE
uint8_t* alloc(size_t size) {
    return (uint8_t*)malloc(size);
}

EMSCRIPTEN_KEEPALIVE
void free_mem(uint8_t* ptr) {
    if (ptr) free(ptr);
}

EMSCRIPTEN_KEEPALIVE
int can_decode(uint8_t* input, size_t inputSize) {
    if (!input || inputSize == 0) return 0;

    libraw_data_t* rawData = libraw_init(0);
    if (!rawData) {
        return 0;
    }

    int ret = libraw_open_buffer(rawData, input, inputSize);
    libraw_close(rawData);

    return (ret == LIBRAW_SUCCESS) ? 1 : 0;
}

EMSCRIPTEN_KEEPALIVE
int decode(uint8_t* input, size_t inputSize, uint8_t* outPtr) {
    if (!input || inputSize == 0) return -10;

    libraw_data_t* rawData = libraw_init(0);
    if (!rawData) {
        return -1;
    }

    int ret = libraw_open_buffer(rawData, input, inputSize);
    if (ret != LIBRAW_SUCCESS) {
        libraw_close(rawData);
        return -2;
    }

    ret = libraw_unpack(rawData);
    if (ret != LIBRAW_SUCCESS) {
        libraw_close(rawData);
        return -3;
    }

    ret = libraw_dcraw_process(rawData);
    if (ret != LIBRAW_SUCCESS) {
        libraw_close(rawData);
        return -4;
    }

    libraw_processed_image_t* image = libraw_dcraw_make_mem_image(rawData, &ret);
    if (!image) {
        libraw_close(rawData);
        return -5;
    }

    uint32_t width = image->width;
    uint32_t height = image->height;
    uint16_t colors = image->colors;
    uint16_t bits = image->bits;

    if (colors != 3 || (bits != 8 && bits != 16)) {
        libraw_dcraw_clear_mem(image);
        libraw_close(rawData);
        return -6;
    }

    size_t rgba_size = width * height * 4;
    uint8_t* pixelData = (uint8_t*)malloc(rgba_size);
    if (!pixelData) {
        libraw_dcraw_clear_mem(image);
        libraw_close(rawData);
        return -7;
    }

    if (bits == 8) {
        uint8_t* src = image->data;
        for (size_t i = 0; i < width * height; i++) {
            pixelData[i * 4 + 0] = src[i * 3 + 0];
            pixelData[i * 4 + 1] = src[i * 3 + 1];
            pixelData[i * 4 + 2] = src[i * 3 + 2];
            pixelData[i * 4 + 3] = 255;
        }
    } else {
        uint16_t* src = (uint16_t*)image->data;
        for (size_t i = 0; i < width * height; i++) {
            pixelData[i * 4 + 0] = src[i * 3 + 0] >> 8;
            pixelData[i * 4 + 1] = src[i * 3 + 1] >> 8;
            pixelData[i * 4 + 2] = src[i * 3 + 2] >> 8;
            pixelData[i * 4 + 3] = 255;
        }
    }

    libraw_dcraw_clear_mem(image);
    libraw_close(rawData);

    uint32_t* outView = (uint32_t*)outPtr;
    outView[0] = width;
    outView[1] = height;
    outView[2] = (uint32_t)(uintptr_t)pixelData;
    outView[3] = (uint32_t)rgba_size;

    return 0;
}
