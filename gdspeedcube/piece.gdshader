shader_type spatial;

varying vec3 pos;

uniform samplerCube texcube;

void vertex() {
	pos = VERTEX;
}

void fragment() {
	mat3 toObjFromView3 = transpose(mat3(VIEW_MATRIX * MODEL_MATRIX));
	vec3 n = toObjFromView3 * NORMAL;
	vec3 an = abs(n);
	float man = max(an.x, max(an.y, an.z));
    if (an.x > an.y && an.x > an.z) {
		if (n.x > 0.0) {
			ALBEDO = vec3(1.0);
		} else {
			ALBEDO = vec3(1.0, 1.0, 0.0);
		}
	} else if (an.y > an.z) {
		if (n.y > 0.0) {
			ALBEDO = vec3(1.0, 0.0, 0.0);
		} else {
			ALBEDO = vec3(1.0, 0.25, 0.0);
		}
	} else {
		if (n.z > 0.0) {
			ALBEDO = vec3(0.0, 0.15, 0.0);
		} else {
			ALBEDO = vec3(0.0, 0.0, 1.0);
		}
	}
	ALBEDO = texture(texcube, pos).rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
