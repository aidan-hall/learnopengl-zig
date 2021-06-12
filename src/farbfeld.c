#include "farbfeld.h"

#include <stdlib.h>

uint32_t netbyte_to_hostbyte(uint32_t netlong) {
	uint32_t hostlong;
	char *netbytes = (char*)(&netlong);

	hostlong = (netbytes[0]>>8*3)|(netbytes[1]>>8*1)|(netbytes[2]<<8*1)|(netbytes[3]<<8*3);

	return hostlong;
}

farb_Image *farb_read(FILE *imageFile) {
	farb_Image *image = malloc(sizeof(farb_Image));
	if (image == NULL)
		return NULL;

	// 'farbfeld' header
	if (fseek(imageFile, sizeof("farbfeld")-sizeof(""), SEEK_SET) != 0) {
		free(image);
		return NULL;
	}


	{
		uint32_t widthBuffer, heightBuffer;
		if (fread(&widthBuffer, sizeof(uint32_t), 1, imageFile) != 1) {
			free(image);
			return NULL;
		}
		image->width = netbyte_to_hostbyte(widthBuffer);

		if (fread(&heightBuffer, sizeof(uint32_t), 1, imageFile) != 1) {
			free(image);
			return NULL;
		}
		image->height = netbyte_to_hostbyte(heightBuffer);
	}

	image->data = malloc(image->width * image->height * 4 * sizeof(uint16_t));

	if (fread(image->data, 4*sizeof(uint16_t), image->width*image->height, imageFile)
			!= image->width*image->height) {
		farb_destroy(image);
		return NULL;
	}

	return image;
}

void farb_destroy(farb_Image *image) {

	free(image->data);
	free(image);
}

farb_Image *farb_load(const char *filename) {
	FILE *imageFile = fopen(filename, "r");
	if (imageFile == NULL)
		return NULL;
	farb_Image *image = farb_read(imageFile);
	fclose(imageFile);
	return image;
}
