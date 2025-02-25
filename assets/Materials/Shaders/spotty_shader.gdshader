shader_type spatial;

// Water properties
uniform vec4 color_base : source_color = vec4(0.1, 0.3, 0.5, 1.0);
uniform vec4 color_add : source_color = vec4(0.2, 0.5, 0.8, 1.0);
uniform float noise_scale = 0.5;

varying vec3 world_position;


float random (vec2 uv) { return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123) ; }


// Helper function for 2D hashing
vec2 hash22(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
             dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

// Improved gradient noise
float gradient_noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    float a = dot(hash22(i), f);
    float b = dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
    float c = dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
    float d = dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));

    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal noise with multiple octaves
float fractal_noise(vec2 uv) {
    float value = 0.0;
    float amplitude = 0.5;

    for(int i = 0; i < 3; i++) {
        value += gradient_noise(uv) * amplitude;
        uv *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}

// Domain warping for organic patterns
float organic_noise(vec2 uv) {
    vec2 q = vec2(
        fractal_noise(uv),
        fractal_noise(uv + vec2(5.2, 1.3))
    );

    vec2 r = vec2(
        fractal_noise(uv + 4.0 * q + vec2(1.7, 9.2)),
        fractal_noise(uv + 4.0 * q + vec2(8.3, 2.8))
    );

    return fractal_noise(uv + 4.0 * r);
}


void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Create flowing organic pattern
    vec2 uv = world_position.xz * noise_scale;
    float pattern = organic_noise(uv + vec2(1.0 * noise_scale));

    // Create directional flow
    vec2 flow_dir = vec2(0.8, 0.6);
    float flow = organic_noise(uv * 0.5 + flow_dir * 0.3);

    // Combine patterns
    float water_mask = smoothstep(-0.5, 0.5, pattern * 0.8 + flow * 0.4);

    // Color blending
    vec3 base_color = mix(color_base.rgb, color_add.rgb, water_mask);

    // Final output
	ALBEDO = base_color;
    METALLIC = 0.0;
    ROUGHNESS = 0.8;
    ALPHA = 1.0;
}