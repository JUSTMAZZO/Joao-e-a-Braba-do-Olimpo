shader_type spatial;
// Cel-shading para personagens (João): preserva a textura de cor do .glb e
// troca a iluminação PBR por bandas discretas, com sombra tingida de
// azul/lilás (nunca preta) e um rim light fino para destacar a silhueta.
// O contorno é um segundo passe (next_pass) com toon_outline.gdshader.

render_mode cull_disabled;

group_uniforms Cor;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_tint : source_color = vec4(1.0);
// Luz que sobra no lado sombreado: cor azul-arroxeada x brilho.
uniform vec3 shadow_tint : source_color = vec3(0.45, 0.42, 0.95);
uniform float shadow_brightness : hint_range(0.0, 1.0) = 0.55;
// Lilás somado por cima da sombra, independente do albedo (pele e roupa
// quentes escurecem para marrom sem isso).
uniform float shadow_overlay : hint_range(0.0, 0.5) = 0.08;

group_uniforms Bandas;
// 2 = luz/sombra; 3 = luz/meio-tom/sombra.
uniform int bands : hint_range(2, 3) = 3;
// Largura da transição entre bandas (0 = corte seco).
uniform float band_softness : hint_range(0.0, 0.5) = 0.04;
uniform float light_wrap : hint_range(0.0, 1.0) = 0.15;

group_uniforms Normal;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
// Detalhe do normal map. Valores altos picotam as bandas; o toon pede pouco.
uniform float normal_strength : hint_range(0.0, 1.0) = 0.35;

group_uniforms Borda;
uniform vec3 rim_color : source_color = vec3(1.0, 0.88, 0.6);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.25;
uniform float rim_width : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec4 tex = texture(albedo_texture, UV) * albedo_tint;
	ALBEDO = tex.rgb;
	NORMAL_MAP = texture(normal_texture, UV).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	METALLIC = 0.0;
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
	// SPECULAR_LIGHT não é multiplicado pelo albedo: camada aditiva lilás.
	SPECULAR_LIGHT += shadow_tint * shadow_overlay * (1.0 - lit) * LIGHT_COLOR / PI;

	// Rim light recortado, só do lado iluminado (luz dourada vinda de cima).
	float fresnel = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = step(1.0 - rim_width, fresnel) * lit;
	SPECULAR_LIGHT += rim * rim_strength * rim_color * LIGHT_COLOR / PI;
}
