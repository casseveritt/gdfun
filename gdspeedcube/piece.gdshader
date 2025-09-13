shader_type spatial;

varying vec3 pos;

uniform samplerCube texcube;
uniform float piece_scale;
instance uniform vec3 piece_bias;
instance uniform int piece_idx;


void vertex() {
	pos = VERTEX;
}


void fragment() {
	vec3 pos2 = pos * piece_scale + piece_bias;

	vec3 apos2 = abs(pos2);
	float maxapos2 = max(apos2.x, max(apos2.y, apos2.z));
	float sc = maxapos2 < 0.49 ? 0.0 : 1.0;
	ALBEDO = texture(texcube, pos).rgb * sc;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
