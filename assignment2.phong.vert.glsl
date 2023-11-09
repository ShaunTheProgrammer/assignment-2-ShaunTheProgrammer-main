#version 300 es

// an attribute will receive data from a buffer
in vec3 a_position;
in vec3 a_normal;

// transformation matrices
uniform mat4x4 u_m;
uniform mat4x4 u_v;
uniform mat4x4 u_p;

// output to fragment stage
// TODO: Create any needed `out` variables here
out vec3 v_normal;
out vec3 v_fragPosition;
void main() {
    // Transform positions and normals
    vec4 fragPosition = u_m * vec4(a_position, 1.0);
    mat3 normal = transpose(inverse(mat3(u_m)));
    v_normal = normalize(normal* a_normal) ;
    v_fragPosition = vec3(fragPosition);
    
    gl_Position = u_p * u_v * fragPosition;
}
