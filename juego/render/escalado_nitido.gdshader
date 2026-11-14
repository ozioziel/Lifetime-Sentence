shader_type canvas_item;
// Amplía la imagen interna (480 x 270) a cualquier tamaño de ventana
// conservando los píxeles nítidos, sin el temblor que produce el escalado
// "vecino más cercano" cuando la ampliación no es un número entero.
//
// Requiere que el TextureRect use filtro de textura Lineal.

void fragment() {
	vec2 tam = vec2(textureSize(TEXTURE, 0));
	vec2 texel = UV * tam;
	// Píxeles de pantalla que ocupa cada píxel interno.
	vec2 escala = max(1.0 / fwidth(texel), vec2(1.0));
	vec2 base = floor(texel);
	vec2 centro = fract(texel) - 0.5;
	vec2 rango = 0.5 - 0.5 / escala;
	vec2 f = (centro - clamp(centro, -rango, rango)) * escala + 0.5;
	COLOR = texture(TEXTURE, (base + f) / tam);
}
