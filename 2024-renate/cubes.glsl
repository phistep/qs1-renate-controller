// This scene is taken from my second tutorial about shader coding,
// which introduces the concept of raymarching as well as some useful
// transforms and space-bending techniques.
// 
//     Mouse interactive!
//                            Video URL: https://youtu.be/khblXafu7iA
uniform bool feature_oct; // =0 #14
uniform bool feature_tor; // =0 #15
uniform bool feature_cub; // =0 #18
uniform float oct; // =0.1 [0.,.5,.001] #107
uniform float tor_out_diameter; // =(0.001) [0.1,.5,.01] #108
uniform float tor_in_diameter; // =(0.001) [0.1,.5,.01] #109
vec2 tor = vec2(tor_out_diameter,tor_in_diameter);
float cub_depth = oct;
float cub_length = tor_out_diameter; 
float cub_width = tor_in_diameter; 
vec3 cub = vec3(cub_depth,cub_length,cub_width); 

uniform float wiggle; // =.35 [0.01,.5,0.05] #102
uniform float rotate; // =.15 [0.0,.3,0.05] #103
uniform float number; // =1. [0.1,10.,0.1] #106

// 2D rotation function
mat2 rot2D(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

// Custom gradient - https://iquilezles.org/articles/palettes/
vec3 palette(float t) {
    return .5+.5*cos(6.28318*(t+vec3(.3,.416,.557)));
}

// Octahedron SDF - https://iquilezles.org/articles/distfunctions/
float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    return (p.x+p.y+p.z-s)*0.57735027;
}

float sdCube(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-length(p)*t.y;
}

// Scene distance
float map(vec3 p) {
    p.z += u_Time * .4; // Forward movement
    
    // Space repetition
    p.xy = fract(p.xy) - .5;     // number: 1
    p.z =  mod(p.z, .25*number) - .125*number; // number: .25
    
    if(feature_oct) return sdOctahedron(p, oct); // Octahedron
	if(feature_tor) return sdTorus(p, tor); // Octahedron
	if(feature_cub) return sdCube(p, cub); // Octahedron
	
}

void main() {
    vec2 uv = (gl_FragCoord.xy * 2. - u_Resolution.xy) / u_Resolution.y;
    vec2  m = (2. - u_Resolution.xy) / u_Resolution.y;
    
    // Default circular motion if mouse not clicked
    //if (feature) m = vec2(sin(u_Time*0.05), cos(u_Time*.2));

    // Initialization
    vec3 ro = vec3(0, 0, -3);         // ray origin
    vec3 rd = normalize(vec3(uv, 1)); // ray direction
    vec3 col = vec3(0);               // final pixel color

    float t = 0.; // total distance travelled

    int i; // Raymarching
    for (i = 0; i < 100; i++) {
        vec3 p = ro + rd * t; // position along the ray
        
        p.xy *= rot2D(t* rotate * m.x);     // rotate ray around z-axis

        p.y += sin(t) * wiggle;  // wiggle ray

        float d = map(p);     // current distance to the scene

        t += d;               // "march" the ray

        if (d < .001 || t > 100.) break; // early stop
    }

    // Coloring
    col = palette(t*.04 + float(i)*.005);

    FragColor = vec4(col, 1);
}
