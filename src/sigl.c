#include "sigl.h"

GLFWwindow* setup(
		int winWidth, int winHeight,
		const char* title,
		GLFWmonitor* monitor, GLFWwindow* share
		) {
	// GLFW
	if (glfwInit() == GLFW_FALSE) {
		return NULL;
	}

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	// Window
	GLFWwindow *win = glfwCreateWindow(winWidth, winHeight, title, monitor, share);
	if (win == NULL) {
		glfwTerminate();
		return NULL;
	} else {
		glfwMakeContextCurrent(win);
	}

	// GLAD
	if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
		return NULL;
	}

	// Framebuffer
	glfwSetFramebufferSizeCallback(win, framebufferSizeCallback);
	return win;
}

void cleanup(GLFWwindow* win) {
	if (win != NULL)
		glfwDestroyWindow(win);

	glfwTerminate();
}

void framebufferSizeCallback(GLFWwindow* win, int width, int height) {
	glViewport(0, 0, width, height);
}
