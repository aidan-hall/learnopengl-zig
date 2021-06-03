#version 400 core
out vec4 FragColor;

in vec3 vertexColour;

uniform float glfwTime;

void main()
{
	FragColor = vec4(vertexColour*sin(glfwTime)/2.0f, 1.0) + vec4(0.5f, 0.3f, 0.2f, 1.0f);
	/* FragColor = vec4(vertexColour, 1.0); */
	FragColor.g += (cos(glfwTime)/2.0f) + 0.5f;
	FragColor.b += (sin(glfwTime * 20 * vertexColour.y * vertexColour.x)/2.0f) + 0.5f;
	FragColor.r += (sin(glfwTime * vertexColour.x)/2.0f) + 0.5f;
	float minColour = min(FragColor.r, min(FragColor.g, FragColor.b));
	FragColor -= vec4(minColour, minColour, minColour, 2.0)/2.0;

}
