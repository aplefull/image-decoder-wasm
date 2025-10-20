#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <emscripten.h>
#include <JXRGlue.h>

EMSCRIPTEN_KEEPALIVE
uint8_t* alloc(size_t size) {
    return (uint8_t*)malloc(size);
}

EMSCRIPTEN_KEEPALIVE
void free_mem(uint8_t* ptr) {
    if (ptr) free(ptr);
}

static inline U8 float_to_u8(float value) {
    if (value <= 0.0f) return 0;
    if (value >= 1.0f) return 255;
    return (U8)(value * 255.0f + 0.5f);
}

EMSCRIPTEN_KEEPALIVE
int decode(uint8_t* input, size_t inputSize, uint8_t* outPtr) {
    if (!input || inputSize == 0) return -10;

    PKFactory* pFactory = NULL;
    PKCodecFactory* pCodecFactory = NULL;
    PKImageDecode* pDecoder = NULL;
    PKFormatConverter* pConverter = NULL;
    ERR err = WMP_errSuccess;

    struct WMPStream* pStream = NULL;
    PKRect rect = {0};
    I32 width = 0, height = 0;
    U8* pixelData = NULL;
    void* tempData = NULL;

    err = PKCreateFactory(&pFactory, PK_SDK_VERSION);
    if (Failed(err)) {
        printf("PKCreateFactory failed: %ld\n", (long)err);
        return err;
    }

    err = PKCreateCodecFactory(&pCodecFactory, WMP_SDK_VERSION);
    if (Failed(err)) {
        printf("PKCreateCodecFactory failed: %ld\n", (long)err);
        goto Cleanup;
    }

    err = pFactory->CreateStreamFromMemory(&pStream, input, inputSize);
    if (Failed(err)) {
        printf("CreateStreamFromMemory failed: %ld\n", (long)err);
        goto Cleanup;
    }

    err = PKImageDecode_Create_WMP(&pDecoder);
    if (Failed(err)) {
        printf("PKImageDecode_Create_WMP failed: %ld\n", (long)err);
        goto Cleanup;
    }

    err = pDecoder->Initialize(pDecoder, pStream);
    if (Failed(err)) {
        printf("Initialize failed: %ld\n", (long)err);
        goto Cleanup;
    }

    err = pDecoder->GetSize(pDecoder, &width, &height);
    if (Failed(err)) {
        printf("GetSize failed: %ld\n", (long)err);
        goto Cleanup;
    }

    PKPixelFormatGUID srcFormat;
    err = pDecoder->GetPixelFormat(pDecoder, &srcFormat);
    if (Failed(err)) {
        printf("GetPixelFormat failed: %ld\n", (long)err);
        goto Cleanup;
    }

    err = pCodecFactory->CreateFormatConverter(&pConverter);
    if (Failed(err)) {
        printf("CreateFormatConverter failed: %ld\n", (long)err);
        goto Cleanup;
    }

    err = pConverter->Initialize(pConverter, pDecoder, NULL, GUID_PKPixelFormat128bppRGBAFloat);
    if (Failed(err)) {
        printf("Converter Initialize failed: %ld\n", (long)err);
        goto Cleanup;
    }

    rect.X = 0;
    rect.Y = 0;
    rect.Width = width;
    rect.Height = height;

    size_t outputSize = (size_t)width * (size_t)height * 4;
    size_t tempSize = (size_t)width * (size_t)height * 16;

    pixelData = (U8*)malloc(outputSize);
    tempData = malloc(tempSize);

    if (!pixelData || !tempData) {
        err = WMP_errOutOfMemory;
        printf("malloc failed\n");
        goto Cleanup;
    }

    U32 stride = width * 16;
    err = pConverter->Copy(pConverter, &rect, (U8*)tempData, stride);
    if (Failed(err)) {
        printf("Copy failed: %ld\n", (long)err);
        goto Cleanup;
    }

    float* floatPixels = (float*)tempData;
    for (I32 i = 0; i < width * height; i++) {
        float r = floatPixels[i * 4 + 0];
        float g = floatPixels[i * 4 + 1];
        float b = floatPixels[i * 4 + 2];
        float a = floatPixels[i * 4 + 3];

        pixelData[i * 4 + 0] = float_to_u8(r);
        pixelData[i * 4 + 1] = float_to_u8(g);
        pixelData[i * 4 + 2] = float_to_u8(b);
        pixelData[i * 4 + 3] = (a == 0.0f) ? 255 : float_to_u8(a);
    }

    uint32_t* outView = (uint32_t*)outPtr;
    outView[0] = (uint32_t)width;
    outView[1] = (uint32_t)height;
    outView[2] = (uint32_t)(uintptr_t)pixelData;
    outView[3] = (uint32_t)outputSize;

Cleanup:
    if (tempData) free(tempData);
    if (pConverter) pConverter->Release(&pConverter);
    if (pDecoder) pDecoder->Release(&pDecoder);
    if (pStream) pStream->Close(&pStream);
    if (pCodecFactory) pCodecFactory->Release(&pCodecFactory);
    if (pFactory) pFactory->Release(&pFactory);

    if (Failed(err) && pixelData) {
        free(pixelData);
        return err;
    }

    return 0;
}
