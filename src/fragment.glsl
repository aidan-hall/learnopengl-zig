#version 330 core
out vec4 FragColor;

in vec3 vertexColour;
in vec2 TexCoord;

uniform float glfwTime;
uniform vec3 ourColour;

uniform sampler2D boxTexture;
uniform sampler2D wallTexture;

void main()
{

	FragColor = mix(
			texture(boxTexture, TexCoord),
			texture(wallTexture, TexCoord),
			0.5f
			);
}
