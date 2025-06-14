shader_type canvas_item;

uniform float dissolve_threshold : hint_range(0.0, 1.0) = 0.0;
uniform float pixel_size : hint_range(0.001, 0.1) = 0.02;
uniform sampler2D noise_texture;
uniform vec4 dissolve_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

void fragment() {
	// Pixelate UV coordinates
	vec2 pixelated_uv = floor(UV / pixel_size) * pixel_size;
	
	// Sample noise texture
	float noise_value = texture(noise_texture, pixelated_uv).r;
	
	// Compare noise value to dissolve threshold
	if (noise_value < dissolve_threshold) {
		COLOR = dissolve_color; // Fully dissolved to black
	} else {
		COLOR = texture(screen_texture, SCREEN_UV); // Fully visible screen texture
		COLOR.a = 1.0;
	}
}