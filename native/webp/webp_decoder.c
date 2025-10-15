#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <webp/decode.h>
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

    int width, height;
    
    // Get WebP image dimensions
    if (!WebPGetInfo(input, inputSize, &width, &height)) {
        return -1;
    }

    printf("WebP image: width=%d height=%d\n", width, height);

    // Decode to RGBA
    uint8_t* pixelData = WebPDecodeRGBA(input, inputSize, &width, &height);
    
    if (!pixelData) {
        return -2;
    }

    size_t dataSize = width * height * 4;

    uint32_t* outView = (uint32_t*)outPtr;
    outView[0] = width;
    outView[1] = height;
    outView[2] = (uint32_t)(uintptr_t)pixelData;
    outView[3] = (uint32_t)dataSize;

    return 0;
}
