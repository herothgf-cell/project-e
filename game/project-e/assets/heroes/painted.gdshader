shader_type spatial;
render_mode unshaded, cull_disabled;

// Painted UVs carry facial expressions and embroidery. A fixed world-space
// key keeps those painted values readable under the review room and match lights.
uniform bool textured = false;
uniform bool ink_edges = false;
uniform sampler2D pigment : source_color, filter_linear_mipmap, repeat_enable;
void fragment() {
    vec3 n = normalize(mat3(INV_VIEW_MATRIX) * NORMAL);
    float key = dot(n, normalize(vec3(-0.45, 0.83, -0.50)));
    float diffuse = smoothstep(-0.33, 0.18, key);
    vec3 shade = mix(vec3(0.64, 0.64, 0.77), vec3(1.0, 0.98, 0.94), diffuse);
    float edge = pow(1.0 - abs(dot(normalize(NORMAL), VIEW)), 3.5);
    vec3 base = COLOR.rgb;
    if (textured) {
        vec3 sampled = texture(pigment, UV).rgb;
        base = OUTPUT_IS_SRGB ? pow(sampled, vec3(2.2)) : sampled;
    }
    vec3 linear_paint = base * shade * (0.94 + 0.06 * max(key, 0.0));
    // GL compatibility presents sRGB, Forward+ presents linear light.
    ALBEDO = OUTPUT_IS_SRGB ? pow(max(linear_paint, vec3(0.0)), vec3(1.0/2.2)) : linear_paint;
    if (ink_edges) {
        ALBEDO *= mix(1.0, 0.61, smoothstep(0.31, 0.94, edge));
    }
}
