#version 300 es

#define MAX_LIGHTS 16

// Fragment shaders don't have a default precision so we need
// to pick one. mediump is a good default. It means "medium precision".
precision mediump float;

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

// lights and materials
uniform AmbientLight u_lights_ambient[MAX_LIGHTS];
uniform DirectionalLight u_lights_directional[MAX_LIGHTS];
uniform PointLight u_lights_point[MAX_LIGHTS];

uniform Material u_material;

// camera position
uniform vec3 u_eye;

// received from vertex stage
// TODO: Create any needed `in` variables here
in vec3 v_normal; 
in vec3 v_fragPosition;
// TODO: These variables correspond to the `out` variables from the vertex stage

// with webgl 2, we now have to define an out that will be the color of the fragment
out vec4 o_fragColor;

// Shades an ambient light and returns this light's contribution
vec3 shadeAmbientLight(Material material, AmbientLight light) {

    return material.kA * light.color * light.intensity;

    //return vec3(0);
}

// Shades a directional light and returns its contribution
vec3 shadeDirectionalLight(Material material, DirectionalLight light, vec3 normal, vec3 eye, vec3 vertex_position) {

    vec3 lightDirection = normalize(-light.direction);
    float diff = max(dot(normal, lightDirection), 0.0);
    vec3 reflectionDirection = reflect(-lightDirection, normal);
    float spec = pow(max(dot(reflectionDirection, normalize(eye - vertex_position)), 0.0), material.shininess);
    vec3 ambient = material.kA * light.color * light.intensity;
    vec3 diffuse = material.kD * light.color * light.intensity * diff;
    vec3 specular = material.kS * light.color * light.intensity * spec;
    return diffuse + specular;

    //return vec3(0);
}

// Shades a point light and returns its contribution
vec3 shadePointLight(Material material, PointLight light, vec3 normal, vec3 eye, vec3 vertex_position) {
    vec3 lightDirection = normalize(light.position - vertex_position);
    float diff = max(dot(normal, lightDirection), 0.0);
    float distance = length(light.position - vertex_position);
    float attenuation = 1.0 / (1.0 + 0.05 * distance + 0.0001 * distance * distance);

    
    // Specular reflection
    vec3 viewDirection = normalize(eye - vertex_position);
    vec3 reflectDirection = reflect(-lightDirection, normal);
    float spec = pow(max(dot(reflectDirection,eye), 0.0), material.shininess);
    
    vec3 ambient = material.kA * light.color * light.intensity;
    vec3 diffuse = material.kD * light.color * light.intensity * diff * attenuation;
    vec3 specular = material.kS * light.color * light.intensity * spec * attenuation;

    return diffuse + specular;

    //return vec3(0);
}

void main() {

    // Normal and fragment position are interpolated by the rasterizer
    vec3 normal = normalize(v_normal);
    vec3 fragPosition = v_fragPosition;
    vec3 eyeD = normalize(u_eye - fragPosition.xyz);
    // Initialize final color as black
    vec3 totalLight = vec3(0);

    // Loop through ambient lights
    for (int i = 0; i < MAX_LIGHTS; i++) {
        if (u_lights_ambient[i].intensity > 0.0) {
            totalLight += shadeAmbientLight(u_material, u_lights_ambient[i]);
        }
    }

    // Loop through directional lights
    for (int i = 0; i < MAX_LIGHTS; i++) {
        if (u_lights_directional[i].intensity > 0.0) {
            totalLight += shadeDirectionalLight(u_material, u_lights_directional[i], normal, eyeD, fragPosition);
        }
    }

    // Loop through point lights
    for (int i = 0; i < MAX_LIGHTS; i++) {
        if (u_lights_point[i].intensity > 0.0) {
            totalLight += shadePointLight(u_material, u_lights_point[i], normal, eyeD, fragPosition);
        }
    }

    o_fragColor = vec4(totalLight, 1.0);
}
