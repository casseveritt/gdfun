shader_type spatial;

varying vec3 pos;

uniform samplerCube texcube;
instance uniform int piece_idx;

void vertex() {
	pos = VERTEX;
}

int get_cube_face(vec3 p) {
    vec3 abs_pos = abs(p);
    // Find max axis: 0=X, 1=Y, 2=Z
    int axis = 0;
    if (abs_pos.y > abs_pos.x && abs_pos.y > abs_pos.z) {
        axis = 1;
    } else if (abs_pos.z > abs_pos.x && abs_pos.z > abs_pos.y) {
        axis = 2;
    }
    // Determine sign and face id
    if (axis == 0) {
        return p.x < 0.0 ? 0 : 1;
    } else if (axis == 1) {
        return p.y < 0.0 ? 2 : 3;
    } else { // axis == 2
        return p.z < 0.0 ? 4 : 5;
    }
}

int idx_face_mask(int idx) {
	int arr[3] = {1, 0, 2};
	return arr[idx];	
}

void fragment() {
	mat3 toObjFromView3 = transpose(mat3(VIEW_MATRIX * MODEL_MATRIX));
	int facebit = 1 << get_cube_face(pos);
	int facemask = idx_face_mask((piece_idx >> 0) & 3) << 0 |
	               idx_face_mask((piece_idx >> 2) & 3) << 2 |
				   idx_face_mask((piece_idx >> 4) & 3) << 4;
	if ((facebit & facemask) > 0) {
		ALBEDO = texture(texcube, pos).rgb;
	} else {
		ALBEDO = vec3(0, 0, 0);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
