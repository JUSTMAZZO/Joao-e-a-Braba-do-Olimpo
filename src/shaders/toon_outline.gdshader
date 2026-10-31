shader_type spatial;
// Contorno por "inverted hull": a malha é inflada e só as faces de trás são
// desenhadas. Usado como next_pass dos materiais toon.

render_mode unshaded, cull_front, shadows_disabled;

uniform vec3 outline_color : source_color = vec3(0.07, 0.09, 0.06);
// Espessura em metros (espaço do objeto).
uniform float outline_width : hint_range(0.0, 0.2) = 0.035;
// Malhas com quinas duras (BoxMesh) abrem buracos ao inflar pela normal.
// Ativado, infla pelo sinal da posição, o que fecha as quinas de caixas
// centradas. Para malhas suaves (cilindro, .glb do João), deixe desligado.
uniform bool extrude_by_position = false;

void vertex() {
	vec3 dir = extrude_by_position ? sign(VERTEX) : NORMAL;
	VERTEX += dir * outline_width;
}

void fragment() {
	ALBEDO = outline_color;
}
