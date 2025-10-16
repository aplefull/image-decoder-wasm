#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <emscripten.h>
#include <jpeglib.h>
#include <jerror.h>

EMSCRIPTEN_KEEPALIVE
uint8_t* alloc(size_t size) {
    return (uint8_t*)malloc(size);
}

EMSCRIPTEN_KEEPALIVE
void free_mem(uint8_t* ptr) {
    if (ptr) free(ptr);
}

struct mem_source_mgr {
    struct jpeg_source_mgr pub;
    const uint8_t* data;
    size_t size;
};

static void init_source(j_decompress_ptr cinfo) {
    (void)cinfo;
}

static boolean fill_input_buffer(j_decompress_ptr cinfo) {
    struct mem_source_mgr* src = (struct mem_source_mgr*)cinfo->src;
    static const JOCTET eoi_buffer[2] = { 0xFF, JPEG_EOI };
    src->pub.next_input_byte = eoi_buffer;
    src->pub.bytes_in_buffer = 2;
    return TRUE;
}

static void skip_input_data(j_decompress_ptr cinfo, long num_bytes) {
    struct mem_source_mgr* src = (struct mem_source_mgr*)cinfo->src;
    if (num_bytes > 0) {
        while (num_bytes > (long)src->pub.bytes_in_buffer) {
            num_bytes -= (long)src->pub.bytes_in_buffer;
            fill_input_buffer(cinfo);
        }
        src->pub.next_input_byte += num_bytes;
        src->pub.bytes_in_buffer -= num_bytes;
    }
}

static void term_source(j_decompress_ptr cinfo) {
    (void)cinfo;
}

static void jpeg_mem_src_custom(j_decompress_ptr cinfo, const uint8_t* buffer, size_t size) {
    struct mem_source_mgr* src;
    if (cinfo->src == NULL) {
        cinfo->src = (struct jpeg_source_mgr*)
            (*cinfo->mem->alloc_small)((j_common_ptr)cinfo, JPOOL_PERMANENT,
                                      sizeof(struct mem_source_mgr));
    }
    src = (struct mem_source_mgr*)cinfo->src;
    src->pub.init_source = init_source;
    src->pub.fill_input_buffer = fill_input_buffer;
    src->pub.skip_input_data = skip_input_data;
    src->pub.resync_to_restart = jpeg_resync_to_restart;
    src->pub.term_source = term_source;
    src->data = buffer;
    src->size = size;
    src->pub.next_input_byte = buffer;
    src->pub.bytes_in_buffer = size;
}

EMSCRIPTEN_KEEPALIVE
int decode(uint8_t* input, size_t inputSize, uint8_t* outPtr) {
    if (!input || inputSize == 0) return -10;

    struct jpeg_decompress_struct cinfo;
    struct jpeg_error_mgr jerr;

    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_decompress(&cinfo);

    jpeg_mem_src_custom(&cinfo, input, inputSize);

    int rc = jpeg_read_header(&cinfo, TRUE);
    if (rc != JPEG_HEADER_OK) {
        jpeg_destroy_decompress(&cinfo);
        return -1;
    }

    int is_ycck = 0;
    int is_cmyk = 0;
    int saw_adobe_marker = 0;

    if (cinfo.jpeg_color_space == JCS_YCCK) {
        is_ycck = 1;
        cinfo.out_color_space = JCS_YCCK;
    } else if (cinfo.jpeg_color_space == JCS_CMYK) {
        is_cmyk = 1;
        cinfo.out_color_space = JCS_CMYK;
    } else if (cinfo.jpeg_color_space == JCS_GRAYSCALE) {
        cinfo.out_color_space = JCS_GRAYSCALE;
    } else {
        cinfo.out_color_space = JCS_RGB;
    }

    jpeg_start_decompress(&cinfo);

    uint32_t width = cinfo.output_width;
    uint32_t height = cinfo.output_height;
    int num_components = cinfo.output_components;
    int is_grayscale = (cinfo.out_color_space == JCS_GRAYSCALE);
    saw_adobe_marker = cinfo.saw_Adobe_marker;

    size_t row_stride = width * num_components;
    size_t rgba_size = width * height * 4;
    uint8_t* pixelData = (uint8_t*)malloc(rgba_size);
    
    if (!pixelData) {
        jpeg_finish_decompress(&cinfo);
        jpeg_destroy_decompress(&cinfo);
        return -2;
    }

    JSAMPARRAY buffer = (*cinfo.mem->alloc_sarray)
        ((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, 1);

    int row = 0;
    while (cinfo.output_scanline < cinfo.output_height) {
        jpeg_read_scanlines(&cinfo, buffer, 1);
        
        uint8_t* src = buffer[0];
        uint8_t* dst = pixelData + (row * width * 4);
        
        if (is_ycck) {
            for (uint32_t i = 0; i < width; i++) {
                int y_val = src[i * 4 + 0];
                int cb = src[i * 4 + 1];
                int cr = src[i * 4 + 2];
                int k = src[i * 4 + 3];

                int r = y_val + 1.402f * (cr - 128);
                int g = y_val - 0.3441f * (cb - 128) - 0.7141f * (cr - 128);
                int b = y_val + 1.772f * (cb - 128);

                int c = (r < 0) ? 0 : (r > 255) ? 255 : r;
                int m = (g < 0) ? 0 : (g > 255) ? 255 : g;
                int y = (b < 0) ? 0 : (b > 255) ? 255 : b;
                k = 255 - k;

                src[i * 4 + 0] = (uint8_t)c;
                src[i * 4 + 1] = (uint8_t)m;
                src[i * 4 + 2] = (uint8_t)y;
                src[i * 4 + 3] = (uint8_t)k;
            }
        }
        
        if (is_cmyk || is_ycck) {
            for (uint32_t i = 0; i < width; i++) {
                int c = src[i * 4 + 0];
                int m = src[i * 4 + 1];
                int y = src[i * 4 + 2];
                int k = src[i * 4 + 3];

                int r = ((255 - c) * (255 - k)) / 255;
                int g = ((255 - m) * (255 - k)) / 255;
                int b = ((255 - y) * (255 - k)) / 255;

                dst[i * 4 + 0] = (uint8_t)r;
                dst[i * 4 + 1] = (uint8_t)g;
                dst[i * 4 + 2] = (uint8_t)b;
                dst[i * 4 + 3] = 255;
            }
        } else if (is_grayscale) {
            for (uint32_t i = 0; i < width; i++) {
                uint8_t gray = src[i];
                dst[i * 4 + 0] = gray;
                dst[i * 4 + 1] = gray;
                dst[i * 4 + 2] = gray;
                dst[i * 4 + 3] = 255;
            }
        } else {
            for (uint32_t i = 0; i < width; i++) {
                dst[i * 4 + 0] = src[i * 3 + 0];
                dst[i * 4 + 1] = src[i * 3 + 1];
                dst[i * 4 + 2] = src[i * 3 + 2];
                dst[i * 4 + 3] = 255;
            }
        }
        
        row++;
    }

    jpeg_finish_decompress(&cinfo);
    jpeg_destroy_decompress(&cinfo);

    uint32_t* outView = (uint32_t*)outPtr;
    outView[0] = width;
    outView[1] = height;
    outView[2] = (uint32_t)(uintptr_t)pixelData;
    outView[3] = (uint32_t)rgba_size;

    return 0;
}
