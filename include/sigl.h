#pragma once
#include "glad/glad.h"
#include <GLFW/glfw3.h>

GLFWwindow* setup(
		int winWidth, int winHeight,
		const char* title,
		GLFWmonitor* monitor, GLFWwindow* share
		);
void cleanup(GLFWwindow* win);

void framebufferSizeCallback(GLFWwindow* win, int width, int height);
