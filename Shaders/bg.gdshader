shader_type canvas_item;


uniform float speed;

uniform float t;

void fragment () {
	COLOR = texture(TEXTURE, vec2(UV.x + t * speed, UV.y));
}
