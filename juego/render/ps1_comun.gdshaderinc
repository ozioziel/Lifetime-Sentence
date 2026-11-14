// Funciones comunes de la estética PS1. Se incluyen desde los shaders de superficie.
//
// Los tres parámetros globales los controla RenderRig (render/render_rig.gd).
// Se declaran en Proyecto > Configuración del proyecto > Shader Globals.

// 0 = sin vibración. 1 = los vértices saltan a la rejilla de píxeles de la
// resolución interna (auténtico). Valores mayores = rejilla más gruesa.
global uniform float ps1_vibracion;
// Resolución interna del juego (480 x 270).
global uniform vec2 ps1_resolucion;
// 0 = texturas con perspectiva correcta. 1 = texturas "afines" que se deforman
// como en la PS1 original.
global uniform float ps1_afin;

// Umbral de la trama ordenada 4 x 4 para un píxel de pantalla (entre 0 y 1).
// Sirve para "disolver" una superficie con un patrón de puntos, sin transparencia.
float ps1_umbral_trama(vec2 pixel) {
	const mat4 trama = mat4(
		vec4(0.0, 12.0, 3.0, 15.0),
		vec4(8.0, 4.0, 11.0, 7.0),
		vec4(2.0, 14.0, 1.0, 13.0),
		vec4(10.0, 6.0, 9.0, 5.0));
	ivec2 celda = ivec2(mod(pixel, 4.0));
	return (trama[celda.x][celda.y] + 0.5) / 16.0;
}

// Ajusta un vértice (en espacio de vista) a la rejilla de píxeles, como hacía
// la PS1 al no tener precisión subpíxel. Devuelve el vértice corregido y deja
// en `w` la profundidad, que se usa para la deformación afín de texturas.
vec3 ps1_vibrar(vec3 vertice_vista, mat4 proyeccion, mat4 proyeccion_inv, out float w) {
	vec4 clip = proyeccion * vec4(vertice_vista, 1.0);
	w = max(clip.w, 0.0001);
	if (ps1_vibracion <= 0.0 || clip.w <= 0.0) {
		return vertice_vista;
	}
	vec2 rejilla = ps1_resolucion * 0.5 / ps1_vibracion;
	vec2 ndc = floor(clip.xy / clip.w * rejilla + 0.5) / rejilla;
	clip.xy = ndc * clip.w;
	vec4 v = proyeccion_inv * clip;
	return v.xyz / v.w;
}
