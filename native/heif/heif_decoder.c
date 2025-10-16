#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <libheif/heif.h>
#include <emscripten.h>

EMSCRIPTEN_KEEPALIVE
uint8_t* alloc(size_t size) {
    return (uint8_t*)malloc(size);
}

EMSCRIPTEN_KEEPALIVE
void free_mem(uint8_t* ptr) {
    if (ptr) free(ptr);
}

EMSCRIPTEN_KEEPALIVE
int decode(uint8_t* input, size_t inputSize, uint8_t* outPtr) {
    if (!input || inputSize == 0) return -10;

    struct heif_context* ctx = heif_context_alloc();
    if (!ctx) return -1;

    struct heif_error error = heif_context_read_from_memory_without_copy(ctx, input, inputSize, NULL);
    if (error.code != heif_error_Ok) {
        heif_context_free(ctx);
        return -2 * 100 - error.code;
    }

    struct heif_image_handle* handle;
    error = heif_context_get_primary_image_handle(ctx, &handle);
    if (error.code != heif_error_Ok) {
        heif_context_free(ctx);
        return -3 * 100 - error.code;
    }

    int width = heif_image_handle_get_width(handle);
    int height = heif_image_handle_get_height(handle);

    struct heif_image* img;
    error = heif_decode_image(handle, &img, heif_colorspace_RGB, heif_chroma_interleaved_RGBA, NULL);
    if (error.code != heif_error_Ok) {
        heif_image_handle_release(handle);
        heif_context_free(ctx);
        return -4 * 100 - error.code;
    }

    int stride;
    const uint8_t* data = heif_image_get_plane_readonly(img, heif_channel_interleaved, &stride);

    if (!data) {
        heif_image_release(img);
        heif_image_handle_release(handle);
        heif_context_free(ctx);
        return -5 * 100;
    }

    size_t dataSize = stride * height;
    uint8_t* pixelData = (uint8_t*)malloc(dataSize);
    
    if (stride == width * 4) {
        memcpy(pixelData, data, dataSize);
    } else {
        for (int y = 0; y < height; y++) {
            memcpy(pixelData + y * width * 4, data + y * stride, width * 4);
        }
        dataSize = width * height * 4;
    }

    uint32_t* outView = (uint32_t*)outPtr;
    outView[0] = width;
    outView[1] = height;
    outView[2] = (uint32_t)(uintptr_t)pixelData;
    outView[3] = (uint32_t)dataSize;

    heif_image_release(img);
    heif_image_handle_release(handle);
    heif_context_free(ctx);

    return 0;
}
