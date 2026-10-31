shader_type spatial;
// Esporos mágicos: cor vem das partículas (COLOR) e é emitida acima de 1.0
// para acionar o Glow do WorldEnvironment.

render_mode unshaded, shadows_disabled, blend_add, depth_draw_never;

uniform float emission_energy : hint_range(0.0, 8.0) = 1.2;

void fragment() {
	ALBEDO = COLOR.rgb * emission_energy;
	ALPHA = COLOR.a;
}
