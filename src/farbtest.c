#include "farbfeld.h"

int main(int argc, char* argv[]) {
	farb_Image *image = farb_load("container.ff");
	if (image == NULL)
		return 1;

	printf("Image loaded with width=%d, height=%d\n", image->width, image->height);


	farb_destroy(image);
}
