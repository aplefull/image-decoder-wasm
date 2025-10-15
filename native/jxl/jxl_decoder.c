#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <jxl/decode.h>
#include <jxl/resizable_parallel_runner.h>
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

    JxlDecoder* dec = JxlDecoderCreate(NULL);
    if (!dec) return -1;

    void* runner = JxlResizableParallelRunnerCreate(NULL);
    if (JxlDecoderSetParallelRunner(dec, JxlResizableParallelRunner, runner) != JXL_DEC_SUCCESS) {
        JxlResizableParallelRunnerDestroy(runner);
        JxlDecoderDestroy(dec);
        return -2;
    }

    if (JxlDecoderSubscribeEvents(dec, JXL_DEC_BASIC_INFO | JXL_DEC_FULL_IMAGE) != JXL_DEC_SUCCESS) {
        JxlResizableParallelRunnerDestroy(runner);
        JxlDecoderDestroy(dec);
        return -3;
    }

    if (JxlDecoderSetInput(dec, input, inputSize) != JXL_DEC_SUCCESS) {
        JxlResizableParallelRunnerDestroy(runner);
        JxlDecoderDestroy(dec);
        return -4;
    }

    JxlDecoderCloseInput(dec);

    JxlBasicInfo info;
    JxlPixelFormat format = {4, JXL_TYPE_UINT8, JXL_NATIVE_ENDIAN, 0};
    uint8_t* pixelData = NULL;
    size_t dataSize = 0;

    JxlDecoderStatus status;
    while (1) {
        status = JxlDecoderProcessInput(dec);

        if (status == JXL_DEC_ERROR) {
            if (pixelData) free(pixelData);
            JxlResizableParallelRunnerDestroy(runner);
            JxlDecoderDestroy(dec);
            return -5;
        } else if (status == JXL_DEC_NEED_MORE_INPUT) {
            if (pixelData) free(pixelData);
            JxlResizableParallelRunnerDestroy(runner);
            JxlDecoderDestroy(dec);
            return -6;
        } else if (status == JXL_DEC_BASIC_INFO) {
            if (JxlDecoderGetBasicInfo(dec, &info) != JXL_DEC_SUCCESS) {
                if (pixelData) free(pixelData);
                JxlResizableParallelRunnerDestroy(runner);
                JxlDecoderDestroy(dec);
                return -7;
            }

            printf("JXL image: width=%d height=%d bits_per_sample=%d\n", 
                   info.xsize, info.ysize, info.bits_per_sample);

            JxlResizableParallelRunnerSetThreads(runner, 
                JxlResizableParallelRunnerSuggestThreads(info.xsize, info.ysize));

        } else if (status == JXL_DEC_NEED_IMAGE_OUT_BUFFER) {
            if (JxlDecoderImageOutBufferSize(dec, &format, &dataSize) != JXL_DEC_SUCCESS) {
                if (pixelData) free(pixelData);
                JxlResizableParallelRunnerDestroy(runner);
                JxlDecoderDestroy(dec);
                return -8;
            }

            pixelData = (uint8_t*)malloc(dataSize);
            if (!pixelData) {
                JxlResizableParallelRunnerDestroy(runner);
                JxlDecoderDestroy(dec);
                return -9;
            }

            if (JxlDecoderSetImageOutBuffer(dec, &format, pixelData, dataSize) != JXL_DEC_SUCCESS) {
                free(pixelData);
                JxlResizableParallelRunnerDestroy(runner);
                JxlDecoderDestroy(dec);
                return -10;
            }

        } else if (status == JXL_DEC_FULL_IMAGE) {
            // Image decoded successfully
            continue;
        } else if (status == JXL_DEC_SUCCESS) {
            // All processing done
            break;
        } else {
            if (pixelData) free(pixelData);
            JxlResizableParallelRunnerDestroy(runner);
            JxlDecoderDestroy(dec);
            return -11;
        }
    }

    if (!pixelData) {
        JxlResizableParallelRunnerDestroy(runner);
        JxlDecoderDestroy(dec);
        return -12;
    }

    uint32_t* outView = (uint32_t*)outPtr;
    outView[0] = info.xsize;
    outView[1] = info.ysize;
    outView[2] = (uint32_t)(uintptr_t)pixelData;
    outView[3] = (uint32_t)dataSize;

    JxlResizableParallelRunnerDestroy(runner);
    JxlDecoderDestroy(dec);

    return 0;
}
