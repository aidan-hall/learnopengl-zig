#version 330 core
out vec4 FragColor;

in vec2 TexCoord;
in float illumination;

uniform vec3 lightCol;
uniform float faceOpacity;

uniform sampler2D boxTexture;
uniform sampler2D wallTexture;

vec4 lighting(vec4 objectColour, vec3 lightColour, float ambient) {
  return objectColour * vec4(lightColour * ambient, 1.0);
}

void main()
{

  FragColor = lighting( mix(
			    texture(boxTexture, TexCoord),
			    texture(wallTexture, TexCoord),
			    faceOpacity
			    ), lightCol, illumination);
  // FragColor.rgb = FragColor.rgb * lightCol * illumination;
}
