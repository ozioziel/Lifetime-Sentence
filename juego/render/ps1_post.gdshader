shader_type canvas_item;
// Posproceso PS1. Se aplica sobre la imagen interna de 480 x 270, antes de
// ampliarla a la pantalla. Lo controla RenderRig; los valores de cada época
// están en los recursos PerfilEpoca (render/epoca_presente.tres, etc.).

uniform sampler2D pantalla : hint_screen_texture, filter_nearest, repeat_disable;

group_uniforms Color;
// Tintes de sombras y luces. Gris medio (0.5) = sin cambio.
uniform vec3 tinte_sombras : source_color = vec3(0.5);
uniform vec3 tinte_luces : source_color = vec3(0.5);
uniform float saturacion : hint_range(0.0, 2.0) = 1.0;
uniform float contraste : hint_range(0.5, 2.0) = 1.0;
uniform float brillo : hint_range(-0.2, 0.2) = 0.0;

group_uniforms PS1;
// Niveles por canal. 31 = color de 15 bits, como la PS1. 255 = sin reducción.
uniform float niveles_color : hint_range(2.0, 255.0) = 31.0;
// Trama ordenada que disimula los saltos de color.
uniform float fuerza_dither : hint_range(0.0, 2.0) = 1.0;
uniform float grano : hint_range(0.0, 0.3) = 0.05;
uniform float vineta : hint_range(0.0, 1.0) = 0.4;

group_uniforms Cine;
// 0 = sin bandas. 1 = bandas negras de formato 2.39:1 (cinemáticas).
uniform float barras : hint_range(0.0, 1.0) = 0.0;
// 0 = imagen normal. 1 = negro.
uniform float fundido : hint_range(0.0, 1.0) = 0.0;

const mat4 BAYER = mat4(
	vec4(0.0, 12.0, 3.0, 15.0),
	vec4(8.0, 4.0, 11.0, 7.0),
	vec4(2.0, 14.0, 1.0, 13.0),
	vec4(10.0, 6.0, 9.0, 5.0));

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 c = texture(pantalla, uv).rgb;

	// --- Gradación de color de la época ---
	float luz = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(luz), c, saturacion);
	c = (c - 0.5) * contraste + 0.5 + brillo;
	c = max(c, vec3(0.0));
	c *= 2.0 * mix(tinte_sombras, tinte_luces, smoothstep(0.0, 0.65, luz));

	// --- Viñeta ---
	float distancia = distance(uv, vec2(0.5));
	c *= mix(1.0, smoothstep(0.9, 0.3, distancia), vineta);

	// --- Grano (cambia 15 veces por segundo, por píxel interno) ---
	vec2 pixel = floor(FRAGCOORD.xy);
	float ruido = azar(pixel + floor(TIME * 15.0) * vec2(17.0, 31.0)) - 0.5;
	c += ruido * grano;

	// --- Reducción de color con trama ordenada 4 x 4 ---
	ivec2 celda = ivec2(mod(pixel, 4.0));
	float umbral = (BAYER[celda.x][celda.y] + 0.5) / 16.0 - 0.5;
	c = floor(c * niveles_color + umbral * fuerza_dither + 0.5) / niveles_color;
	c = clamp(c, 0.0, 1.0);

	// --- Bandas de cine y fundido a negro ---
	float margen = 0.1281 * barras;
	if (uv.y < margen || uv.y > 1.0 - margen) {
		c = vec3(0.0);
	}
	c *= 1.0 - fundido;

	COLOR = vec4(c, 1.0);
}
