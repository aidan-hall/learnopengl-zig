#version 330 core
out vec4 FragColor;

in vec3 vertexColour;

uniform float glfwTime;
uniform vec3 ourColour;

void main()
{
	FragColor = vec4((ourColour+vertexColour)*sin(glfwTime)/4.0f, 1.0) + vec4(0.5f, 0.3f, 0.2f, 1.0f);
	FragColor.g += (cos(glfwTime)/2.0f) + 0.5f;
	FragColor.b += (sin(glfwTime * 200 * vertexColour.y * vertexColour.x)/2.0f) + 0.5f;
	FragColor.r += (sin(glfwTime * vertexColour.x)/2.0f) + 0.5f;
	float minColour = min(FragColor.r, min(FragColor.g, FragColor.b));
	FragColor -= vec4(minColour, minColour, minColour, 2.0)/2.0;

}
