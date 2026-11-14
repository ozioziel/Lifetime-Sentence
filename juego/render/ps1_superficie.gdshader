shader_type spatial;
// Material base de la estética PS1 para superficies opacas.
//
// Qué hace:
//  - Texturas sin suavizar (píxel visible) y sin mipmaps.
//  - Vibración de vértices: la geometría "tiembla" al moverse la cámara.
//  - Mapeo triplanar opcional: la textura se proyecta según la posición en el
//    mundo, así todas las piezas tienen el mismo tamaño de píxel sin tocar UV.
//  - Deformación afín opcional de la textura (global, desactivada por defecto).
//
// Cómo usarlo: crear un ShaderMaterial con este shader y ajustar los parámetros
// en el Inspector. Hay ejemplos en assets/materiales/.
render_mode skip_vertex_transform, diffuse_lambert, specular_schlick_ggx;

#include "res://render/ps1_comun.gdshaderinc"

group_uniforms Color;
// Color que multiplica a la textura. Blanco = sin cambio.
uniform vec4 color : source_color = vec4(1.0);
uniform sampler2D textura : source_color, filter_nearest, repeat_enable, hint_default_white;
// Multiplica el color por el color de vértice del modelo (luz pintada u horneada).
uniform bool usar_color_vertice = false;

group_uniforms Mapeado;
// Proyecta la textura desde el mundo en lugar de usar las UV del modelo.
uniform bool triplanar = false;
// Con triplanar: repeticiones de la textura por metro. Sin triplanar: multiplica las UV.
uniform float escala_uv = 1.0;

group_uniforms Superficie;
uniform float rugosidad : hint_range(0.0, 1.0) = 0.9;
uniform float especular : hint_range(0.0, 1.0) = 0.3;
uniform float metalico : hint_range(0.0, 1.0) = 0.0;

group_uniforms Emision;
uniform vec3 emision : source_color = vec3(0.0);
uniform float energia_emision = 1.0;
// La textura brilla por sí misma (pantallas, ventanas iluminadas).
uniform bool emision_desde_textura = false;

group_uniforms Recorte;
// > 0: descarta los píxeles con alfa de la textura menor que este valor
// (estandartes rasgados, sábanas, sangre). 0 = superficie opaca.
uniform float recorte_alfa : hint_range(0.0, 1.0) = 0.0;

group_uniforms Disolucion;
// 0 = sólido. 1 = invisible. Entre medias, se deshace en un patrón de puntos.
// Lo usa la cámara para que el personaje no tape la vista cuando queda muy cerca.
uniform float disolucion : hint_range(0.0, 1.0) = 0.0;

varying vec3 pos_mundo;
varying vec3 normal_mundo;
varying vec3 uv_afin;

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize(MODEL_NORMAL_MATRIX * NORMAL);

	// Con skip_vertex_transform el vértice se entrega en espacio de vista.
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);

	float w = 1.0;
	// En el pase de sombras no se vibra: evita sombras que se despegan.
	if (!IN_SHADOW_PASS) {
		VERTEX = ps1_vibrar(VERTEX, PROJECTION_MATRIX, INV_PROJECTION_MATRIX, w);
	}
	uv_afin = vec3(UV * w, w);
}

void fragment() {
	if (!IN_SHADOW_PASS && disolucion > 0.0 && disolucion > ps1_umbral_trama(FRAGCOORD.xy)) {
		discard;
	}

	vec2 uv;
	if (triplanar) {
		// Se elige la cara dominante (sin mezclar) para conservar el píxel nítido.
		vec3 n = abs(normal_mundo);
		if (n.y >= n.x && n.y >= n.z) {
			uv = pos_mundo.xz;
		} else if (n.x >= n.z) {
			uv = vec2(pos_mundo.z, -pos_mundo.y);
		} else {
			uv = vec2(pos_mundo.x, -pos_mundo.y);
		}
		uv *= escala_uv;
	} else {
		uv = mix(UV, uv_afin.xy / uv_afin.z, ps1_afin) * escala_uv;
	}

	vec4 muestra = texture(textura, uv);
	if (recorte_alfa > 0.0 && muestra.a * color.a < recorte_alfa) {
		discard;
	}
	vec3 base = muestra.rgb * color.rgb;
	if (usar_color_vertice) {
		base *= COLOR.rgb;
	}
	ALBEDO = base;
	ROUGHNESS = rugosidad;
	SPECULAR = especular;
	METALLIC = metalico;
	EMISSION = (emision_desde_textura ? base : emision) * energia_emision;
}
