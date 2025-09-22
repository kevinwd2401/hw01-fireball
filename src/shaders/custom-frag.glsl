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

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_Color2;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec3 randomVector(vec3 p) {
    vec3 v = fract(sin(vec3(
        dot(p, vec3(127.1, 311.7, 74.7)),
        dot(p, vec3(269.5, 18.3, 246.1)),
        dot(p, vec3(113.5, 271.9, 124.6))
    )) * 4358.5453);
    return normalize(v);
}

float surflet(vec3 P, vec3 gridPoint) {
    float distX = abs(P.x - gridPoint.x);
    float distY = abs(P.y - gridPoint.y);
    float distZ = abs(P.z - gridPoint.z);

    float tX = 1.0 - 6.0*pow(distX, 5.0) + 15.0*pow(distX, 4.0) - 10.0*pow(distX, 3.0);
    float tY = 1.0 - 6.0*pow(distY, 5.0) + 15.0*pow(distY, 4.0) - 10.0*pow(distY, 3.0);
    float tZ = 1.0 - 6.0*pow(distZ, 5.0) + 15.0*pow(distZ, 4.0) - 10.0*pow(distZ, 3.0);

    vec3 gradient = randomVector(gridPoint);
    vec3 diff = P - gridPoint;

    float height = dot(diff, gradient);
    return height * tX * tY * tZ;
}

float perlinNoise(vec3 p) {
    float surfletSum = 0.f;

    for(int dx = 0; dx <= 1; ++dx) {
        for(int dy = 0; dy <= 1; ++dy) {
            for(int dz = 0; dz <= 1; ++dz) {
                surfletSum += surflet(p, floor(p) + vec3(dx, dy, dz));
            }
        }
    }
    return surfletSum;
}

float fbm(vec3 p) {

    int octaves = 2;
    float amplitude = 0.5;
    float frequency = 2.0;
    float persistence = 0.8f;

    float total = 0.0;

    for (int i = 0; i < octaves; i++) {
        total += amplitude * perlinNoise(p * frequency);

        frequency *= 1.66;
        amplitude *= persistence;
    }
    return total;
}

void main()
{

    // Calculate the diffuse term for Lambert shading
    //float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    // diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    //float ambientTerm = 0.1;

    //float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    

    out_Col = vec4(u_Color * diffuseTerm, u_Color.a);
}



