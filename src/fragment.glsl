#version 330 core
out vec4 FragColor;

in highp vec3 coord;
uniform float size;
uniform vec2 position;

uniform int max_count;
uniform float shade_scale;

float asdf(float perc) {
	return 1-tanh(perc * shade_scale);
}

void main()
{
	int count = 0;
	highp vec2 c = position + coord.xy * size;
	vec2 z = vec2(0, 0);
	vec2 z_squ = vec2(0, 0);

	while (count < max_count && z_squ.x + z_squ.y <= 4) {
		count += 1;
		z_squ = vec2(z.x * z.x, z.y * z.y);
		float xtemp = z_squ.x - z_squ.y;
		z.y = 2 * z.x * z.y + c.y;
		z.x = xtemp + c.x;
	}

	float perc = float(count) / max_count;
	float shade = asdf(perc);
	FragColor = vec4(
			shade,
			shade,
			shade,
			0.0f
			);
}
