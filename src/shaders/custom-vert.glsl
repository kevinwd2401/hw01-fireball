#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform int u_Time;       // Time

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

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

float gain(float g, float t) {
    if (t < 0.5) {
        return bias(1. - g, 2. * t) / 2.;
    } else {
        return 1. - bias(1. - g, 2. - 2. * t) / 2.;
    }
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    // tail along positive y axis
    vec3 newPos = vec3(vs_Pos);
    float heightScaleFluct = 0.08 * sin(float(u_Time) * 0.134) - 0.1 * cos(float(u_Time) * 0.017 + 0.4);
    newPos.y *= mix(1.0, 2. + heightScaleFluct, clamp(newPos.y, 0.0, 1.0)); 


    // tail taper
    float t = clamp(newPos.y - 0.3, 0.0, 1.0);
    newPos.xz *= mix(1.0, 0.7, gain(0.66, t));

    // x z oscillation
    float amp = 0.016 + 0.03 * clamp(newPos.y - 1., 0.0, 1.0); 
    newPos.x += amp * (sin(3. * newPos.y + float(u_Time) * 0.0234) + cos(4. * newPos.y + float(u_Time) * 0.019 - 11.));
    newPos.x += amp * (sin(3. * newPos.y + float(u_Time) * 0.039 + 2.3) - cos( 4. * newPos.y - float(u_Time) * 0.087));

    // FBM
    float r = length(newPos);
    vec3 noisePos = vec3(newPos.x * 0.5, newPos.y * 0.5 - float(u_Time) * 0.03, newPos.z * 0.5);
    float fbm = fbm3D(noisePos, 4, 3., 0.5);
    float fbmAmp = 0.3 * clamp(r * 2., 1.0, 2.0) * fbm;
    newPos += fbmAmp * normalize(newPos);

    fs_Pos = vec4(newPos, 1);
    vec4 modelposition = u_Model * vec4(newPos, 1);  // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
