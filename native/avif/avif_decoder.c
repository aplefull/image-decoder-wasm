#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <avif/avif.h>
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
    if (!input || inputSize == 0) return -1;

    avifDecoder* decoder = avifDecoderCreate();
    if (!decoder) return -1;

    decoder->strictFlags = AVIF_STRICT_DISABLED;

    avifResult result = avifDecoderSetIOMemory(decoder, input, inputSize);
    if (result != AVIF_RESULT_OK) {
        avifDecoderDestroy(decoder);
        return result;
    }

    result = avifDecoderParse(decoder);
    if (result != AVIF_RESULT_OK) {
        avifDecoderDestroy(decoder);
        return result;
    }

    result = avifDecoderNextImage(decoder);
    if (result != AVIF_RESULT_OK) {
        avifDecoderDestroy(decoder);
        return result;
    }

    avifImage* image = decoder->image;

    avifImage* outputImage = avifImageCreateEmpty();
    result = avifDecoderRead(decoder, outputImage);
    if (result != AVIF_RESULT_OK) {
        avifImageDestroy(outputImage);
        avifDecoderDestroy(decoder);
        return result;
    }

    avifRGBImage rgb;
    avifRGBImageSetDefaults(&rgb, outputImage);

    rgb.format = AVIF_RGB_FORMAT_RGBA;
    rgb.depth = 8;
    rgb.chromaUpsampling = AVIF_CHROMA_UPSAMPLING_AUTOMATIC;
    rgb.ignoreAlpha = AVIF_FALSE;
    rgb.alphaPremultiplied = AVIF_FALSE;

    result = avifRGBImageAllocatePixels(&rgb);
    if (result != AVIF_RESULT_OK) {
        avifImageDestroy(outputImage);
        avifDecoderDestroy(decoder);
        return result;
    }

    result = avifImageYUVToRGB(outputImage, &rgb);
    if (result != AVIF_RESULT_OK) {
        avifRGBImageFreePixels(&rgb);
        avifImageDestroy(outputImage);
        avifDecoderDestroy(decoder);
        return result;
    }

    uint32_t* outView = (uint32_t*)outPtr;
    outView[0] = outputImage->width;
    outView[1] = outputImage->height;

    size_t dataSize = rgb.rowBytes * outputImage->height;
    uint8_t* pixelData = (uint8_t*)malloc(dataSize);
    memcpy(pixelData, rgb.pixels, dataSize);

    outView[2] = (uint32_t)(uintptr_t)pixelData;
    outView[3] = (uint32_t)dataSize;

    avifRGBImageFreePixels(&rgb);
    avifImageDestroy(outputImage);
    avifDecoderDestroy(decoder);

    return 0;
}
