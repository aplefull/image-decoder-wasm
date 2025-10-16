#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <emscripten.h>
#include <charls/charls.h>

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

    charls_jpegls_decoder* decoder = charls_jpegls_decoder_create();
    if (!decoder) {
        return -1;
    }

    charls_jpegls_errc error = charls_jpegls_decoder_set_source_buffer(decoder, input, inputSize);
    if (error != CHARLS_JPEGLS_ERRC_SUCCESS) {
        charls_jpegls_decoder_destroy(decoder);
        return -2;
    }

    error = charls_jpegls_decoder_read_header(decoder);
    if (error != CHARLS_JPEGLS_ERRC_SUCCESS) {
        charls_jpegls_decoder_destroy(decoder);
        return -3;
    }

    charls_frame_info frame_info;
    error = charls_jpegls_decoder_get_frame_info(decoder, &frame_info);
    if (error != CHARLS_JPEGLS_ERRC_SUCCESS) {
        charls_jpegls_decoder_destroy(decoder);
        return -4;
    }

    uint32_t width = frame_info.width;
    uint32_t height = frame_info.height;
    int32_t component_count = frame_info.component_count;
    int32_t bits_per_sample = frame_info.bits_per_sample;

    size_t destination_size;
    error = charls_jpegls_decoder_get_destination_size(decoder, 0, &destination_size);
    if (error != CHARLS_JPEGLS_ERRC_SUCCESS) {
        charls_jpegls_decoder_destroy(decoder);
        return -5;
    }

    uint8_t* decoded_data = (uint8_t*)malloc(destination_size);
    if (!decoded_data) {
        charls_jpegls_decoder_destroy(decoder);
        return -6;
    }

    error = charls_jpegls_decoder_decode_to_buffer(decoder, decoded_data, destination_size, 0);
    if (error != CHARLS_JPEGLS_ERRC_SUCCESS) {
        free(decoded_data);
        charls_jpegls_decoder_destroy(decoder);
        return -7;
    }

    size_t rgba_size = width * height * 4;
    uint8_t* pixelData = (uint8_t*)malloc(rgba_size);
    if (!pixelData) {
        free(decoded_data);
        charls_jpegls_decoder_destroy(decoder);
        return -8;
    }

    if (bits_per_sample == 8) {
        if (component_count == 1) {
            for (uint32_t i = 0; i < width * height; i++) {
                uint8_t gray = decoded_data[i];
                pixelData[i * 4 + 0] = gray;
                pixelData[i * 4 + 1] = gray;
                pixelData[i * 4 + 2] = gray;
                pixelData[i * 4 + 3] = 255;
            }
        } else if (component_count == 3) {
            for (uint32_t i = 0; i < width * height; i++) {
                pixelData[i * 4 + 0] = decoded_data[i * 3 + 0];
                pixelData[i * 4 + 1] = decoded_data[i * 3 + 1];
                pixelData[i * 4 + 2] = decoded_data[i * 3 + 2];
                pixelData[i * 4 + 3] = 255;
            }
        } else if (component_count == 4) {
            memcpy(pixelData, decoded_data, rgba_size);
        } else {
            free(decoded_data);
            free(pixelData);
            charls_jpegls_decoder_destroy(decoder);
            return -9;
        }
    } else if (bits_per_sample == 16) {
        uint16_t* decoded_data_16 = (uint16_t*)decoded_data;
        if (component_count == 1) {
            for (uint32_t i = 0; i < width * height; i++) {
                uint8_t gray = decoded_data_16[i] >> 8;
                pixelData[i * 4 + 0] = gray;
                pixelData[i * 4 + 1] = gray;
                pixelData[i * 4 + 2] = gray;
                pixelData[i * 4 + 3] = 255;
            }
        } else if (component_count == 3) {
            for (uint32_t i = 0; i < width * height; i++) {
                pixelData[i * 4 + 0] = decoded_data_16[i * 3 + 0] >> 8;
                pixelData[i * 4 + 1] = decoded_data_16[i * 3 + 1] >> 8;
                pixelData[i * 4 + 2] = decoded_data_16[i * 3 + 2] >> 8;
                pixelData[i * 4 + 3] = 255;
            }
        } else if (component_count == 4) {
            for (uint32_t i = 0; i < width * height; i++) {
                pixelData[i * 4 + 0] = decoded_data_16[i * 4 + 0] >> 8;
                pixelData[i * 4 + 1] = decoded_data_16[i * 4 + 1] >> 8;
                pixelData[i * 4 + 2] = decoded_data_16[i * 4 + 2] >> 8;
                pixelData[i * 4 + 3] = decoded_data_16[i * 4 + 3] >> 8;
            }
        } else {
            free(decoded_data);
            free(pixelData);
            charls_jpegls_decoder_destroy(decoder);
            return -9;
        }
    } else {
        free(decoded_data);
        free(pixelData);
        charls_jpegls_decoder_destroy(decoder);
        return -10;
    }

    free(decoded_data);
    charls_jpegls_decoder_destroy(decoder);

    uint32_t* outView = (uint32_t*)outPtr;
    outView[0] = width;
    outView[1] = height;
    outView[2] = (uint32_t)(uintptr_t)pixelData;
    outView[3] = (uint32_t)rgba_size;

    return 0;
}
