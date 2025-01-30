shader_type canvas_item;

uniform sampler2D tex;

void vertex() 
{
	// Called for every vertex the material is visible on.
}

void fragment() 
{
	vec4 col = vec4(texture(tex,UV).rrr, 1.0f);
	COLOR = col;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
