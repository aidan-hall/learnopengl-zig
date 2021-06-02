#version 400 core
layout (location = 0) in vec3 aPos;

out vec4 vertexColour;

uniform float glfwTime;

void main()
{
	gl_Position.za = vec2(aPos.z, 1.0);
	gl_Position.x = aPos.x * (2.0/3.0) + sin(glfwTime * aPos.y * 2.0)/3.0;
	gl_Position.y = aPos.y * (2.0/3.0) + cos(glfwTime * aPos.x)/3.0;
	/* gl_Position.y += cos(glfwTime)/3.0; */
	vertexColour = vec4(aPos, 1.0);
}
