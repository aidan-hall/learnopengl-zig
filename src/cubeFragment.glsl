#version 330 core
out vec4 FragColor;

in vec2 TexCoord;
in float illumination;

uniform float faceOpacity;

uniform sampler2D boxTexture;
uniform sampler2D wallTexture;

void main()
{

	FragColor = mix(
			texture(boxTexture, TexCoord),
			texture(wallTexture, TexCoord),
			faceOpacity
			);
	FragColor.rgb *= illumination;
}
