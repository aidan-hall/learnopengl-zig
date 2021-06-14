#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColour;
layout (location = 2) in vec2 aTexCoord;

out vec3 vertexColour;
out vec2 TexCoord;

uniform float glfwTime;

void main()
{
	gl_Position = vec4(aPos, 1.0);
	const float wobbleFactor = 1.0/20.0;
	gl_Position.z = aPos.z;
	gl_Position.a = 1.0;
	gl_Position.x = aPos.x * (1.0 - wobbleFactor) + sin(glfwTime * aPos.y * 2.0) * wobbleFactor;
	gl_Position.y = aPos.y * (1.0 - wobbleFactor) + cos(glfwTime * aPos.y) * wobbleFactor/2
		+ sin(glfwTime * aPos.y) * wobbleFactor/2;

	vertexColour = (aPos + aColour) / 2.0;
	vertexColour = (aColour - aPos) * cos(glfwTime/2.0);

	/* gl_Position = vec4(aPos, 1.0); */
	vertexColour = aColour;
	TexCoord = vec2(aTexCoord.x, aTexCoord.y);
}
