shader_type spatial;

group_uniforms textures;
uniform sampler2D top_texture: source_color;
uniform sampler2D top_normal: hint_normal;
uniform sampler2D top_roughness: hint_roughness_r;
uniform sampler2D center_texture: source_color;
uniform sampler2D center_normal: hint_normal;
uniform sampler2D center_roughness: hint_roughness_r;


group_uniforms slopes;
uniform float center_slope: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform bool use_world_normal = true;
uniform float width = 0.1;

group_uniforms uv;
uniform float uv_top_blend_sharpness = 1.0;
uniform vec3 uv_top_scale = vec3(1.0);
uniform vec3 uv_top_offset = vec3(0.0);
uniform float uv_center_blend_sharpness = 1.0;
uniform vec3 uv_center_scale = vec3(1.0);
uniform vec3 uv_center_offset = vec3(0.0);

varying float world_normal_y;
varying float normal_y;
varying vec3 uv_top_triplanar_pos;
varying vec3 uv_center_triplanar_pos;
varying vec3 uv_top_power_normal;
varying vec3 uv_center_power_normal;

void vertex() {
    vec3 world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
    world_normal_y = world_normal.y;
    normal_y = NORMAL.y;

    vec3 normal = normalize(NORMAL);
    vec3 tangent = vec3(0.0);
    vec3 binormal = vec3(0.0);

    float absX = abs(normal.x);
    float absY = abs(normal.y);
    float absZ = abs(normal.z);
    
    if (absX > absY && absX > absZ) {
        tangent = vec3(0.0, 0.0, -sign(normal.x));
        binormal = vec3(0.0, sign(normal.x), 0.0);
    } else if (absY > absZ) {
        tangent = vec3(sign(normal.y), 0.0, 0.0);
        binormal = vec3(0.0, 0.0, -sign(normal.y));
    } else {
        tangent = vec3(sign(normal.z), 0.0, 0.0);
        binormal = vec3(0.0, sign(normal.z), 0.0);
    }
    
    TANGENT = normalize(tangent);
    BINORMAL = normalize(binormal);

    vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Top calculations
    uv_top_power_normal = pow(abs(normal), vec3(uv_top_blend_sharpness));
    uv_top_triplanar_pos = world_vertex * uv_top_scale + uv_top_offset;
    uv_top_power_normal /= dot(uv_top_power_normal, vec3(1.0));

    // Center calculations
    uv_center_power_normal = pow(abs(normal), vec3(uv_center_blend_sharpness));
    uv_center_triplanar_pos = world_vertex * uv_center_scale + uv_center_offset;
    uv_center_power_normal /= dot(uv_center_power_normal, vec3(1.0));
}

vec2 hash( vec2 p ) {
	return fract( sin( p * mat2( vec2( 127.1, 311.7 ), vec2( 269.5, 183.3 ) ) ) * 43758.5453 );
}

vec4 stochastic_sample(sampler2D tex, vec2 uv) {
	vec2 skewV = mat2(vec2(1.0,1.0),vec2(-0.57735027 , 1.15470054))*uv * 3.464;

	vec2 vxID = floor(skewV);
	vec2 fracV = fract(skewV);
	vec3 barry = vec3(fracV.x,fracV.y,1.0-fracV.x-fracV.y);

	mat4 bw_vx = barry.z>0.0?
		mat4(vec4(vxID,0.0,0.0),vec4((vxID+vec2(0.0,1.0)),0.0,0.0),vec4(vxID+vec2(1.0,0.0),0,0),vec4(barry.zyx,0)):
		mat4(vec4(vxID+vec2(1.0,1.0),0.0,0.0),vec4((vxID+vec2(1.0,0.0)),0.0,0.0),vec4(vxID+vec2(0.0,1.0),0,0),vec4(-barry.z,1.0-barry.y,1.0-barry.x,0));

	vec2 ddx = dFdx(uv);
	vec2 ddy = dFdy(uv);

	return (textureGrad(tex,uv+hash(bw_vx[0].xy),ddx,ddy)*bw_vx[3].x) +
	(textureGrad(tex,uv+hash(bw_vx[1].xy),ddx,ddy)*bw_vx[3].y) +
	(textureGrad(tex,uv+hash(bw_vx[2].xy),ddx,ddy)*bw_vx[3].z);
}

vec4 triplanar_stochastic_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= stochastic_sample(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= stochastic_sample(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= stochastic_sample(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void fragment() {
    // textures
    vec3 top_albedo = triplanar_stochastic_texture(top_texture, uv_top_power_normal, uv_top_triplanar_pos).rgb;
    vec3 center_albedo = triplanar_stochastic_texture(center_texture, uv_center_power_normal, uv_center_triplanar_pos).rgb;

    // normals
    vec3 top_normal_map = triplanar_stochastic_texture(top_normal, uv_top_power_normal, uv_top_triplanar_pos).rgb;
    vec3 center_normal_map = triplanar_stochastic_texture(center_normal, uv_center_power_normal, uv_center_triplanar_pos).rgb;

    // roughness
    float _top_roughness = triplanar_stochastic_texture(top_roughness, uv_top_power_normal, uv_top_triplanar_pos).r;
    float _center_roughness = triplanar_stochastic_texture(center_roughness, uv_center_power_normal, uv_center_triplanar_pos).r;

    // Blend weight
    float center_top_weight = use_world_normal ? world_normal_y : normal_y;
    
    // smooth transition
    center_top_weight = smoothstep(
        center_slope - width,
        center_slope + width,
        center_top_weight
    );

    // Mix layers
    ALBEDO = mix(center_albedo, top_albedo, center_top_weight);
    NORMAL_MAP = mix(center_normal_map, top_normal_map, center_top_weight);
    ROUGHNESS = mix(_center_roughness, _top_roughness, center_top_weight);
}