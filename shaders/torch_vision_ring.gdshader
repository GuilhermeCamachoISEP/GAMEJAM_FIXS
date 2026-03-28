shader_type canvas_item;
render_mode unshaded;

uniform vec2 center_px = vec2(640.0, 360.0);
uniform vec2 viewport_px = vec2(1280.0, 720.0);
uniform float inner_radius_px = 200.0;
uniform float edge_softness_px = 48.0;
uniform vec4 darken : source_color = vec4(0.02, 0.015, 0.06, 0.9);

void fragment() {
	vec2 px = UV * viewport_px;
	float d = distance(px, center_px);
	float t = smoothstep(inner_radius_px - edge_softness_px, inner_radius_px + edge_softness_px, d);
	COLOR = vec4(darken.rgb, darken.a * t);
}
