#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColour;
layout (location = 2) in vec2 aTexCoord;

out vec3 vertexColour;
out float illumination;
out vec2 TexCoord;

uniform float glfwTime;

uniform vec3 lightPos;

uniform mat4 transMat;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
  vec4 modelCoords = model * vec4(aPos, 1.0);
  gl_Position = projection * view * modelCoords;
  TexCoord = vec2(aTexCoord.x, aTexCoord.y);
  vertexColour = aColour;

  float lightSep = distance(modelCoords.xyz, lightPos);
  illumination = clamp(5.0 / (lightSep * lightSep), 0.0, 1.0);

  /* const float wobbleFactor = 1.0/20.0; */
  /* gl_Position.x *= (1.0 - wobbleFactor) + sin(glfwTime * aPos.y * 2.0) * wobbleFactor; */
  /* gl_Position.y *= (1.0 - wobbleFactor) + cos(glfwTime * aPos.y) * wobbleFactor/2 */
  /* 	+ sin(glfwTime * aPos.y) * wobbleFactor/2; */

  /* vertexColour = (aPos + aColour) / 2.0; */
  /* vertexColour = (aColour - aPos) * cos(glfwTime/2.0); */

}
