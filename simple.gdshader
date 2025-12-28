shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, blend_mix, cull_back;

uniform vec3 color : source_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D albedo : source_color;

uniform float shine : hint_range(0.0, 1.0) = 0.5;

// add normal map later

void vertex() {
	
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb * color;
	METALLIC = 0.2;
	SPECULAR = shine;
	ROUGHNESS = 1.0 - shine;
}