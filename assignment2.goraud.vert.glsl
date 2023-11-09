#version 300 es

#define MAX_LIGHTS 16

// struct definitions
struct AmbientLight {
    vec3 color;
    float intensity;
};

struct DirectionalLight {
    vec3 direction;
    vec3 color;
    float intensity;
};

struct PointLight {
    vec3 position;
    vec3 color;
    float intensity;
};

struct Material {
    vec3 kA;
    vec3 kD;
    vec3 kS;
    float shininess;
};


// an attribute will receive data from a buffer
in vec3 a_position;
in vec3 a_normal;

// camera position
uniform vec3 u_eye;

// transformation matrices
uniform mat4x4 u_m;
uniform mat4x4 u_v;
uniform mat4x4 u_p;

// lights and materials
uniform AmbientLight u_lights_ambient[MAX_LIGHTS];
uniform DirectionalLight u_lights_directional[MAX_LIGHTS];
uniform PointLight u_lights_point[MAX_LIGHTS];

uniform Material u_material;

// shading output
out vec4 o_color;

// Shades an ambient light and returns this light's contribution
vec3 shadeAmbientLight(Material material, AmbientLight light) {
    
    return material.kA * light.color * light.intensity;

    //return vec3(0);
}

// Shades a directional light and returns its contribution
vec3 shadeDirectionalLight(Material material, DirectionalLight light, vec3 normal, vec3 eye, vec3 vertex_position) {
    vec3 lightDirection = normalize(-light.direction);
    vec3 reflectDirection = reflect(-lightDirection, normal);
    float diff = max(dot(normal, lightDirection), 0.0);
    float spec = pow(max(dot(reflectDirection, eye), 0.0), material.shininess);
    return (material.kD * light.color * light.intensity * diff) + (material.kS * light.color * light.intensity * spec);

}

// Shades a point light and returns its contribution
vec3 shadePointLight(Material material, PointLight light, vec3 normal, vec3 eye, vec3 vertex_position) {
    vec3 lightDirection = normalize(light.position - vertex_position);
    vec3 reflectDirection = reflect(-lightDirection, normal);
    float diff = max(dot(normal, lightDirection), 0.0);
    float spec = pow(max(dot(reflectDirection, normalize(eye - vertex_position)), 0.0), material.shininess);
    float distance = length(light.position - vertex_position);
    float attenuation = 1.0 / (1.0 + 0.05 * distance + 0.0001 * distance * distance);
    return (material.kD * light.color * light.intensity * diff * attenuation) + (material.kS * light.color * light.intensity * spec * attenuation);

}

void main() {
    // Transform positions and normals
    vec4 transformedPosition = u_m * vec4(a_position, 1.0);
    vec3 transformedNormal = normalize(mat3(transpose(inverse(u_m))) * a_normal);
    //vec3 n = normalize(mat3(u_v* u_m) * a_normal);
    vec3 eyeD = normalize(u_eye - transformedPosition.xyz);
    
    vec3 totalLightContribution = vec3(0);

    // Shade all ambient lights
    for (int i = 0; i < MAX_LIGHTS; i++) {
        totalLightContribution += shadeAmbientLight(u_material, u_lights_ambient[i]);
    }

    // Shade all directional lights
    for (int i = 0; i < MAX_LIGHTS; i++) {
        totalLightContribution += shadeDirectionalLight(u_material, u_lights_directional[i], transformedNormal, eyeD, transformedPosition.xyz);
    }

    // Shade all point lights
    for (int i = 0; i < MAX_LIGHTS; i++) {
        totalLightContribution += shadePointLight(u_material, u_lights_point[i], transformedNormal, eyeD, transformedPosition.xyz);
    }

    // Pass the shaded vertex color to the fragment stage
    o_color = vec4(totalLightContribution, 1.0);
    gl_Position = u_p * u_v * transformedPosition;
}