shader_type spatial;
// Cel-shading para folhas e tronco: luz em bandas discretas, sombra tingida de
// lilás (nunca preta) e brilho especular "cartoon" opcional para folhas cerosas.
// O contorno é um segundo passe (next_pass) com toon_outline.gdshader.

group_uniforms Cor;
uniform vec3 albedo : source_color = vec3(0.16, 0.74, 0.36);
// Luz que sobra no lado sombreado: cor lilás x brilho. Nunca chega a preto.
uniform vec3 shadow_tint : source_color = vec3(0.5, 0.48, 1.0);
uniform float shadow_brightness : hint_range(0.0, 1.0) = 0.5;
// Lilás somado por cima da sombra (independe do albedo). Sem isso, superfícies
// com pouco azul (tronco marrom) escurecem para vinho em vez de lilás.
uniform float shadow_overlay : hint_range(0.0, 0.5) = 0.12;

group_uniforms Bandas;
// 2 = luz/sombra; 3 = luz/meio-tom/sombra.
uniform int bands : hint_range(2, 4) = 3;
// Largura da transição entre bandas (0 = corte seco).
uniform float band_softness : hint_range(0.0, 0.5) = 0.06;
// Empurra o corte luz/sombra para o lado sombreado. Necessário em superfícies
// verticais (tronco), onde o sol alto nunca passa de N·L ≈ 0.5.
uniform float light_wrap : hint_range(0.0, 1.0) = 0.2;

group_uniforms Especular;
uniform float specular_strength : hint_range(0.0, 2.0) = 0.0;
// Tamanho do brilho especular (disco recortado).
uniform float specular_size : hint_range(0.0, 0.5) = 0.08;

void fragment() {
	ALBEDO = albedo;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

float quantize(float value) {
	float steps = float(bands - 1);
	float scaled = clamp(value, 0.0, 1.0) * steps;
	float edge = smoothstep(0.5 - band_softness, 0.5 + band_softness, fract(scaled));
	return clamp((floor(scaled) + edge) / steps, 0.0, 1.0);
}

void light() {
	// ATTENUATION inclui sombras projetadas: elas também caem na banda tingida.
	float n_dot_l = (dot(NORMAL, LIGHT) + light_wrap) / (1.0 + light_wrap);
	float lit = quantize(clamp(n_dot_l, 0.0, 1.0) * ATTENUATION);
	vec3 shade = mix(shadow_tint * shadow_brightness, vec3(1.0), lit);
	DIFFUSE_LIGHT += shade * LIGHT_COLOR / PI;
	// SPECULAR_LIGHT não é multiplicado pelo albedo: serve de camada aditiva.
	SPECULAR_LIGHT += shadow_tint * shadow_overlay * (1.0 - lit) * LIGHT_COLOR / PI;

	if (specular_strength > 0.0) {
		float n_dot_h = clamp(dot(NORMAL, normalize(LIGHT + VIEW)), 0.0, 1.0);
		float threshold = 1.0 - specular_size * specular_size;
		float spec = smoothstep(threshold - 0.005, threshold + 0.005, n_dot_h) * lit;
		SPECULAR_LIGHT += spec * specular_strength * LIGHT_COLOR / PI;
	}
}
