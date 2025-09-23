#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

in float fs_Time;       // Time

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_Color2;
uniform float u_ColorSteps;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float fade(float t) {
    // quintic fade
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

vec3 rand3(vec3 p) {
    vec3 q = vec3(
        dot(p, vec3(127.1, 311.7,  74.7)),
        dot(p, vec3(269.5, 183.3, 246.1)),
        dot(p, vec3(113.5, 271.9, 124.6))
    );
    q = fract(sin(q) * 43758.5453123);
    // [-1,1]
    q = q * 2.0 - 1.0;
    return normalize(q);
}

float perlin3D(vec3 P) {
    vec3 Pi = floor(P);
    vec3 Pf = P - Pi;
    vec3 w = vec3(fade(Pf.x), fade(Pf.y), fade(Pf.z));

    // corner offsets
    vec3 c000 = vec3(0.0, 0.0, 0.0);
    vec3 c100 = vec3(1.0, 0.0, 0.0);
    vec3 c010 = vec3(0.0, 1.0, 0.0);
    vec3 c110 = vec3(1.0, 1.0, 0.0);
    vec3 c001 = vec3(0.0, 0.0, 1.0);
    vec3 c101 = vec3(1.0, 0.0, 1.0);
    vec3 c011 = vec3(0.0, 1.0, 1.0);
    vec3 c111 = vec3(1.0, 1.0, 1.0);

    // gradient vectors
    float n000 = dot(rand3(Pi + c000), Pf - c000);
    float n100 = dot(rand3(Pi + c100), Pf - c100);
    float n010 = dot(rand3(Pi + c010), Pf - c010);
    float n110 = dot(rand3(Pi + c110), Pf - c110);
    float n001 = dot(rand3(Pi + c001), Pf - c001);
    float n101 = dot(rand3(Pi + c101), Pf - c101);
    float n011 = dot(rand3(Pi + c011), Pf - c011);
    float n111 = dot(rand3(Pi + c111), Pf - c111);

    float nx00 = mix(n000, n100, w.x);
    float nx10 = mix(n010, n110, w.x);
    float nx01 = mix(n001, n101, w.x);
    float nx11 = mix(n011, n111, w.x);

    float nxy0 = mix(nx00, nx10, w.y);
    float nxy1 = mix(nx01, nx11, w.y);

    float nxyz = mix(nxy0, nxy1, w.z);

    return nxyz * 1.732;
}

float fbm3D(vec3 p, int OCTAVES, float LACUNARITY, float GAIN) {
    float freq = 1.0;
    float amp = 1.0;
    float sum = 0.0;
    float norm = 0.0;

    for (int i = 0; i < OCTAVES; ++i) {
        sum += perlin3D(p * freq) * amp;
        norm += amp;
        freq *= LACUNARITY;
        amp *= GAIN;
    }
    // [-1,1]
    return sum / norm;
}

float bias(float t, float b) {
    return pow(t, log(b) / log(0.5));
}


void main()
{
    // base color
    float r = length(fs_Pos.xyz);
    float t = (clamp(r, 1., 2.2) - 1.) / 1.2;
    vec3 colLayer1 = mix(u_Color.rgb, u_Color2.rgb, bias(t, 0.7));


    // fbm
    vec3 noisePos = vec3(fs_Pos.x * 0.5, fs_Pos.y * 0.5 - fs_Time * 0.03, fs_Pos.z * 0.5);
    float fbm = fbm3D(noisePos, 4, 2.8, 0.8);
    float bucketT = floor(clamp(fbm, 0., 1.) * u_ColorSteps) / (u_ColorSteps - 1.);
    vec3 colLayer2 = mix(u_Color.rgb, u_Color2.rgb, bucketT);

    //more fbm
    noisePos = vec3(fs_Pos.x * 1.25, fs_Pos.y * 1.25 - fs_Time * 0.033, fs_Pos.z * 1.25);
    fbm = fbm3D(noisePos, 4, 3., 0.8);
    bucketT = floor(clamp(fbm, 0., 1.) * u_ColorSteps) / (u_ColorSteps - 1.);
    colLayer2 = mix(colLayer2, mix(u_Color.rgb, u_Color2.rgb, bucketT), 0.5);

    //darken base color at bottom
    float darkenT = clamp(-fs_Pos.y - 0.1 - 0.4 * fbm, 0., 1.);
    bucketT = floor(clamp(darkenT, 0., 1.) * 2. * u_ColorSteps) / (2. * u_ColorSteps - 1.);
    colLayer1 = mix(colLayer1, vec3(0), bucketT);

    //brighten base color at top
    out_Col = vec4(mix(colLayer1, colLayer2, 0.55 - 0.3 * clamp(fs_Pos.y - 1., 0., 1.)), u_Color.a);

}



