#version 400 core
out vec4 FragColor;

in vec4 vertexColour;

uniform float glfwTime;

void main()
{
	FragColor = vertexColour*(sin(glfwTime)/2.0f) + vec4(0.5f, 0.3f, 0.2f, 1.0f);
	FragColor.g += (cos(glfwTime)/2.0f) + 0.5f;
	FragColor.b += (sin(glfwTime * vertexColour.y * vertexColour.x)/2.0f) + 0.5f;
	FragColor.r += (sin(glfwTime * vertexColour.x)/2.0f) + 0.5f;
	float maxColour = max(FragColor.r, max(FragColor.g, FragColor.b));
	FragColor /= maxColour;

}
