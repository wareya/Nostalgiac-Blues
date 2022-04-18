// NOTE: Shader automatically converted from Godot Engine 3.4.4.stable's SpatialMaterial.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform float shatterment;
uniform vec3 scale;
uniform float gravity_amount;

// public domain rng (modified
highp float rand(vec3 co)
{
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float z = 748.2313;
    highp float c = 43758.5453;
    highp float d = dot(co.xyz, vec3(a,b,z));
    highp float r = mod(d, 3.14);
    return fract(sin(r) * c) * 2.0 - 1.0;
}

void vertex() {
    UV=UV*uv1_scale.xy+uv1_offset.xy;
    vec3 gravity = vec3(0, -6.0, 0) * gravity_amount;
    vec3 velocity = NORMAL;
    velocity.x += 2.0*rand(NORMAL);
    velocity.z += 2.0*rand(NORMAL + vec3(10.1, 23.0, 83.0));
    velocity.y += 1.0 + 2.0*rand(NORMAL + vec3(0.1, 29.0, 13.0));
    float a = WORLD_MATRIX[0][0];
    float b = WORLD_MATRIX[1][1];
    float c = WORLD_MATRIX[2][2];
    vec3 _scale = 1.0/scale;
    _scale *= 2.0;
    gravity *= _scale;
    velocity *= _scale;
    VERTEX += velocity*shatterment + gravity*shatterment*shatterment;
}


void fragment() {
    vec2 base_uv = UV;
    vec4 albedo_tex = texture(texture_albedo,base_uv);
	albedo_tex *= COLOR;
    ALBEDO = albedo.rgb * albedo_tex.rgb;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = specular;
}
