#version 330 core
out vec4 FragColor;

in vec3 vertexColour;
in vec2 TexCoord;

uniform float glfwTime;
uniform vec3 ourColour;
uniform float faceOpacity;

uniform sampler2D boxTexture;
uniform sampler2D wallTexture;

void main()
{
	/* FragColor = vec4((ourColour+vertexColour)*sin(glfwTime)/4.0f, 1.0) + vec4(0.5f, 0.3f, 0.2f, 1.0f); */
	/* FragColor.b += (sin(glfwTime * 200 * vertexColour.y * vertexColour.x)/2.0f) + 0.5f; */
	/* FragColor.r += (sin(glfwTime * vertexColour.x)/2.0f) + 0.5f; */
	/* float minColour = min(FragColor.r, min(FragColor.g, FragColor.b)); */
	/* FragColor -= vec4(minColour, minColour, minColour, 2.0)/2.0; */

	FragColor = mix(
			texture(boxTexture, vec2(TexCoord.x + sin(TexCoord.y * 5.0f + glfwTime)/40.0f, TexCoord.y)),
			texture(wallTexture, vec2(TexCoord.x, 1.0 - TexCoord.y + sin(TexCoord.x * 20.0f + glfwTime)/30.0f)),
			faceOpacity
			);
	/* FragColor = mix( */
	/* 		texture(boxTexture, TexCoord), */
	/* 		texture(wallTexture, TexCoord), */
	/* 		0.5f */
	/* 		); */
	FragColor.r *= (cos(glfwTime + 6.123/3) * 0.5f) + 1.0f;
	FragColor.g *= (cos(glfwTime) * 0.5f) + 1.0f;
	FragColor.b *= (cos(glfwTime - 6.123/3) * 0.5f) + 1.0f;
}
