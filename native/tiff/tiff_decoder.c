#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <emscripten.h>
#include <tiffio.h>

EMSCRIPTEN_KEEPALIVE
uint8_t* alloc(size_t size) {
    return (uint8_t*)malloc(size);
}

EMSCRIPTEN_KEEPALIVE
void free_mem(uint8_t* ptr) {
    if (ptr) free(ptr);
}

typedef struct {
    const uint8_t* data;
    size_t size;
    size_t offset;
} MemoryBuffer;

static tmsize_t tiff_read_proc(thandle_t handle, void* buf, tmsize_t size) {
    MemoryBuffer* mem = (MemoryBuffer*)handle;
    size_t available = mem->size - mem->offset;
    size_t to_read = (size_t)size < available ? (size_t)size : available;

    if (to_read > 0) {
        memcpy(buf, mem->data + mem->offset, to_read);
        mem->offset += to_read;
    }

    return (tmsize_t)to_read;
}

static tmsize_t tiff_write_proc(thandle_t handle, void* buf, tmsize_t size) {
    (void)handle;
    (void)buf;
    (void)size;
    return 0;
}

static toff_t tiff_seek_proc(thandle_t handle, toff_t offset, int whence) {
    MemoryBuffer* mem = (MemoryBuffer*)handle;

    switch (whence) {
        case SEEK_SET:
            mem->offset = (size_t)offset;
            break;
        case SEEK_CUR:
            mem->offset += (size_t)offset;
            break;
        case SEEK_END:
            mem->offset = mem->size + (size_t)offset;
            break;
        default:
            return -1;
    }

    if (mem->offset > mem->size) {
        mem->offset = mem->size;
    }

    return (toff_t)mem->offset;
}

static int tiff_close_proc(thandle_t handle) {
    (void)handle;
    return 0;
}

static toff_t tiff_size_proc(thandle_t handle) {
    MemoryBuffer* mem = (MemoryBuffer*)handle;
    return (toff_t)mem->size;
}

static int tiff_map_proc(thandle_t handle, void** base, toff_t* size) {
    MemoryBuffer* mem = (MemoryBuffer*)handle;
    *base = (void*)mem->data;
    *size = (toff_t)mem->size;
    return 1;
}

static void tiff_unmap_proc(thandle_t handle, void* base, toff_t size) {
    (void)handle;
    (void)base;
    (void)size;
}

EMSCRIPTEN_KEEPALIVE
int decode(uint8_t* input, size_t inputSize, uint8_t* outPtr) {
    if (!input || inputSize == 0) return -10;

    MemoryBuffer mem_buffer;
    mem_buffer.data = input;
    mem_buffer.size = inputSize;
    mem_buffer.offset = 0;

    TIFFSetErrorHandler(NULL);
    TIFFSetWarningHandler(NULL);

    TIFF* tif = TIFFClientOpen(
        "memory",
        "r",
        (thandle_t)&mem_buffer,
        tiff_read_proc,
        tiff_write_proc,
        tiff_seek_proc,
        tiff_close_proc,
        tiff_size_proc,
        tiff_map_proc,
        tiff_unmap_proc
    );

    if (!tif) {
        return -1;
    }

    uint32_t width = 0, height = 0;
    uint16_t samples_per_pixel = 0;
    uint16_t bits_per_sample = 0;
    uint16_t photometric = 0;

    TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &width);
    TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &height);
    TIFFGetField(tif, TIFFTAG_SAMPLESPERPIXEL, &samples_per_pixel);
    TIFFGetField(tif, TIFFTAG_BITSPERSAMPLE, &bits_per_sample);
    TIFFGetField(tif, TIFFTAG_PHOTOMETRIC, &photometric);

    if (width == 0 || height == 0) {
        TIFFClose(tif);
        return -2;
    }

    size_t rgba_size = width * height * 4;
    uint8_t* pixelData = (uint8_t*)malloc(rgba_size);

    if (!pixelData) {
        TIFFClose(tif);
        return -3;
    }

    if (!TIFFReadRGBAImageOriented(tif, width, height, (uint32_t*)pixelData, ORIENTATION_TOPLEFT, 0)) {
        free(pixelData);
        TIFFClose(tif);
        return -4;
    }

    for (size_t i = 0; i < width * height; i++) {
        uint8_t r = pixelData[i * 4 + 0];
        uint8_t g = pixelData[i * 4 + 1];
        uint8_t b = pixelData[i * 4 + 2];
        uint8_t a = pixelData[i * 4 + 3];

        pixelData[i * 4 + 0] = r;
        pixelData[i * 4 + 1] = g;
        pixelData[i * 4 + 2] = b;
        pixelData[i * 4 + 3] = a;
    }

    TIFFClose(tif);

    uint32_t* outView = (uint32_t*)outPtr;
    outView[0] = width;
    outView[1] = height;
    outView[2] = (uint32_t)(uintptr_t)pixelData;
    outView[3] = (uint32_t)rgba_size;

    return 0;
}
