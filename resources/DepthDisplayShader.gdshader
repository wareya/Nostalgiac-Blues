// NOTE: Shader automatically converted from Godot Engine 3.4.4.stable's SpatialMaterial.

shader_type spatial;
render_mode blend_mix,depth_draw_never,depth_test_disable,cull_disabled,diffuse_burley,specular_schlick_ggx,unshaded;
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


void vertex() {
    MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(CAMERA_MATRIX[0],CAMERA_MATRIX[1],CAMERA_MATRIX[2],WORLD_MATRIX[3]);
    VERTEX.x *= 1.6;
    VERTEX *= 0.65;
}




void fragment() {
	vec2 base_uv = UV;
    base_uv.y = 1.0-base_uv.y;
    //ALBEDO = texture( SCREEN_TEXTURE, base_uv).xyz;
    ALBEDO = clamp(-(texture( DEPTH_TEXTURE, base_uv).x-vec3(1.0))*40.0, 0.0, 1.0);
}
