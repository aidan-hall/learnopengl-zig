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

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
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
	glfwSetKeyCallback(win, keyCallback);
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

void keyCallback(GLFWwindow* window, int key, int scancode, int action, int mods) {
	if (action == GLFW_RELEASE) {
		switch (key) {
			case GLFW_KEY_ESCAPE:
				glfwSetWindowShouldClose(window, GLFW_TRUE);
				break;
			case GLFW_KEY_W: {
					int polyMode;
					glGetIntegerv(GL_POLYGON_MODE, &polyMode);
					if (polyMode == GL_LINE)
						glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
					else
						glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
				}
				break;
			default:
				break;
		}
	}
}
