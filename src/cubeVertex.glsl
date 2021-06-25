#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;

out vec2 TexCoord;

uniform float glfwTime;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

/* float wobbleAbout(float centre, float magnitude, float factor) { */
/* 	return centre + magnitude * factor; */
/* } */
void main()
{
	const float wobbleCentre = 0.9;
	const float wobbleMag = 0.1;

	/* vec4 wobblyPos = vec4( */
	/* 		aPos.x * wobbleAbout(wobbleCentre, wobbleMag, sin(glfwTime)), */
	/* 		aPos.y * wobbleAbout(wobbleCentre, wobbleMag, cos(glfwTime)), */
	/* 		aPos.z, */
	/* 		1.0); */
	gl_Position = projection * view * model * vec4(aPos, 1.0);
	TexCoord = vec2(aTexCoord.x, aTexCoord.y);
}
