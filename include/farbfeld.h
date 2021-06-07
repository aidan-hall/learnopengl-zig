#pragma once

#include <stdio.h>
#include <stdint.h>

typedef struct {
	int32_t width;
	int32_t height;
	uint16_t (*data)[4];
} farb_Image;

farb_Image *farb_read(FILE *imageFile);
void farb_destroy(farb_Image *image);
farb_Image *farb_load(const char *filename);
