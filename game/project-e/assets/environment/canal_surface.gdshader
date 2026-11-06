shader_type spatial;
render_mode cull_disabled;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D vision_mask : filter_linear, repeat_disable;
uniform bool vision_bound = false;
uniform sampler2D flagstones : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D waterbed : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool warm_ceramic = false;
uniform int finish = 0; // 1 limestone, 2 water, 3 vertex paint, 4 ceramic inlay, 5 planted banks
varying vec2 world_point;
varying vec2 local_point;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_point = vec2(world.x, -world.z);
	local_point = VERTEX.xz;
}

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float drift(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(hash21(cell), hash21(cell+vec2(1.0,0.0)), u.x),
			mix(hash21(cell+vec2(0.0,1.0)), hash21(cell+vec2(1.0)), u.x), u.y);
}

void fragment() {
	vec3 paint = base_color.rgb;
	if (finish == 1) {
		vec2 uv = world_point / 4.0;
		float wear = drift(world_point * 0.18);
		paint = texture(flagstones, uv + vec2(0.006 * sin(uv.y * 3.0), 0.0)).rgb;
		paint = mix(vec3(dot(paint,vec3(0.24,0.62,0.14))),paint,0.68);
		paint *= mix(base_color.rgb,vec3(0.88,0.89,0.90),0.48) * vec3(0.92,0.95,1.03) * mix(0.75, 0.92, wear);
	} else if (finish == 2) {
		vec2 p = world_point;
		float t = TIME * 0.20;
		float deep = drift(p * 0.17) * 0.68 + drift(p * 0.62) * 0.32;
		float bend = drift(p * 0.47 + vec2(t, 0.0));
		vec2 refraction = vec2(bend - 0.5, sin(p.x * 1.15 + p.y * 0.8 + t) * 0.3);
		vec2 uv = p / 13.0 + refraction * 0.012;
		vec2 turned = mat2(vec2(0.57, 0.82), vec2(-0.82, 0.57)) * uv * 0.53;
		vec3 bed = mix(texture(waterbed, uv).rgb, texture(waterbed, turned).rgb, 0.32);
		vec3 deep_water = OUTPUT_IS_SRGB ? vec3(0.10,0.31,0.36) : vec3(0.01,0.079,0.107);
		vec3 reflected_sky = OUTPUT_IS_SRGB ? vec3(0.47,0.68,0.71) : vec3(0.19,0.43,0.47);
		float curve = sin(p.y * 5.7 + 4.7*bend + t + 0.45*sin(p.x*3.0+t));
		float fleck = smoothstep(0.72,0.91,curve) * smoothstep(0.50,0.75,drift(p*vec2(0.95,2.4)-t*0.27));
		paint = mix(mix(bed, deep_water, 0.49 + 0.21 * deep), reflected_sky, fleck * 0.23);
	} else if (finish == 3 || finish == 5) {
		paint = OUTPUT_IS_SRGB ? pow(max(COLOR.rgb,vec3(0.0)),vec3(0.81)) : COLOR.rgb;
		if (warm_ceramic) {
			// The same meshes carry a cold glazed crest or a red enamel crest.
			// Keep the gilt, stone and neutral facets in their original palette.
			float blue_glaze = smoothstep(0.015,0.11,paint.b-paint.r);
			float value = dot(paint,vec3(0.25,0.55,0.20));
			vec3 vermilion = vec3(1.54,0.72,0.58) * value + vec3(0.035,0.0,0.0);
			paint = mix(paint,vermilion,blue_glaze);
		}
		if (finish == 5) {
			float moss = 0.60 * drift(world_point * 2.2) + 0.40 * drift(world_point * 0.64);
			paint *= mix(vec3(0.65,0.72,0.82),vec3(1.03,0.99,0.91),moss);
		}
	} else if (finish == 4) {
		float z = local_point.y / 0.12;
		float vine = abs(abs(z)-abs(sin(local_point.x * 6.0)) * 0.51);
		float line = max(1.0 - smoothstep(0.07,0.21,vine),smoothstep(0.74,0.86,abs(z)));
		float bud = (1.0-smoothstep(0.12,0.31,abs(z))) * smoothstep(0.86,0.97,abs(sin(local_point.x * 6.0)));
		paint = mix(vec3(0.24,0.36,0.44),vec3(0.62,0.55,0.40),max(line,bud));
		if (!OUTPUT_IS_SRGB) { paint = pow(paint, vec3(2.2)); }
	}
	float visible = vision_bound ? texture(vision_mask, (world_point + vec2(62.0,40.0)) / vec2(124.0,80.0)).r : 1.0;
	float grey = dot(paint, vec3(0.2126,0.7152,0.0722));
	vec3 unseen = mix(vec3(grey), paint, 0.38) * 0.49;
	ALBEDO = mix(unseen, paint, visible);
	ROUGHNESS = 0.94;
	SPECULAR = 0.10;
}
